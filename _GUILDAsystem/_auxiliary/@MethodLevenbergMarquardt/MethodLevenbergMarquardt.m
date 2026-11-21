classdef (Sealed = true) MethodLevenbergMarquardt < MethodBase
% Levenberg-Marquardt solver of a nonlinear equation F(x) = 0.
%
% Each step solves (J'J + mu*I) dx = -J'F with the Jacobian J of Jac. A step that reduces
% |F| is taken and mu is divided by 10; otherwise mu is multiplied by 10 and the step is
% tried again. mu starts at 1e-6 times the largest column norm^2 of J, so near a regular
% solution the steps are Newton steps. Converged when max|F(x)| <= ConvTol; when mu
% exceeds 1e20 without a decrease of |F| the iteration stops at a local minimum of |F|. Without Jac, the Jacobian is computed by
% central differences (see MethodBase).
%
% <@Examples>
% ```matlab
% lm = MethodLevenbergMarquardt(Fcn=@(x) x.^2 - 4, Jac=@(x) diag(2*x), InitVal=1);
% [x, flag] = lm.solve();
% ```
%
% See also MethodBase, SolverPF, MethodNewtonRaphson

    methods
        function obj = MethodLevenbergMarquardt(opt)
        % Create a Levenberg-Marquardt solver; the Name-Value options are the public
        % properties (defaults: ConvTol 1e-8, MaxIter 100).
            arguments (Input)
                opt.?MethodLevenbergMarquardt
            end
            arguments (Output)
                obj  % Levenberg-Marquardt solver.
            end
            obj.ConvTol = 1e-8;
            obj.MaxIter = 100;
            obj.set_options(opt);
        end

        [x, flag, output, rm_history, rv_step] = solve(obj)
    end
end
