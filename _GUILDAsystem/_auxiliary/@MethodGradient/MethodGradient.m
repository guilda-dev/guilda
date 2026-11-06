classdef (Sealed = true) MethodGradient < auxiliary
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
% See also SolverPF, MethodNewtonRaphson

    properties (Access=public) % Settings
        Fcn                                                                                                           % Step direction: d = Fcn(x) or [d, r] = Fcn(x) (see the class help). <@Type> function_handle
        InitVal (:,1) double                                                                                          % Initial value of x.
        StepSize (1,1) double {mustBePositive} = 1                                                                    % Factor of the update x = x + StepSize*d(x).
        ConvTol (1,1) double {mustBePositive} = 1e-8                                                                  % Tolerance of the largest |r(x)| for convergence.
        MaxIter (1,1) double {mustBeNonnegative} = 1e6                                                                % Maximum number of iterations.
        Display (1,1) string {mustBeMember(Display,["none","iter","iter-detailed","final","final-detailed"])} = "none"  % "iter"/"iter-detailed" print each iteration; any value but "none" prints the final message.
    end

    methods
        function obj = MethodGradient(opt)
        % Create a gradient iteration; the Name-Value options are the public properties.
            arguments (Input)
                opt.?MethodGradient
            end
            arguments (Output)
                obj  % Gradient iteration.
            end
            for s_name = string(fieldnames(opt)).'
                obj.(s_name) = opt.(s_name);
            end
        end

        [x, flag, output, rm_history, rv_step] = solve(obj)
    end
end
