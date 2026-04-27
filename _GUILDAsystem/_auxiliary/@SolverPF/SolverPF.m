classdef SolverPF < auxiliary
% <@Desc>
% Power flow solver class used by PowerNetwork to perform steady-state calculations.
% Supports both algebraic (Newton-Raphson) and dynamic power flow methods.
% <@Role>
% auxiliary
% <@Constructor>
% SolverPF(opt)
%  i.e.
%  >> solver = SolverPF()
%  >> solver = SolverPF(MaxIterations=100, Display="iter")
%      - MaxIterations: maximum iterations for the solver (default: from GUILDA config)
%      - Display:       display mode for solver output (default: "none")
%      - WhenFailed:    behavior when solver fails ("WARN","ERROR","DISP","NONE") (default: "NONE")

    properties(Access=public)

        % <@Desc> Maximum number of iterations for the power flow solver.
        % <@Role> Solver Option
        % <@Type> double
        % <@Size> 1x1
        MaxIterations (1,1) double {mustBeNonnegative,mustBeInteger} = 0

        % <@Desc> Display mode for solver iteration output.
        % <@Role> Solver Option
        % <@Type> string
        % <@Size> 1x1
        Display       (1,1) string {mustBeMember(Display,["none","iter","iter-detailed","final","final-detailed"])} = "none"

        % <@Desc> Maximum number of function evaluations for the power flow solver.
        % <@Role> Solver Option
        % <@Type> double
        % <@Size> 1x1
        MaxFunEvals   (1,1) double {mustBeNonnegative,mustBeInteger} = 0

        % <@Desc> Flag to enable parallel computation in the solver.
        % <@Role> Solver Option
        % <@Type> logical
        % <@Size> 1x1
        UseParallel   (1,1) logical = false

        % <@Desc> Plot function name for monitoring solver progress.
        % <@Role> Solver Option
        % <@Type> string
        % <@Size> 1x1
        PlotFcn       (1,1) string {mustBeMember(PlotFcn,["none","optimplotx","optimplotfunccount","optimplotfval","optimplotstepsize","optimplotfirstorderopt"])} ="none"

        % <@Desc> Behavior when the solver fails to converge ("WARN","ERROR","DISP","NONE").
        % <@Role> Solver Option
        % <@Type> string
        % <@Size> 1x1
        WhenFailed    (1,1) string {mustBeMember(WhenFailed,["WARN","ERROR","DISP","NONE"])} = "NONE"

        % <@Desc> Dynamic solver settings (Mass, Damper, foh_PQ) for dynamic power flow method.
        % <@Role> Solver Option
        % <@Type> struct
        % <@Size> 1x1
        dynamic       (1,1) struct  = struct("Mass",0,"Damper",0.1,"foh_PQ",0);
    end

    properties(SetAccess=private)

        % <@Desc> Response data from the most recent solver execution.
        % <@Role> Solver Internal
        % <@Type> double
        % <@Size> Nx1
        rm_response

        % <@Desc> Step size data from the most recent solver execution.
        % <@Role> Solver Internal
        % <@Type> double
        % <@Size> Nx1
        rr_step

        % <@Desc> Iteration count from the most recent solver execution.
        % <@Role> Solver Internal
        % <@Type> double
        % <@Size> 1x1
        i_iteration 
    end
        
    methods
        function obj = SolverPF(opt)
        % <@Desc>
        % Creates a SolverPF instance with the given solver options.
        % <@Role>
        % Constructor
        % <@Abst>
        % Initialize solver options from arguments and GUILDA configuration.
        % <@Signatures>
        % [
        %   "obj = SolverPF()",
        %   "obj = SolverPF(MaxIterations=100, Display=\"iter\")"
        % ]
        % <@varargin>
        % [
        %   {
        %     "Name": "opt",
        %     "Type": "name-value pairs",
        %     "Description": "Solver options matching SolverPF properties (MaxIterations, Display, WhenFailed, etc.).",
        %     "Required": false,
        %     "Default": "from GUILDA config"
        %   }
        % ]
        % <@varargout>
        % [
        %   {
        %     "Name": "obj",
        %     "Type": "SolverPF",
        %     "Description": "Created SolverPF instance."
        %   }
        % ]
            arguments
                opt.?SolverPF
            end
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
        
        [powerflow_bus,flag,output] = solve(obj, net, mode)
        [cv_Vbus,flag,output] = solve_algebraic(obj, tab_PFset, cm_Y)
        [cv_Vbus,flag,output] = solve_dynamic(  obj, tab_PFset, cm_Y)
        stop = OutputFcn(obj, x, optimValues, state)

    end
end
