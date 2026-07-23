function [odeResult,varargout] = simulate(obj, time, varargin)
    arguments
        obj 
        time (:,1) double = [] 
    end
    arguments (Input, Repeating)
        varargin {mustBeA(varargin, 'odeEventSet')}
    end    
    
    [odeResult,varargout{1}]= obj.solver_ODE.simulate(obj,time,varargin{:});
end
