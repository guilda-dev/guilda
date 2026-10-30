classdef PowerFlowResult < AnalysisResult
% Result of net.calculate_powerflow.
%
% Holds the bus voltages, currents and power injections of the solution, the branch flows,
% and the voltages at each iteration (or time step of the "dynamic" method). It holds
% computed values only; the power flow settings of the buses and components stay with the
% network. Plot draws the voltage profile. Export writes the bus or branch table (CSV,
% Excel) or the iteration history (JSON for the GridSpring viewer).
%
% <@Examples>
% ```matlab
% net = network.IEEE14bus();
% [result, flag, output] = net.calculate_powerflow();
% result.tab_bus           % Varg, V, P, Q, Vphasor, Iphasor of each bus
% result.tab_branch        % flows and losses of each branch
% result.Plot();           % voltage profile
% result.Export("pf.csv", Table="branch");
% ```
%
% See also PowerFlowCalculation, AnalysisResult

    properties (SetAccess=private) % Result
        % Bus values of the solution, one row per bus (row names = bus tags).
        % Columns: Varg [rad], V [pu], P, Q (injections into the network) [pu], Vphasor,
        % Iphasor [pu]. The same table as the first output of calculate_powerflow in v3.
        tab_bus table = table()

        % Branch flows, one row per branch (row names = branch tags).
        % "from" is br.a_Bus{1}, "to" is br.a_Bus{2}. Pfrom, Qfrom, Pto, Qto: power flowing into
        % the branch at each end [pu]; Ifrom, Ito: current phasors into the branch [pu]; Ploss,
        % Qloss: losses of the branch (sum of both ends) [pu].
        tab_branch table = table()

        % [pu] Bus voltage phasors at each iteration or output time.
        % One row per bus in the order of tab_bus, one column per iteration ("algebraic") or
        % output time ("dynamic").
        cm_Vhistory double = zeros(0,0)

        % Iteration numbers ("algebraic") or times [s] ("dynamic") of cm_Vhistory.
        rv_step double = zeros(1,0)
    end

    methods
        function obj = PowerFlowResult(net, solver, options, flag, output, elapsed, tab_bus, tab_branch, cm_Vhistory, rv_step)
        % Create a power flow result.
        %
        % Stores the computed values of a power flow calculation.
            arguments
                net               = [] % Analysed network; see AnalysisResult.
                solver            = "PowerFlowCalculation" % Solver object or its class name; see AnalysisResult.
                options    struct = struct() % Effective settings; see AnalysisResult.
                flag              = false % Success or convergence flag; see AnalysisResult.
                output     struct = struct() % Solver details; see AnalysisResult.
                elapsed           = NaN % [s] Elapsed time or tic value; see AnalysisResult.
                tab_bus    table  = table() % Bus values (see tab_bus).
                tab_branch table  = table() % Branch flows (see tab_branch).
                cm_Vhistory double = zeros(0,0) % [pu] Bus voltages at each step.
                rv_step    double = zeros(1,0) % Iteration numbers or times of cm_Vhistory.
            end
            arguments (Output)
                obj % The result object.
            end
            obj@AnalysisResult(net, solver, options, flag, output, elapsed);
            obj.tab_bus     = tab_bus;
            obj.tab_branch  = tab_branch;
            obj.cm_Vhistory = cm_Vhistory;
            obj.rv_step     = reshape(rv_step, 1, []);
        end

        fig = Plot(obj, opt)
        str_file = Export(obj, filename, opt)
    end
end
