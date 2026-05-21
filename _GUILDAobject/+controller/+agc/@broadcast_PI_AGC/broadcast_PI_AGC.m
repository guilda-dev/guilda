classdef broadcast_PI_AGC < GlobalController    

    properties (Constant, Hidden)
        key   = "agc"
        str_x = "xi"
        str_u = "omega"
        str_y = "Pmech"
        str_para = ["alpha","beta","kP","kI"]
    end           
    
    methods
        function obj = broadcast_PI_AGC(net, tag, varargin, opt)
            arguments
                net
                tag
            end
            arguments (Input,Repeating)
                varargin                  
            end
            arguments
                opt.alpha (:,1) double = 1
                opt.beta  (:,1) double = 1                
                opt.kP    (1,1) double = 100
                opt.kI    (1,1) double = 500
            end 
            obj@GlobalController(net, tag, varargin{:})            

            na = numel(opt.alpha);
            nb = numel(opt.beta);
            if na ~= nb
                error(msg('GUILDA:broadcast_PI_AGC:InvalidSize'))
            end            

            obj.para_dynamics.add_entry("alpha", opt.alpha             , "double", ...
                                         "beta", opt.beta              , "double", ...
                                           "kP", repmat(opt.kP, [na,1]), "double", ...
                                           "kI", repmat(opt.kI, [na,1]), "double");                        

        end

        function set_odefcn(obj, omega0)
            param = obj.tab_parameter.dynamics{:,obj.str_para};

            obj.fv_odeDiff = @(t,x,V,I,u) obj.fcn_dx(t,x,V,I,u,param,omega0);
            obj.fv_odeY    = @(t,x,V,I,u) obj.fcn_y(t,x,V,I,u,param,omega0);
            obj.rm_odeMass = @(t,x,V,I,u) obj.fcn_Mass(t,x,V,I,u,param,omega0);

            obj.JacobiAxx = @(t,x,V,I,u) obj.getJacobiAxx(t,x,V,I,u,param,omega0);
            obj.JacobiBxv = @(t,x,V,I,u) obj.getJacobiBxv(t,x,V,I,u,param,omega0);
            obj.JacobiBxi = @(t,x,V,I,u) obj.getJacobiBxi(t,x,V,I,u,param,omega0);
            obj.JacobiBxu = @(t,x,V,I,u) obj.getJacobiBxu(t,x,V,I,u,param,omega0);

            obj.JacobiCyx = @(t,x,V,I,u) obj.getJacobiCyx(t,x,V,I,u,param,omega0);
            obj.JacobiDyv = @(t,x,V,I,u) obj.getJacobiDyv(t,x,V,I,u,param,omega0);
            obj.JacobiDyi = @(t,x,V,I,u) obj.getJacobiDyi(t,x,V,I,u,param,omega0);
            obj.JacobiDyu = @(t,x,V,I,u) obj.getJacobiDyu(t,x,V,I,u,param,omega0);
        end

        function [cv_Xequilibrium, cv_Uequilibrium] = get_equilibrium(obj)
            nCU = numel(obj.controlledUnits);
            cv_Xequilibrium = 0;
            cv_Uequilibrium = zeros(nCU,1);
        end

        function dx = fcn_dx(obj, t, x, V, I, u, param, omega0) %#ok
            beta  = param(:,2);
            
            dx = beta.' * u;
        end

        function y = fcn_y(obj, t, x, V, I, u, param, omega0) %#ok
            alpha = param(:,1);
            beta  = param(:,2);
            kP    = param(1,3);
            kI    = param(1,4);
                        
            w = beta.' * u;
            y = -alpha * (kP * w + kI * x);
        end    

        function M = fcn_Mass(obj, t, x, V, I, u, param, omega0) %#ok
            M = 1;
        end

        function Axx = getJacobiAxx(obj, t, x, V, I, u, param, omega0) %#ok
            Axx = 0;
        end

        function Bxv = getJacobiBxv(obj, t, x, V, I, u, param, omega0) %#ok
            Bxv = [];
        end

        function Bxi = getJacobiBxi(obj, t, x, V, I, u, param, omega0) %#ok
            Bxi = [];
        end

        function Bxu = getJacobiBxu(obj, t, x, V, I, u, param, omega0) %#ok
            beta = param(:,2);
            Bxu  = beta.';
        end

        function Cyx = getJacobiCyx(obj, t, x, V, I, u, param, omega0) %#ok
            alpha = param(:,1);
            kI    = param(1,4);

            Cyx = -kI * alpha;
        end

        function Dyv = getJacobiDyv(obj, t, x, V, I, u, param, omega0) %#ok
            Dyv = [];
        end

        function Dyi = getJacobiDyi(obj, t, x, V, I, u, param, omega0) %#ok
            Dyi = [];
        end

        function Dyu = getJacobiDyu(obj, t, x, V, I, u, param, omega0) %#ok
            alpha = param(:,1);
            beta  = param(:,2);
            kP    = param(1,3);            

            Dyu = -kP * (alpha * beta.');
        end        
                        
    end    
end