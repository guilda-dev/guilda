classdef main < component

    properties (SetAccess = private)
        vsc_controller
        reference_model
        dc_source
        % parameter
        % x_equilibrium
        % u_equilibrium
    end

    methods

        function obj = main(para)
            if nargin==0
                c = class(obj);
                c = regexprep(c,'.GFM.(\w+)','.GFM.converter.params.main');
                para = eval([c,'();']);
            end
            obj.parameter = para;
            obj.Tag = 'GFM';
        end

        function nx = get_nx(obj)
            nx = 6 + obj.vsc_controller.get_nx() ...
                   + obj.reference_model.get_nx() ...
                   + obj.dc_source.get_nx();
        end

        function nu = get_nu(obj)
            nu =  obj.vsc_controller.get_nu() ...
                + obj.reference_model.get_nu() ...
                + obj.dc_source.get_nu();
        end

        function set_vsc_controller(obj,c)
            if nargin<2 || isempty(c)
                path = strrep( mfilename("fullpath"), '+converter/main','+controller');
                obj.vsc_controller = search_file(path);
            elseif contains(class(c), 'component.GFM.controller')
                obj.vsc_controller = c;
            else
                switch c
                    case 'low_level_cascade'
                        obj.vsc_controller = component.GFM.controller.low_level_cascade();
                    otherwise
                        error('The specified class could not be identified');
                end
            end
            obj.vsc_controller.converter = obj;
        end

        function set_reference_model(obj,c)
            if nargin<2 || isempty(c)
                path = strrep( mfilename("fullpath"), '+converter/main','+ReferenceModel');
                obj.reference_model = search_file(path);
            elseif contains(class(c), 'component.GFM.ReferenceModel')
                obj.reference_model = c;
            elseif isa(c,'component')
                error('under developping')
            else
                switch c
                    case {'vsm','VSM'}
                        obj.reference_model = component.GFM.ReferenceModel.vsm();
                    case {'Droop','droop'}
                        obj.reference_model = component.GFM.ReferenceModel.droop();
                    otherwise
                        error('The specified class could not be identified');
                end
            end
            obj.reference_model.converter = obj;
        end

        function set_dc_source(obj,c)
            if nargin<2 || isempty(c)
                path = strrep( mfilename("fullpath"), '+converter/main','+DCsource');
                obj.dc_source = search_file(path);
            elseif contains(class(c), 'component.GFM.DCsource')
                obj.dc_source = c;
            else
                switch c
                    case 'Vconst'
                        obj.dc_source = component.GFM.DCsource.Vconstant();
                    case 'Delay1order'
                        obj.dc_source = component.GFM.DCsource.Delay1order_model();
                    otherwise
                        error('The specified class could not be identified');
                end
            end
        end

        function name_tag = naming_state(obj)
            name_tag = [ {'is_d','is_q','v_d','v_q','i_d','i_q'},...
                         obj.vsc_controller.naming_state,...
                         obj.reference_model.naming_state,...
                         obj.dc_source.naming_state];
        end

        function name_tag = naming_port(obj)
            name_tag = [ obj.vsc_controller.naming_port,...
                         obj.reference_model.naming_port,...
                         obj.dc_source.naming_port];
        end

        function [dx, con] = get_dx_constraint(obj, t, x, V, I, u)
            p = obj.parameter;
            I = I/p.n;

            con = obj.vsc_controller;
            ref = obj.reference_model;
            dc  = obj.dc_source;

            is_dq= x(1:2);
            v_dq = x(3:4);
            i_dq = x(5:6);

            x_con = x( (1:con.get_nx) + 6                           );
            x_ref = x( (1:ref.get_nx) + 6 + con.get_nx              );
            x_dc  = x( (1:dc.get_nx ) + 6 + con.get_nx + ref.get_nx );

            u_con = u( (1:con.get_nu)                           );
            u_ref = u( (1:ref.get_nu) + con.get_nu              );
            u_dc  = u( (1: dc.get_nu) + con.get_nu + ref.get_nu );
            
            [delta,omega,~]  = ref.get_Vterminal(x_ref,V,I);
            

            % Convert from grid to converter reference
                tensor = [ sin(delta),  cos(delta); ... 
                          -cos(delta),  sin(delta)] ;
                I_   =  tensor   * i_dq;
                V_dq =  tensor.' *    V;
           

            % Calculate dx

                vdq_hat = ref.calculate_vdq_hat(t, x_ref, u_ref, v_dq, i_dq);
                
                % Calculate low-level cascade control dynamics
                [dx_con, m      ] = con.get_dx_mdq( t, x_con, u_con, v_dq, i_dq, is_dq, vdq_hat, omega);

                % Calculate dc source dynamics
                ix = (1/2) * m.' * is_dq;
                [dx_dc,  vdc    ] =  dc.get_dx_vdc( t, x_dc , u_dc , v_dq, i_dq, ix);

                % Calculate references model dynamics
                dx_ref = ref.get_dx(t, x_ref, u_ref, v_dq, i_dq, vdc);

                % Calculate converter dynamics
                vs_dq = (1/2) * m * vdc;

                d_isdq= (-(p.R * eye(2) + omega * p.L * [0, -1; 1, 0]) * is_dq - v_dq + vs_dq) / p.L;
                d_vdq = ( -p.C * omega * [0, -1; 1, 0] * v_dq + is_dq - i_dq) / p.C; % d_vdq = (is_dq - i_dq) / p.C;
                d_idq = (-(p.R_g * eye(2) + omega * p.L_g * [0, -1; 1, 0]) * i_dq - V_dq + v_dq) / p.L_g;


            % Calculate dx/constraint
            dx  = [d_isdq; d_vdq; d_idq; dx_con; dx_ref; dx_dc];
            con = I - I_;

        end

        function [x_st,u_st] = get_equilibrium(obj, V, I, flag)
            flag  = 'init';

            p = obj.parameter;

            V = tools.complex2vec(V);
            I = tools.complex2vec(I);
            I = I/p.n;

            % Reference model
                [x_ref, u_ref] = obj.reference_model.set_equilibrium(V,I,flag);
            
            
            % Calculate equilibrium of "vdq,idq"
                [delta_st, omega_st, Vdq] = obj.reference_model.get_Vterminal(x_ref,V,I);
                tensor = [ sin(delta_st), -cos(delta_st); ... 
                           cos(delta_st),  sin(delta_st)];
                
                %Vdq = tensor * V % equal >> Vbus_dq = [0; norm(V)]
                Idq = tensor * I;

            % Converter
                idq_st  = Idq;
                vdq_st  = Vdq;  % +(p.R_g*eye(2) + omega_st*p.L_g*[0,-1;1,0]) * idq_st;
                isdq_st = idq_st + omega_st*p.C*[0,-1;1,0]*vdq_st;

            % Low-level cascade control
                [x_con, u_con, mdq] = obj.vsc_controller.set_equilibrium( vdq_st, isdq_st, omega_st, flag);

            % DC source
                ix_st = 1/2 * mdq.' * isdq_st;
                [x_dc,u_dc] = obj.dc_source.set_equilibrium(V,I,ix_st,flag);


            x_st = [isdq_st; vdq_st; idq_st; x_con; x_ref; x_dc];
            u_st = [u_con; u_ref; u_dc];
        end

    end

end

function Instance = search_file(dir_name)
    f = dir([dir_name,'/*.m']);
    f = struct2table(f);
    f = f{:,'name'};

    getID = false;

    while ~getID
        disp(' ')
        for i = 1:numel(f)
            disp([num2str(i),'. ',f{i}])
        end
        disp(' ')
        ID = str2double( input('Select a number : ','s') );
        if ~isnan(ID)
            getID = true;
        end
    end
    fname = supporters.DNS(f{ID});
    Instance = eval([fname,'();']);
    word = ['Set "',fname,'" class successfully !!'];
    disp(' ')
    disp(repmat('-',1,numel(word)))
    disp(word)
    disp(repmat('-',1,numel(word)))
    disp(' ')
end
