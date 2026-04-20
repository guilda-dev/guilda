classdef SolverPF < auxiliary
    properties(Access=public)
        MaxIterations (1,1) double {mustBeNonnegative,mustBeInteger} = 0
        Display       (1,1) string {mustBeMember(Display,["none","iter","iter-detailed","final","final-detailed"])} = "none"
        MaxFunEvals   (1,1) double {mustBeNonnegative,mustBeInteger} = 0
        UseParallel   (1,1) logical = false
        PlotFcn       (1,1) string {mustBeMember(PlotFcn,["none","optimplotx","optimplotfunccount","optimplotfval","optimplotstepsize","optimplotfirstorderopt"])} ="none"
        WhenFailed    (1,1) string {mustBeMember(WhenFailed,["WARN","ERROR","DISP","NONE"])} = "NONE"
        ExportJSON    (1,1) logical = false;
    end

    properties(SetAccess=private)
        rm_response
        rr_stepsize
        i_iteration 
    end
        
    methods
        function obj = SolverPF(opt)
            arguments
                opt.?SolverPF
            end
            sct_def = GUILDA.config("EnvFsolve");
            str_fn  = fieldnames(sct_def);
            for i_fi = 1:numel(str_fn)
                stri = str_fn{i_fi};
                if isfield(opt,stri)
                    obj.(stri) = opt.(stri);
                else
                    obj.(stri) = sct_def.(stri);
                end
            end
        end

        opt = optimoption(obj)
        stop = OutputFcn(obj, x, optimValues, state)
        [powerflow_bus,flag,output] = solve(obj, tab_PFset, cm_Y)

    end
end
