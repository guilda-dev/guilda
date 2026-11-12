classdef ResultPF < ResultBase
% Result of net.calculate_powerflow (its default Format "GUILDAorigin").
%
% Holds the bus voltages, currents and power injections of the solution, the branch flows,
% the violated operating limits and the voltages at each iteration (or time step of the
% "dynamic" method). It is built from data only: the solution table, the bus admittance
% matrix, a struct snapshot of the network (struct(net, false), no handles) and the
% solver information. It keeps no reference to the network, so a later edit of the
% network does not change it. plot_voltage draws the voltage profile; the disp_* methods print tables. export writes the bus or
% branch table (CSV, Excel) or the iteration history (JSON for the GridSpring viewer).
%
% - `tab_bus` has the bus tags as row names.
% - `tab_branch` has the branch tags as row names. "from" is the first bus of the branch,
%   "to" the second. Pfrom, Qfrom, Pto, Qto: power flowing into the branch at each end;
%   Ifrom, Ito: current phasors into the branch; Ploss, Qloss: losses of the branch (sum
%   of both ends). The admittance of each branch is the field cm_Y of the branch in the
%   snapshot (Branch.struct adds it from get_admittance_matrix), so every branch class,
%   also one of your own, gets its flows.
% - `cm_Vhistory` has one column per iteration, or per ODE step ("dynamic").
% - `tab_violation` records the operating limits (tab_parameter.operation of the
%   snapshot) that the solution violates by more than Tolerance; the power flow itself
%   never applies them, and a violation gives no warning or error. One row per violated
%   limit, 0 rows when none (or when the calculation did not converge):
%   - Class: "Bus", "Component" or "Branch"; Object: its tag.
%   - Limit: the violated limit, e.g. "Vmin", "Vmax" (bus), "Pmin", "Pmax", "Qmin",
%     "Qmax" (component), "Pmax", "Qmax", "Smax", "Imax", "Vargmax" (branch).
%   - Value: the solution value (bus V; component P, Q as initialize gives them; for a
%     branch the larger of its two ends of |P|, |Q|, |S|, |I|, and |Varg_from - Varg_to|).
%   - Bound: the limit; Excess: |Value - Bound|.
% - `tab_PFcondition`, `cm_Y` and `sct_network` are the data the result was built from.
%
% <@Examples>
% ```matlab
% net = network.IEEE14bus();
% [result, flag, output] = net.calculate_powerflow();
% result.tab_bus           % Varg, V, P, Q, Vphasor, Iphasor of each bus
% result.tab_branch        % flows and losses of each branch
% result.tab_violation     % violated operating limits (0 rows when none)
% result.plot_voltage();           % voltage profile
% result.export("pf.csv", Table="branch");
% ```
%
% See also SolverPF, ResultBase, PowerNetwork.calculate_powerflow

    properties (SetAccess=private) % Result
        tab_bus table = table()          % Bus values, one row per bus: Varg [rad], V [pu], P, Q (injections into the network) [pu], Vphasor, Iphasor [pu].
        tab_branch table = table()       % Branch flows, one row per branch: Pfrom, Qfrom, Pto, Qto, Ifrom, Ito, Ploss, Qloss [pu] (see the class help).
        cm_Vhistory double = zeros(0,0)  % [pu] Bus voltage phasors, one row per bus (tab_bus order), one column per iteration or ODE step ("dynamic").
        rv_step double = zeros(1,0)      % Iteration numbers, or virtual times ("dynamic"), of cm_Vhistory.
        tab_violation table = table()    % Violated operating limits, one row per limit: Class, Object, Limit, Value, Bound, Excess (see the class help).
    end
    properties (SetAccess=private) % Data of the calculation
        tab_PFcondition table = table()  % Power flow conditions given to the solver: Type, Varg, V, P, Q of each bus (Bus.get_pf_condition); empty when no power flow was solved.
        cm_Y double = zeros(0,0)         % [pu] Bus admittance matrix (tab_bus order).
        sct_network struct = struct()    % Snapshot of the network at the calculation: struct(net, false), a nested struct without handles.
    end

    methods
        function obj = ResultPF(tab_powerflow, cm_Y, sct_network, sct_solver)
        % Create a power flow result from data.
        %
        % Computes tab_bus, tab_branch and tab_violation from the inputs; no network object
        % is read.
            arguments (Input)
                tab_powerflow table = table() % Solution, one row per bus: V, I (complex phasors), P, Q [pu]; row names = bus tags (Format "powerflow(tab)").
                cm_Y        double = zeros(0,0) % [pu] Bus admittance matrix (tab_powerflow order).
                sct_network struct = struct() % Snapshot of the network: struct(net, false).
                sct_solver  struct = struct() % Solver information: solver, options, flag, output, elapsed (s or a tic value); optional cm_Vhistory, rv_step, tab_PFcondition.
            end
            arguments (Output)
                obj % The result object.
            end
            sct_solver = solver_info(sct_solver);
            obj@ResultBase([], sct_solver.solver, sct_solver.options, sct_solver.flag, sct_solver.output, sct_solver.elapsed);
            if isfield(sct_network, "s_tag")
                obj.s_network = string(sct_network.s_tag);
            end
            obj.sct_network     = sct_network;
            obj.cm_Y            = cm_Y;
            obj.tab_PFcondition = sct_solver.tab_PFcondition;
            obj.cm_Vhistory     = sct_solver.cm_Vhistory;
            obj.rv_step         = reshape(sct_solver.rv_step, 1, []);
            obj.tab_bus         = bus_table(tab_powerflow);
            obj.tab_violation   = rows_to_table();
            if ~isfield(sct_network, "a_Bus") || ~isfield(sct_network, "a_Branch")
                return
            end
            obj.tab_branch = branch_flow(sct_network, obj.tab_bus);
            if obj.l_success
                r_tol = 0;
                if isfield(obj.options, "Tolerance")
                    r_tol = obj.options.Tolerance;
                end
                obj.tab_violation = violation_table(sct_network, obj.tab_bus, obj.tab_branch, r_tol);
            end
        end

        fig = plot_voltage(obj, opt)
        s_file = export(obj, filename, opt)
    end
end
