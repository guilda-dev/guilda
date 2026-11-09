classdef (Sealed = true) MethodGradient < MethodBase
% Gradient iteration x = x + StepSize*d(x) that drives a mismatch to zero.
%
% Fcn returns the step direction d(x) and, as an optional second output, the mismatch r(x)
% that is tested for convergence (d(x) itself when there is no second output). The
% iteration converges when max|r(x)| <= ConvTol; a non-finite d or r stops it as
% diverged. Fcn may return NaN to mark a point outside its domain. The convergence is
% linear: many cheap iterations instead of the few Jacobian solves of MethodNewtonRaphson.
%
% The power flow (Method="gradient") uses it with x = [theta; V] of the buses,
% d = [dP; dQ./V] and r = [dP; dQ] (the slack values and the PV voltages kept fixed).
%
% <@Examples>
% ```matlab
% mg = MethodGradient(Fcn=@(x) [1; 2] - x, InitVal=[0; 0], StepSize=0.5);
% [x, flag] = mg.solve();
% ```
%
% See also MethodBase, SolverPF, MethodNewtonRaphson

    properties (Access=public) % Settings
        StepSize (1,1) double {mustBePositive} = 1   % Factor of the update x = x + StepSize*d(x).
    end

    methods
        function obj = MethodGradient(opt)
        % Create a gradient iteration; the Name-Value options are the public properties
        % (defaults: ConvTol 1e-8, MaxIter 1e6). Fcn returns d or [d, r]; Jac is not used.
            arguments (Input)
                opt.?MethodGradient
            end
            arguments (Output)
                obj  % Gradient iteration.
            end
            obj.ConvTol = 1e-8;
            obj.MaxIter = 1e6;
            obj.set_options(opt);
        end

        [x, flag, output, rm_history, rv_step] = solve(obj)
    end
end
