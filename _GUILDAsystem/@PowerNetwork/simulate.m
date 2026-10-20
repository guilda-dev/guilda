function [sim_t, sim_y] = simulate(obj, time, odeopt)
% <@Desc>
% Runs a time-domain dynamic simulation of the power network.
% <@Role>
% Simulation
% <@Abst>
% Constructs the ODE system and integrates over the given time table.
% <@Signatures>
% [
%   "[sim_t, sim_y] = net.simulate(time)"
% ]
% <@varargin>
% [
%   {
%     "Name": "time",
%     "Type": "table",
%     "Description": "Simulation time table specifying Time, State, Bus, and disconnect info for each stage.",
%     "Required": false,
%     "Default": "default steady-state table"
%   },
%   {
%     "Name": "Solver",
%     "Type": "matlab.ode.SolverID",
%     "Description": "ODE solver to use (e.g., \"ode15s\").",
%     "Required": false,
%     "Default": "\"ode15s\""
%   },
%   {
%     "Name": "AbsoluteTolerance",
%     "Type": "double scalar",
%     "Description": "Absolute tolerance for the ODE solver.",
%     "Required": false,
%     "Default": "1e-6"
%   },
%   {
%     "Name": "RelativeTolerance",
%     "Type": "double scalar",
%     "Description": "Relative tolerance for the ODE solver.",
%     "Required": false,
%     "Default": "1e-3"
%   }
% ]
% <@varargout>
% [
%   {
%     "Name": "sim_t",
%     "Type": "double vector",
%     "Description": "Time vector of the simulation result."
%   },
%   {
%     "Name": "sim_y",
%     "Type": "double matrix",
%     "Description": "State matrix of the simulation result (rows = states, columns = time steps)."
%   }
% ]
    arguments
        obj 
        time (:,:) {mustBeA(time, "table")} = table([0,50],"steady state",0,[0 0], 'RowNames',{'Time Stage1'}, 'VariableNames',{'Time','State','Bus','Dis connect(Bus / Component No.)'})        
    end
    arguments
        odeopt.ODEFcn          (1,1) {mustBeA(odeopt.ODEFcn    , ["odeFunction"   ,"function_handle"])} = @(t,x)[]        
        odeopt.Jacobian        (1,1) {mustBeA(odeopt.Jacobian  , ["odeJacobian"   ,"function_handle"])} = odeJacobian
        odeopt.MassMatrix      (1,1) {mustBeA(odeopt.MassMatrix, ["odeMassMatrix" ,"function_handle"])} = odeMassMatrix
        odeopt.InitialTime     (1,1) double {mustBeReal} = 0       
        odeopt.Parameters      (:,1) double = []
        odeopt.InitialSlope    (:,1) double = []                
        odeopt.InitialValue    (:,1) double = []
        odeopt.NonNegativeVariables (:,1) {mustBeInteger} = 1       
        odeopt.EventDefinition {mustBeA( odeopt.EventDefinition,"odeEvent"       )} = odeEvent      
        odeopt.DelayDefinition {mustBeA( odeopt.DelayDefinition,"odeDelay"       )} = odeDelay
        odeopt.Sensitivity     {mustBeA( odeopt.Sensitivity    ,"odeSensitivity" )} = odeSensitivity                                          
        odeopt.EquationType    (1,1) string {mustBeMember(odeopt.EquationType, ["standard","fullyimplicit","delay"])} = "standard"
        odeopt.Solver          matlab.ode.SolverID = "ode15s"
        odeopt.AbsoluteTolerance    (1,1) double {mustBePositive, mustBeBetween(odeopt.AbsoluteTolerance,1e-15,1e-3, "closed")} = 1e-6
        odeopt.RelativeTolerance    (1,1) double {mustBePositive, mustBeBetween(odeopt.RelativeTolerance,1e-15,1e-3, "closed")} = 1e-3
        odeopt.SeparateComplexParts matlab.lang.OnOffSwitchState = "on"
    end    

    [Mass, x0] = obj.reset_odeset();        

    func              = ode;       
    func.InitialValue = x0;
    func.MassMatrix   = odeMassMatrix("MassMatrix", Mass, "Singular", "yes");
    func.AbsoluteTolerance = odeopt.AbsoluteTolerance;
    func.RelativeTolerance = odeopt.RelativeTolerance;
    func.Solver       = odeopt.Solver;
    func.EquationType = odeopt.EquationType;    
    
    for i=1:size(time, 1)        

        Ymat    = obj.get_admittance_matrix;            
        rm_Ymat = tools.complex2matrix(Ymat.Variables);
        iv_Vbus = cell2mat( cellfun(@(BUS) BUS.iv_odeX, obj.a_Bus, 'UniformOutput', false) );    
    
        rv_dXall  = @(t, rv_Xall) obj.get_dx(t, rv_Xall, zeros(size(rv_Xall)), rm_Ymat, iv_Vbus);        
        % rm_Jacobi = @(t, rv_Xall) obj.get_Jacobi(t, rv_Xall, zeros(size(rv_Xall)), rm_Ymat, iv_Vbus);        

        rv_dXall(0,x0)
        
        func.ODEFcn     = rv_dXall;        
        % func.Jacobian   = odeJacobian("Jacobian", rm_Jacobi);        
    
        t     = time.Time;
        sol   = solve(func, t(1), t(2));
        sim_t = sol.Time;
        sim_y = sol.Solution;
        
        % func.InitialValue = update_odeX0(sim_y, evnt);
    end
end
