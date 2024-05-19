classdef Machine < component
% 全てのgeneratorクラスの親クラス

    properties(SetAccess = private)
        avr
        pss
        governor
    end

    properties(SetAccess=protected,Abstract)
        GenState
        GenPort
    end

    methods
        function obj =  Machine(parameter)
            obj.Tag = 'Gen';
            obj.InputType = 'Add';
            obj.sudo_set_CostFunction;

            if istable(parameter)
                obj.parameter = parameter;
            else
                parameter = char(parameter);
                dataset = readtable([mfilename("fullpath"),'_DataSheet.csv']);
                switch string(parameter)
                    case "NGT2"
                        obj.parameter = dataset(1,:);
                    case "NGT6"
                        obj.parameter = dataset(2,:);
                    case "NGT8"
                        obj.parameter = dataset(3,:);
                end
            end

            obj.set_avr(      component.generator.avr.empty() );
            obj.set_governor( component.generator.governor.empty() );
            obj.set_pss(      component.generator.pss.empty() );
        end
    
        % SubClassのSetメソッド
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function set_avr(obj, avr); obj.set_controller(avr,'avr'); end
        function set_pss(obj, pss); obj.set_controller(pss,'pss'); end
        function set_governor(obj, governor); obj.set_controller(governor,'governor'); end


        % 状態と入力ポートの変数名取得メソッド
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function u_name = naming_port(obj)
            u_gen = obj.GenPort;
            u_avr = obj.avr.naming_port;
            u_pss = obj.pss.naming_port;
            u_gov = obj.governor.naming_port;
            u_name = [u_gen,u_avr,u_pss,u_gov];
        end

        function x_name = naming_state(obj)
            x_gen = obj.GenState;
            x_avr = obj.avr.naming_state;
            x_pss = obj.pss.naming_state;
            x_gov = obj.governor.naming_state;
            x_name = [x_gen,x_avr,x_pss,x_gov];
        end

        function [dx, Vfd, Pm] = get_dx_u(obj, x, u, omega, P, Vabs, Efd)

                nx_avr = obj.avr.get_nx();
                nx_pss = obj.pss.get_nx();
                nx_gov = obj.governor.get_nx();
    
                nu_avr = obj.avr.get_nu();
                nu_pss = obj.pss.get_nu();
                nu_gov = obj.governor.get_nu();

                % AVR,PSS,Governorの状態/入力を抽出
                x_avr = x(1:nx_avr);
                x_pss = x(nx_avr+(1:nx_pss));
                x_gov = x(nx_avr+nx_pss+(1:nx_gov));
    
                % 入力の抽出
                u_avr = u(1:nu_avr);
                u_pss = u(nu_avr+(1:nu_pss));
                u_gov = u(nu_avr+nu_pss+(1:nu_gov));
                

                [dx_pss, v  ] = obj.pss.get_dx_u( x_pss, u_pss, omega);
                [dx_avr, Vfd] = obj.avr.get_dx_u( x_avr, u_avr+v, Vabs, Efd);
                [dx_gov, Pm ] = obj.governor.get_dx_u( x_gov, u_gov, omega, P);
                dx = [dx_avr;dx_pss;dx_gov];
        end

        

        function [x_st,u_st] = set_equilibrium(obj,V,I)
            if nargin<2
                V = obj.V_equilibrium;
                I = obj.I_equilibrium;
            end
            [x_st, u_st] = obj.get_equilibrium(V,I,'set');
            if numel(x_st)==0
                x_st = zeros(0,1);
            end
            if numel(u_st)==0
                u_st = zeros(0,1);
            end
            obj.x_equilibrium = x_st;
            obj.u_equilibrium = u_st;
            obj.set_linear_matrix();
        end

        % function get_sys_gen(obj)
        %     nx = obj.get_nx;
        %     nu = obj.get_nu;
        % 
        %     sys = obj.system_matrix;
        % 
        %     C = [   eye(nx); ...
        %         zeros(2,nx); ...
        %              sys.C ];
        % 
        %     B = [       sys.B,      sys.BV,     sys.BI ];
        %     D = [zeros(nx,nu), zeros(nx,2), zeros(nx,2);...
        %          zeros( 2,nu),      eys(2), zeros( 2,2);...
        %                 sys.D,      sys.DV,     sys.DI ];
        % 
        %     sys = ss( sys.A, B, C, D);
        % 
        %     xname = obj.get_state_name;
        %     uname = obj.get_port_name;
        % 
        %     sys.StateName = xname;
        % 
        %     for i = 1:numel(xname)
        %         sys.OutputGroup.(xname{i}) = i;
        %     end
        %     for i = 1:numel(uname)
        %         sys.InputGroup.(uname{i}) = nx+i;
        %     end
        % 
        %     sys.InputGroup.V = nu+(1:2);
        %     sys.InputGroup.I = nu+(3:4);
        % 
        %     sys.OutputGroup.V = nx+(1:2);
        %     sys.OutputGroup.Const = nx+(3:4);
        % end
        % 
        % function sys = get_sys(obj)
        % 
        % end
    end

    methods(Access=private)
        function set_controller(obj,cls,type)
            if nargin<3
                type = 'controller'; 
            end
            
            idx = ismember({'avr','pss','governor'},type);

            if any(idx)
                if ~isa(cls, 'component.generator.abstract.SubClass')
                    error(['Variable is not "',type,'" class.'])
                end
                obj.children{idx} = cls;
                obj.(type) = cls;
            else
                if ~isa(cls,'controller')
                    error(['Variable is not "',type,'" class.'])
                end
                obj.children{end+1} = cls;
            end
            cls.register_parent(obj,'overwrite')
            obj.editted(['add ',char(type)]);
        end
    end
end
