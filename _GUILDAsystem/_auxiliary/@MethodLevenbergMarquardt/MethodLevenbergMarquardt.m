classdef (Sealed = true) MethodLevenbergMarquardt < auxiliary
% Levenberg-Marquardt solver of a nonlinear equation F(x) = 0.
%
% Each step solves (J'J + mu*I) dx = -J'F with the Jacobian J of Jac. A step that reduces
% |F| is taken and mu is divided by 10; otherwise mu is multiplied by 10 and the step is
% tried again. mu starts at 1e-6 times the largest column norm^2 of J, so near a regular
% solution the steps are Newton steps. Converged when max|F(x)| <= ConvTol; when mu
% exceeds 1e20 without a decrease of |F| the iteration stops at a local minimum of |F|.
%
% <@Examples>
% ```matlab
% lm = MethodLevenbergMarquardt(Fcn=@(x) x.^2 - 4, Jac=@(x) diag(2*x), InitVal=1);
% [x, flag] = lm.solve();
% ```
%
% See also SolverPF, MethodNewtonRaphson

    properties (Access=public) % Settings
        Fcn                                                                                                           % Function F of F(x) = 0. <@Type> function_handle
        Jac                                                                                                           % Jacobian of Fcn (sparse or full). <@Type> function_handle
        InitVal (:,1) double                                                                                          % Initial value of x.
        ConvTol (1,1) double {mustBePositive} = 1e-8                                                                  % Tolerance of the largest |F(x)| for convergence.
        MaxIter (1,1) double {mustBeNonnegative} = 100                                                                % Maximum number of taken steps.
        Display (1,1) string {mustBeMember(Display,["none","iter","iter-detailed","final","final-detailed"])} = "none"  % "iter"/"iter-detailed" print each iteration; any value but "none" prints the final message.
    end

    methods
        function obj = MethodLevenbergMarquardt(opt)
        % Create a Levenberg-Marquardt solver; the Name-Value options are the public properties.
            arguments (Input)
                opt.?MethodLevenbergMarquardt
            end
            arguments (Output)
                obj  % Levenberg-Marquardt solver.
            end
            for s_name = string(fieldnames(opt)).'
                obj.(s_name) = opt.(s_name);
            end
        end

        [x, flag, output, rm_history, rv_step] = solve(obj)
    end
end
