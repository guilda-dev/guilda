classdef broadcast_PI_AGC < GlobalController    

    properties
        iv_odeX
        iv_odeU
        iv_odeY
    end

    properties
        JacobiAxx
        JacobiBxv
        JacobiBxu
        JacobiCxx
        JacobiDxv
        JacobiDxu
    end
        
    
    methods
        function obj = broadcast_PI_AGC(varargin, opt)
            arguments (Input,Repeating)
                varargin (1,1) string                 
            end
            arguments
                opt.beta  (1,:) double
                opt.alpha (:,1) double
                opt.kP    (1,1) double
                opt.kI    (1,1) double
            end
        end                   

        function dx = fcn_dx(t, x, V, u, param, omega0) %#ok
            dx = obj.beta * x(obj.iv_odeU);
        end

        function y = fcn_Y(t, x, V, u, param, omega0) %#ok
            w =  obj.beta * x(obj.iv_odeX);
            y = -obj.alpha .* (obj.kP * w + obj.kI * x(obj.iv_odeX));
        end               
                        
    end
end