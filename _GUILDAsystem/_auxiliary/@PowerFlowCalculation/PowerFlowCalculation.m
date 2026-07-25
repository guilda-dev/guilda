classdef PowerFlowCalculation < auxiliary
    properties(Access=public)
        MaxIterations (1,1) double {mustBeNonnegative,mustBeInteger}
        Display       (1,1) string {mustBeMember(Display,["none","iter","iter-detailed","final","final-detailed"])}='none'
        MaxFunEvals   (1,1) double {mustBeNonnegative,mustBeInteger}
        UseParallel   (1,1) logical
        PlotFcn       (1,1) string {mustBeMember(PlotFcn,["none","optimplotx","optimplotfunccount","optimplotfval","optimplotstepsize","optimplotfirstorderopt"])}="none"
        WhenFailed    (1,1) string {mustBeMember(WhenFailed,["WARN","ERROR","DISP","NONE"])}="NONE"
        dynamic       (1,1) struct  = struct("Mass",0,"Damper",0.1,"foh_PQ",0,"t_span",0:1/120:50);
    end

    properties(SetAccess=private)
        rm_response
        rr_step
        i_iteration 
    end
        
    methods
        function obj = PowerFlowCalculation()
            sct = GUILDA.config("PowerFlowCalculation");
            obj.MaxIterations = sct.MaxIterations.Value;
            obj.Display       = sct.Display.Value;
            obj.MaxFunEvals   = sct.MaxFunEvals.Value;
            obj.UseParallel   = sct.UseParallel.Value;
            obj.PlotFcn       = sct.PlotFcn.Value;
            obj.WhenFailed    = sct.WhenFailed.Value;
        end
        
        [powerflow_bus,flag,output] = solve(obj, net, mode, opt)
        [cv_Vbus,flag,output] = solve_algebraic(obj, tab_PFset, cm_Y)
        [cv_Vbus,flag,output] = solve_dynamic(  obj, tab_PFset, cm_Y)
        stop = OutputFcn(obj, x, optimValues, state)

    end
end
