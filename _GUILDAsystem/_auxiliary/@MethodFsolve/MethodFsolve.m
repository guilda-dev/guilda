classdef (Sealed = true) MethodFsolve < auxiliary
% fsolve solver of a nonlinear equation F(x) = 0 (needs Optimization Toolbox).
%
% solve checks Optimization Toolbox first (tools.require_toolbox) and stops with
% GUILDA:require_toolbox:Unavailable without it. With Jac, fsolve uses that Jacobian
% (SpecifyObjectiveGradient); without it, finite differences. 0 for FunctionTolerance,
% MaxIterations or MaxFunEvals keeps the fsolve default.
%
% <@Examples>
% ```matlab
% fs = MethodFsolve(Fcn=@(x) x.^2 - 4, Jac=@(x) diag(2*x), InitVal=1);
% [x, flag, output] = fs.solve();
% ```
%
% See also SolverPF, MethodNewtonRaphson

    properties (Access=public) % Settings
        Fcn                                                                                                                                                % Function F of F(x) = 0. <@Type> function_handle
        Jac                                                                                                                                                % Jacobian of Fcn; [] for finite differences. <@Type> function_handle
        InitVal (:,1) double                                                                                                                               % Initial value of x.
        FunctionTolerance (1,1) double {mustBeNonnegative} = 0                                                                                             % FunctionTolerance option of fsolve; 0 keeps the fsolve default.
        MaxIterations (1,1) double {mustBeNonnegative,mustBeInteger} = 0                                                                                   % MaxIterations option of fsolve; 0 keeps the fsolve default.
        MaxFunEvals (1,1) double {mustBeNonnegative,mustBeInteger} = 0                                                                                     % MaxFunctionEvaluations option of fsolve; 0 keeps the fsolve default.
        Display (1,1) string {mustBeMember(Display,["none","iter","iter-detailed","final","final-detailed"])} = "none"                                       % Display option of fsolve.
        UseParallel (1,1) logical = false                                                                                                                  % UseParallel option of fsolve.
        PlotFcn (1,1) string {mustBeMember(PlotFcn,["none","optimplotx","optimplotfunccount","optimplotfval","optimplotstepsize","optimplotfirstorderopt"])} = "none"  % PlotFcn option of fsolve; "none" for no plot.
        Feature (1,1) string = "MethodFsolve"                                                                                                              % Name of the calling feature, shown in the error without Optimization Toolbox.
    end

    methods
        function obj = MethodFsolve(opt)
        % Create an fsolve solver; the Name-Value options are the public properties.
            arguments (Input)
                opt.?MethodFsolve
            end
            arguments (Output)
                obj  % fsolve solver.
            end
            for s_name = string(fieldnames(opt)).'
                obj.(s_name) = opt.(s_name);
            end
        end

        [x, flag, output, rm_history, rv_step] = solve(obj)
    end
end
