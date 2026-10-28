function [odeResult,varargout] = simulate(obj, time, varargin)
    arguments
        obj 
        time (:,1) double = [] 
    end
    arguments (Input, Repeating)
        varargin {mustBeA(varargin, 'odeEventSet')}
    end    
    
    obj.check_edit("RequireEquilibrium", true);    % rebuild stale f_*; error if net.initialize() is needed
    [odeResult,varargout{1}]= obj.solver_ODE.simulate(obj,time,varargin{:});
end
