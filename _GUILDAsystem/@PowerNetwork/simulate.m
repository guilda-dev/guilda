function [odeResult,varargout] = simulate(obj, time, varargin, option)
    arguments
        obj 
        time (:,1) double = [] 
    end
    arguments (Input, Repeating)
        varargin {mustBeA(varargin, 'odeEventSet')}
    end
    arguments        
        option.InitialTime       (1,1) double {mustBeReal} = 0              
        option.EquationType      (1,1) string {mustBeMember(option.EquationType, ["standard","fullyimplicit","delay"])} = "standard"
        option.Solver            matlab.ode.SolverID = "ode15s"
        option.AbsoluteTolerance (1,1) double {mustBePositive, mustBeBetween(option.AbsoluteTolerance,1e-15,1e-3, "closed")} = 1e-6
        option.RelativeTolerance (1,1) double {mustBePositive, mustBeBetween(option.RelativeTolerance,1e-15,1e-3, "closed")} = 1e-3        
        option.Reporter          (1,1) string {mustBeMember(option.Reporter,["none","disp","dialog"])} = "dialog"
        option.TimeLimit         (1,1) double = 8;
    end    

    op = [fieldnames(option)'; struct2cell(option)'];
    OS = odeSimulator(obj, time, varargin{:}, op{:});
    [odeResult,varargout{1}]= simulate(OS);
end
