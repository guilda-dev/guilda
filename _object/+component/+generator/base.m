classdef base < component

    properties(SetAccess = private)
        avr
        pss
        governor
    end

    methods
        function obj =  base(parameter)
            obj.Tag = 'Gen';
            obj.set_InputType('Add');

            if istable(parameter)
                obj.parameter = parameter;
                
            elseif isstruct(parameter)
                obj.parameter = struct2table(parameter);

            elseif ischar(parameter) || isstring(parameter)
                parameter = char(parameter);
                dataset = readtable('_object/+component/+generator/_default_para.csv');
                switch parameter
                    case 'NGT2'
                        obj.parameter = dataset(1,:);
                    case 'NGT6'
                        obj.parameter = dataset(2,:);
                    case 'NGT8'
                        obj.parameter = dataset(3,:);
                end
            end
        end
        
        function set_avr(obj, avr)
            if isa(avr, 'component.generator.avr.base')
                obj.avr = avr;
            else
               error('It is not avr class.'); 
            end
        end
        
        function set_pss(obj, pss)
            if isa(pss, 'component.generator.pss.base')
                obj.pss = pss;
            else
                error('It is not pss class.');
            end
        end

        function set_governor(obj, governor)
            if isa(governor, 'component.generator.governor.base')
                obj.governor = governor;
            else
                error('It is not governor class.');
            end
        end

        % function [A, B, C, D, BV, DV, BI, DI, R, S] = get_linear_matrix(obj, x_st, Vst, Ist)
        % 
        %     sys = obj.get_sys;
        %     sys_u = sys('I', obj.get_port_name);
        %     sys_V = sys('I', 'V');
        % 
        %     A = sys_u.a;
        %     B = sys_u.b;
        %     C = sys_u.c;
        %     D = sys_u.d;
        % 
        %     BV = sys_V.b;
        %     BI = zeros(size(A, 1), 2);
        % 
        %     DV = sys_V.d;
        %     DI = -eye(2);
        % 
        %     R = [];
        %     S = [];
        % 
        % end
        % 
        % function sys = get_sys(obj)
        % 
        %     % {Pmech,Vfield} >> {delta,omega,E,V,I}
        %     sys_gen = obj.get_system_matrix();
        % 
        %     % {V} >> {Vabs}
        %     Vst  =  tools.complex2vec(obj.V_equilibrium); 
        %     Vabs = norm(Vst);
        %     sys_V = ss(Vst'/Vabs);
        %     sys_V.InputGroup  = struct( 'Vin', 1:2);
        %     sys_V.OutputGroup = struct('Vabs', 3  );
        % 
        % 
        %     % {Vabs,Efd,u_avr} >> {Vfd}
        %     sys_avr = obj.avr.get_sys();
        % 
        %     % {omega} >> {v_pss}
        %     sys_pss = obj.pss.get_sys();
        % 
        %     % {omega_governor, u_governor} >> {omega_governor, Pmech}
        %     sys_gov = obj.governor.get_sys();
        % 
        % 
        %     G = blkdiag(sys_gen, sys_V, sys_avr, -sys_pss, sys_gov);
        %     ig = G.InputGroup;
        %     og = G.OutputGroup;
        % 
        %     feedout = [og.Pmech, og.Vfd,    og.V, og.Vabs, og.v_pss, og.Vabs, ]
        %     feedin  = [ig.Pmech, ig.Vfield, ig.V, ig.Vabs, ig.Efd, ig.omega, ig.omega_governor, ig.u_governor, ig.u_avr, ig.Vabs, ]
        % 
        % 
        %     feedin =  [ig.Pout, ig.Efd, ig.Efd_swing, ig.delta, ig.E, ig.V, ig.Vabs, ig.Vfd, ig.u_avr, ig.omega, ig.omega, ig.Pmech];
        %     feedout = [og.P,    og.Efd, og.Efd,       og.delta, og.E, og.V, og.Vabs, og.Vfd, og.v_pss, og.omega, og.omega, og.Pmech];
        %     I = ss(eye(numel(feedin)));
        % 
        %     sys = feedback(G, I, feedin, feedout, 1);
        % end

        
    end
end
