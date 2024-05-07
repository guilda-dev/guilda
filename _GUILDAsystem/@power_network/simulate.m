function [out,sim] = simulate(obj, t, varargin)
    obj.check_EditLog;
    simulator =  supporters.for_simulate.odefactory(obj,t,varargin{:});
    [out,sim] = simulator.run;    
end