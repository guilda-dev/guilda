classdef (Sealed = true) MethodDynamic < auxiliary
% Power flow by virtual bus dynamics that settle at the solution (ode15s).
%
% Each bus gets M*theta'' + D*theta' = dP and M*V'' + D*V' = dQ/V (the active power and
% reactive current mismatches); the slack angle and voltage and the PV voltages are fixed.
% Power-flow specific: it takes the bus admittance matrix and the power flow conditions of
% the buses.
%
% - The integration stops when the largest |dP| (non-slack) and |dQ| (PQ) is at most
%   Tolerance (flag 1), on voltage collapse (a PQ voltage below 0.01 pu) or phase angle
%   instability (|theta| beyond 5 turns) (flag -2), or at the virtual time 1e4 (flag 0).
%   With Damper 1, the virtual time to converge is usually below 1000 and up to about
%   3500 near the loading limit.
% - The ODE tolerances follow Tolerance: AbsTol = min(Tolerance, 1e-5) and
%   RelTol = min(100*Tolerance, 1e-4).
% - The initial voltages are the columns Varg0, V0 of PFcondition when it has them, the
%   flat start otherwise (angle 0 and magnitude 1, the set V at PV and slack buses).
% - output: iterations (number of ODE steps), algorithm, residual (largest mismatch at the
%   end), message.
%
% <@Examples>
% ```matlab
% net = network.IEEE9bus();
% Y   = net.get_admittance_matrix().Variables;
% tab = tools.vcellfun(@(b) b.get_pf_condition, net.a_Bus);
% [cv_V, flag] = MethodDynamic(Y=Y, PFcondition=tab).solve();
% ```
%
% See also SolverPF, MethodGradient

    properties (Access=public) % Settings
        Y (:,:) double                                     % [pu] Bus admittance matrix (complex, in the bus order of PFcondition).
        PFcondition table                                  % Power flow conditions of the buses (rows of Bus.get_pf_condition).
        Mass (1,1) double {mustBeNonnegative} = 0          % Mass M of the virtual bus dynamics (0: first order).
        Damper (1,1) double {mustBePositive} = 1           % Damping D of the virtual bus dynamics (with Mass 0, it only scales the virtual time).
        foh_PQ (1,1) double {mustBeNonnegative} = 0        % [s] Ramp time of the specified P and Q (0: step).
        Tolerance (1,1) double {mustBePositive} = 1e-8     % [pu] Largest P/Q mismatch for convergence.
    end

    methods
        function obj = MethodDynamic(opt)
        % Create the virtual bus dynamics; the Name-Value options are the public properties.
            arguments (Input)
                opt.?MethodDynamic
            end
            arguments (Output)
                obj  % Virtual bus dynamics.
            end
            for s_name = string(fieldnames(opt)).'
                obj.(s_name) = opt.(s_name);
            end
        end

        [cv_Vbus, flag, output, cm_Vhistory, rv_step] = solve(obj)
    end
end
