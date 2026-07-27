classdef broadcast_PI_AGC < GlobalController    

    properties (Constant, Hidden)
        key  = "agc"
        sv_x = "xi"
        sv_u = "omega"
        sv_y = "Pmech"
        sv_para = ["alpha","beta","kP","kI"]
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
            obj.set_odefcn(60);
        end

        function [rv_Xequilibrium, rv_Uequilibrium] = get_equilibrium(obj)
            nCU = numel(obj.controlledUnits);
            rv_Xequilibrium = 0;
            rv_Uequilibrium = zeros(nCU,1);
        end                                        
    end
    
    methods (Static)
        dx = fcn_dx(t, x, V, I, u, param, omega0)
        y  = fcn_y(t, x, V, I, u, param, omega0)
        M  = fcn_Mass(t, x, V, I, u, param, omega0)

        [Axx,Bxv,Bxi,Bxu] = Jacobi_dx(t,x,V,I,u,param,omega0);
        [Cyx,Dyv,Dyi,Dyu] = Jacobi_Y(t,x,V,I,u,param,omega0);
    end
end