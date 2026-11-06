classdef ResultPF < ResultBase
% Result of net.calculate_powerflow.
%
% Holds the bus voltages, currents and power injections of the solution, the branch flows,
% and the voltages at each iteration (or time step of the "dynamic" method). It holds
% computed values only; the power flow settings of the buses and components stay with the
% network. Plot draws the voltage profile. Export writes the bus or branch table (CSV,
% Excel) or the iteration history (JSON for the GridSpring viewer).
%
% - `tab_bus` has the bus tags as row names; it is the same table as the first output of
%   calculate_powerflow in v3.
% - `tab_branch` has the branch tags as row names. "from" is br.a_Bus{1}, "to" is
%   br.a_Bus{2}. Pfrom, Qfrom, Pto, Qto: power flowing into the branch at each end; Ifrom,
%   Ito: current phasors into the branch; Ploss, Qloss: losses of the branch (sum of both
%   ends).
% - `cm_Vhistory` has one column per iteration ("algebraic") or output time ("dynamic").
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
% See also SolverPF, ResultBase

    properties (SetAccess=private) % Result
        tab_bus table = table()          % Bus values, one row per bus: Varg [rad], V [pu], P, Q (injections into the network) [pu], Vphasor, Iphasor [pu].
        tab_branch table = table()       % Branch flows, one row per branch: Pfrom, Qfrom, Pto, Qto, Ifrom, Ito, Ploss, Qloss [pu] (see the class help).
        cm_Vhistory double = zeros(0,0)  % [pu] Bus voltage phasors, one row per bus (tab_bus order), one column per iteration or output time.
        rv_step double = zeros(1,0)      % Iteration numbers ("algebraic") or times [s] ("dynamic") of cm_Vhistory.
    end

    methods
        function obj = ResultPF(net, solver, options, flag, output, elapsed, tab_bus, tab_branch, cm_Vhistory, rv_step)
        % Create a power flow result.
        %
        % Stores the computed values of a power flow calculation.
            arguments (Input)
                net               = [] % Analysed network; see ResultBase.
                solver            = "SolverPF" % Solver object or its class name; see ResultBase.
                options    struct = struct() % Effective settings; see ResultBase.
                flag              = false % Success or convergence flag; see ResultBase.
                output     struct = struct() % Solver details; see ResultBase.
                elapsed           = NaN % [s] Elapsed time or tic value; see ResultBase.
                tab_bus    table  = table() % Bus values (see tab_bus).
                tab_branch table  = table() % Branch flows (see tab_branch).
                cm_Vhistory double = zeros(0,0) % [pu] Bus voltages at each step.
                rv_step    double = zeros(1,0) % Iteration numbers or times of cm_Vhistory.
            end
            arguments (Output)
                obj % The result object.
            end
            obj@ResultBase(net, solver, options, flag, output, elapsed);
            obj.tab_bus     = tab_bus;
            obj.tab_branch  = tab_branch;
            obj.cm_Vhistory = cm_Vhistory;
            obj.rv_step     = reshape(rv_step, 1, []);
        end

        fig = Plot(obj, opt)
        s_file = Export(obj, filename, opt)
    end
end
