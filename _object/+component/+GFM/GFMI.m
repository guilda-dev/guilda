classdef GFMI < component

    properties (SetAccess = protected)
        vsc_controller 
        reference_model
        dc_source
    end

    properties(SetAccess=protected)
        Sbase = 1;
        Vbase = 1;
        Ibase = nan; % - 
        Zbase = nan; % |
        Ybase = nan; % | Calculated when Sbase and Vbase are set
        Cbase = nan; % |
        Lbase = nan; % -
    end

    methods

        function obj = GFMI(para)
            % Set parameters
                if nargin==0
                    % If not specified as an argument, use default value from GFMI.csv
                    para = readtable([mfilename("fullpath"),'.csv']);
                end
                obj.parameter = para;
                obj.Tag = 'GFM';
        
            % Set default base value
                obj.set_Sbase( 100*1e3);
                obj.set_Vbase( 480    );

            % Set default class
                obj.vsc_controller  = component.GFM.controller.low_level_cascade();
                obj.vsc_controller.converter = obj;

                obj.reference_model = component.GFM.ReferenceModel.vsm();
                obj.reference_model.converter = obj;

                obj.dc_source       = component.GFM.DCsource.Vconstant();
                obj.dc_source.converter = obj;
        end
    
        % Methods to define the state, number of input ports, and variable names
            function nx = get_nx(obj)
                % Number of states of the model in the converter part is 0
                nx = 6 + obj.vsc_controller.get_nx()  ...
                       + obj.reference_model.get_nx() ...
                       + obj.dc_source.get_nx()       ;
            end
    
            function nu = get_nu(obj)
                % Number of inputs for the converter part of the model is 0
                nu = 0 + obj.vsc_controller.get_nu()  ...
                       + obj.reference_model.get_nu() ...
                       + obj.dc_source.get_nu()       ;
            end

            function name_tag = naming_state(obj)
                % The variable names for the state of the model in the converter section have 6 names.
                name_tag = [ {'is_d','is_q','v_d','v_q','i_d','i_q'},...
                             obj.vsc_controller.naming_state        ,...
                             obj.reference_model.naming_state       ,...
                             obj.dc_source.naming_state             ];
            end
    
            function name_tag = naming_port(obj)
                % No variable names for the input port of the model in the converter section
                name_tag = [ []                             ,...
                             obj.vsc_controller.naming_port ,...
                             obj.reference_model.naming_port,...
                             obj.dc_source.naming_port      ];
            end
    
        % Methods to define base values    
            function set_Sbase(obj,val)
                obj.Sbase = val;
                obj.calc_base;
            end

            function set_Vbase(obj,val)
                obj.Vbase = val;
                obj.calc_base;
            end

            function calc_base(obj)
                omega0 = 1; % << use pu value  // or omega0 = obj.omega0
                obj.Ibase = obj.Sbase/obj.Vbase;
                obj.Zbase = obj.Vbase/obj.Ibase;
                obj.Ybase = 1/obj.Zbase;
                obj.Cbase = obj.Ybase / omega0;
                obj.Lbase = obj.Zbase * omega0;
            end

        % Property to set the GFMI component class
            function set_vsc_controller(obj,c)
                if nargin<2 || isempty(c)
                    error('No Argument')
                elseif isa(c,'component.GFM.controller.AbstractClass')
                    c.converter = obj;
                    obj.vsc_controller = c;
                else
                    error('The specified class could not be identified');
                end
            end
    
            function set_reference_model(obj,c)
                if nargin<2 || isempty(c)
                    error('No Argument')
                elseif isa(c, 'component.GFM.ReferenceModel.AbstractClass')
                    c.converter = obj;
                    obj.reference_model = c;
                elseif isa(c,'component')
                    if ismethod(c, 'get_Vterminal')
                        assert(~isempty(obj.connected_bus),'先にGFMをbusクラスに追加してください >> bus.set_component(gfm)')
                        c.register_parent(obj.connected_bus,'overwrite')
                        obj.reference_model = c;
                    else
                        error('To use this component class as a reference model, the method "A" must be implemented')
                    end
                else
                    error('The specified class could not be identified');
                end
            end
    
            function set_dc_source(obj,c)
                if nargin<2 || isempty(c)
                    error('No Argument')
                elseif isa(c, 'component.GFM.DCsource.AbstractClass')
                    c.converter = obj;
                    obj.dc_source = c;
                else
                    error('The specified class could not be identified');
                end
            end

        
        % ダイナミクスを定義するメソッド
        function [dx, constraint] = get_dx_constraint(obj, t, x, V, I, u)
                
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

                % get parameter
                     p  = obj.parameter;
                     R  = p.R   / obj.Zbase;
                     L  = p.L   / obj.Lbase;
                     C  = p.C   / obj.Cbase;
                    L_g = p.L_g / obj.Lbase;
                    R_g = p.R_g / obj.Zbase;

                % Divide the current value by the number of devices
                    I  = I/p.n;
    
                % Get terminal voltage values from the reference model.
                    [delta,domega,vdq_hat]  = ref.get_Vterminal(x_ref,V,I,u_ref);
                    omega = domega+1; %Convert "frequency deviation" to "frequency"
                
                % Convert from grid to converter reference
                    tensor = [ sin(delta),  cos(delta); ... 
                              -cos(delta),  sin(delta)] ;
                    V_dq =  tensor.' *    V;
                    I_   =  tensor   * i_dq;
                    con_I = I - I_;
               
    
                % Calculate dx
     
                    % vdq_hat = ref.calculate_vdq_hat(t, x_ref, u_ref, v_dq, i_dq);
                    
                    % Calculate low-level cascade control dynamics
                    [dx_con, m      ] = con.get_dx_mdq( t, x_con, u_con, v_dq, i_dq, is_dq, vdq_hat, omega);
                   
                    % Calculate dc source dynamics
                    ix = (1/2) * m.' * is_dq;
                    [dx_dc,  vdc    ] =  dc.get_dx_vdc( t, x_dc , u_dc , v_dq, i_dq, ix);
    
                    % Calculate references model dynamics
                    [dx_ref, con_ref] = ref.get_dx_constraint(t, x_ref, V, I, u_ref); %#ok
                    
                    % Calculate converter dynamics
                    vs_dq = (1/2) * m * vdc;
    
                    d_isdq= (-(R * eye(2) + omega * L * [0, -1; 1, 0]) * is_dq - v_dq + vs_dq) / L;
                    d_vdq = ( -C * omega * [0, -1; 1, 0] * v_dq + is_dq - i_dq) / C; % d_vdq = (is_dq - i_dq) / p.C;
                    d_idq = (-(R_g * eye(2) + omega * L_g * [0, -1; 1, 0]) * i_dq - V_dq + v_dq) / L_g;
    
    
                % Calculate dx/constraint
                dx  = [d_isdq; d_vdq; d_idq; dx_con; dx_ref; dx_dc];
                constraint = con_I; %[con_ref;con_I];
    
            end
    
            function [x_st,u_st] = get_equilibrium(obj, Vc, Ic, flag) %#ok
                flag  = 'init';
    
                % get parameter
                    p = obj.parameter;
                    C = p.C / obj.Cbase;
                
                V = tools.complex2vec(Vc);
                I = tools.complex2vec(Ic);
                I = I/p.n;
    
                % Reference model
                    if strcmp(flag,'init') && isa(obj.reference_model,'component')
                        [x_ref, u_ref] = obj.reference_model.set_equilibrium(Vc,Ic);
                    else
                        [x_ref, u_ref] = obj.reference_model.get_equilibrium(Vc,Ic);
                    end
                
                
                % Calculate equilibrium of "Vdq,Idq"
                    [delta_st, domega_st, Vdq] = obj.reference_model.get_Vterminal(x_ref,V,I,u_ref);
                    omega_st = domega_st +1; %Convert "frequency deviation" to "frequency"
                    tensor = [ sin(delta_st), -cos(delta_st); ... 
                               cos(delta_st),  sin(delta_st)];
                    Idq = tensor * I;
    
                % Converter
                    idq_st  = Idq;
                    vdq_st  = Vdq;  % +(p.R_g*eye(2) + omega_st*p.L_g*[0,-1;1,0]) * idq_st;
                    isdq_st = idq_st + omega_st*C*[0,-1;1,0]*vdq_st;
    
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
