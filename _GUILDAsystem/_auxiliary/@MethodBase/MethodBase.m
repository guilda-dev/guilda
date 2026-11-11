classdef (Abstract) MethodBase < auxiliary
% Abstract base class of the solvers of a nonlinear equation F(x) = 0.
%
% MethodNewtonRaphson, MethodLevenbergMarquardt, MethodGradient and MethodFsolve inherit
% it. Give the equation and the options as Name-Value arguments of the constructor (the
% public properties), then call solve. Each subclass sets its own defaults in its
% constructor.
%
% - Convergence: the largest |F(x)| is at most `ConvTol` (MethodGradient: the largest
%   |r(x)|, see its help).
% - `solve` returns `[x, flag, output, rm_history, rv_step]`. flag is 1 converged, 0
%   `MaxIter` reached, -2 diverged or no solution. output has the fields iterations,
%   algorithm, residual (largest |F|) and message; the message is printed unless `Display`
%   is "none". flag -1: stopped by the live display of the power flow (PlotFcn).
% - Without `Jac`, the Jacobian is computed by central differences (tools.fd_jacobian)
%   with the step `Increment`.
%
% <@Examples>
% ```matlab
% nrm = MethodNewtonRaphson(Fcn=@(x) [x(1)^2 + x(2) - 2; x(2)^3 - 1], InitVal=[0.5; 0.5]);
% [x, flag, output] = nrm.solve();
% ```
%
% See also MethodNewtonRaphson, MethodLevenbergMarquardt, MethodGradient, MethodFsolve, SolverPF

    properties (Access=public) % Equation
        Fcn                                     % Function F of F(x) = 0. <@Type> function_handle
        Jac                                     % Jacobian of Fcn; [] for the numerical Jacobian (central differences with Increment). <@Type> function_handle
        InitVal (:,1) double                    % Initial value of x.
    end

    properties (Access=public) % Settings
        ConvTol (1,1) double {mustBeNonnegative}    % Tolerance of the largest |F(x)| for convergence.
        MaxIter (1,1) double {mustBeNonnegative}    % Maximum number of iterations.
        Display (1,1) string {mustBeMember(Display,["none","iter","iter-detailed","final","final-detailed"])} = "none"  % "iter"/"iter-detailed" print each iteration; any value but "none" prints the final message.
        Increment (1,1) double {mustBePositive} = 1e-4  % Step of the numerical Jacobian (x +- Increment).
    end

    properties (Access={?MethodBase, ?SolverPF}) % Live display
        f_iter = []                             % Called at each iterate as stop = f_iter(x, k, state), state "init", "iter" or "done" (PlotFcn of SolverPF); [] for none. A true stop ends solve with flag -1.
    end

    methods (Abstract)
        % Solve F(x) = 0 from InitVal.
        %
        % Returns the last iterate x, flag (1 converged, 0 MaxIter reached, -1 stopped by
        % f_iter, -2 diverged or no solution), output (iterations, algorithm, residual,
        % message), rm_history (InitVal and x after each step, one column each) and rv_step
        % (iteration numbers of rm_history). Each subclass implements its algorithm.
        [x, flag, output, rm_history, rv_step] = solve(obj)
    end

    methods (Access=protected)
        set_options(obj, opt)
        J = eval_jacobian(obj, x)
        output = make_output(obj, flag, n_iter, r_res, s_algorithm, s_name, s_fail, s_hint)
        print_iter(obj, s_algorithm, k, r_res, s_extra)
    end
end
