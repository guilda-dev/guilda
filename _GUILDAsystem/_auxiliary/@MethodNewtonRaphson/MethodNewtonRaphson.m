classdef (Sealed = true) MethodNewtonRaphson < MethodBase
% Newton-Raphson solver of a nonlinear equation F(x) = 0.
%
% The power flow (Method="newton") uses it, and the continuation power flow uses it as its
% corrector. Give the equation and the options as Name-Value arguments of the constructor
% (they are the public properties), then call solve (see MethodBase for the outputs).
% Without Jac the Jacobian is computed by central differences with step Increment; giving
% Jac is usually faster. Fcn may be a symbolic expression (needs Symbolic Math Toolbox);
% GUILDA itself always passes function handles.
%
% - Iterates x = x - StepSize * (J(x) \ F(x)) until the largest |F(x)| is at most ConvTol.
% - A singular J(x) gives the minimum norm step (lsqminnorm) instead, without a warning.
% - flag -2: F(x) is no longer finite (diverged), or the step is at the rounding level of x
%   (at most 10*eps(max(1, max|x|))) while |F| > ConvTol (no solution, e.g. the minimum
%   norm steps of an island without a slack bus).
% - A call that does not take flag warns GUILDA:MethodNewtonRaphson:MaxIteration when
%   MaxIter is reached.
%
% <@Examples>
% ```matlab
% nrm = MethodNewtonRaphson(Fcn=@(x) [x(1)^2 + x(2) - 2; x(2)^3 - 1], InitVal=[0.5; 0.5]);
% [x, flag, output] = nrm.solve();
% ```
%
% See also MethodBase, SolverPF, SolverCPF, MethodLevenbergMarquardt

    properties (Access=public) % Settings
        StepSize (1,1) double = 1   % Factor of the update x = x - StepSize*dx; large values may not converge.
    end

    methods
        function obj = MethodNewtonRaphson(opt)
        % Create a Newton-Raphson solver.
        %
        % The Name-Value options are the public properties; the others keep the defaults
        % (ConvTol 1e-5, MaxIter 1000, InitVal 1, Increment 1e-4, StepSize 1). A symbolic
        % Fcn is converted to function handles of Fcn and its Jacobian.
            arguments (Input)
                opt.?MethodNewtonRaphson
            end
            arguments (Output)
                obj  % Newton-Raphson solver.
            end
            obj.ConvTol   = 1e-5;
            obj.MaxIter   = 1000;
            obj.InitVal   = 1;
            obj.Increment = 1e-4;
            obj.set_options(opt);

            if isa(obj.Fcn, "sym")
                % The symbolic path is optional and needs Symbolic Math Toolbox.
                if ~MethodNewtonRaphson.has_symbolic()
                    error(msg("GUILDA:MethodNewtonRaphson:SymbolicUnavailable"));
                end
                sv_x = symvar(obj.Fcn);
                obj.Jac = matlabFunction(jacobian(obj.Fcn, sv_x), "Vars", sv_x);
                obj.Fcn = matlabFunction(obj.Fcn, "Vars", sv_x);
            elseif ~isempty(obj.Fcn) && ~isa(obj.Fcn, "function_handle")
                error(msg("GUILDA:MethodNewtonRaphson:InvalidInput"))
            end
        end
    end

    methods (Static,Access=private,Hidden)
        l = has_symbolic()
    end

    methods (Access=public)
        [x, flag, output, rm_history, rv_step] = solve(obj)
    end
end
