classdef (Sealed = true) MethodFsolve < MethodBase
% fsolve solver of a nonlinear equation F(x) = 0 (needs Optimization Toolbox).
%
% solve checks Optimization Toolbox first (tools.require_toolbox) and stops with
% GUILDA:require_toolbox:Unavailable without it. With Jac, fsolve uses that Jacobian
% (SpecifyObjectiveGradient); without it, the finite differences of fsolve.
%
% - ConvTol is passed as FunctionTolerance and MaxIter as MaxIterations of fsolve; 0 for
%   ConvTol, MaxIter or MaxFunEvals keeps the fsolve default.
% - flag: 1 when fsolve succeeded (exitflag > 0) and the largest |F| is at most ConvTol
%   (1e-6, the fsolve default FunctionTolerance, when ConvTol is 0); 0 when fsolve stopped
%   at MaxIterations or MaxFunctionEvaluations (exitflag 0); -2 otherwise.
% - output: the fields of MethodBase and exitflag (the exitflag of fsolve).
%
% <@Examples>
% ```matlab
% fs = MethodFsolve(Fcn=@(x) x.^2 - 4, Jac=@(x) diag(2*x), InitVal=1);
% [x, flag, output] = fs.solve();
% ```
%
% See also MethodBase, SolverPF, MethodNewtonRaphson

    properties (Access=public) % Settings
        MaxFunEvals (1,1) double {mustBeNonnegative,mustBeInteger} = 0                                                                                     % MaxFunctionEvaluations option of fsolve; 0 keeps the fsolve default.
        UseParallel (1,1) logical = false                                                                                                                  % UseParallel option of fsolve.
        PlotFcn (1,1) string {mustBeMember(PlotFcn,["none","optimplotx","optimplotfunccount","optimplotfval","optimplotstepsize","optimplotfirstorderopt"])} = "none"  % PlotFcn option of fsolve; "none" for no plot.
        Feature (1,1) string = "MethodFsolve"                                                                                                              % Name of the calling feature, shown in the error without Optimization Toolbox.
    end

    methods
        function obj = MethodFsolve(opt)
        % Create an fsolve solver; the Name-Value options are the public properties
        % (defaults: ConvTol 0 and MaxIter 0, the fsolve defaults).
            arguments (Input)
                opt.?MethodFsolve
            end
            arguments (Output)
                obj  % fsolve solver.
            end
            obj.ConvTol = 0;
            obj.MaxIter = 0;
            obj.set_options(opt);
        end

        [x, flag, output, rm_history, rv_step] = solve(obj)
    end
end
