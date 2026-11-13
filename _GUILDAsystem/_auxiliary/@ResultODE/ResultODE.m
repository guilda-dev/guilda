classdef ResultODE < ResultBase
% Result of net.simulate.
%
% Holds the time response of the bus voltages, currents and powers, of the states and
% inputs of the components and controllers, and of their outputs. It is built from data
% only: the trajectories of the solver, the variable map and the output functions of the
% run, a struct snapshot of the network (sct_network = struct(net, false)) and the solver
% information. It keeps no reference to the network: its methods (plot_trajectory,
% get_point, export, judge_out_of_step, odeResults) work after the network is edited or
% deleted.
% flag is 1 when the simulation reached the end time, 2 when it stopped by StopOnOutOfStep
% (output.outOfStep holds the stop), 0 when it stopped by TimeLimit and -1 when the solver
% stopped early; then the trajectories end at output.tEnd. When the first phase could not
% be solved, they have no time points.
%
% The trajectory is stored once, in the order of the variable map of the network
% (rm_variable, columns = rows of tab_variable): the states of the components with their
% local controllers, the states of the global controllers, the bus voltages and the inputs
% of the components. odeResults is a view of it per bus and component, and get_point gives
% the values at a time, for example for net.get_sys(Point={sim, t}). plot_trajectory draws a
% trajectory of the buses or components. export writes all trajectories as a table (CSV,
% Excel) or as a MAT-file. judge_out_of_step judges the rotor angles (stable, out of step).
%
% - `tab_variable` has one row per variable with Index, Kind ("x" | "Vre" | "Vim" | "u"),
%   Role, Owner, Name, Label and Bus: the leading rows of net.get_variable_map() (its
%   rows uc, y and yc, the controller inputs and the signals, are not variables here).
% - In `rm_variable` the states of a tripped unit are NaN while it is tripped. The inputs u
%   are the inputs applied to the components (steady value, outputs of the controllers and
%   event inputs).
% - `rm_I` holds the columns B1 Ireal, B1 Iimag, B2 Ireal, ... They are not variables of the
%   map; odeResults.Bus(i).I and .PQ are made from them.
% - `tab_output` has the rows y (outputs of the components) and yc (outputs of the
%   controllers) of the variable map, with the columns of tab_variable. `rm_output` holds
%   their trajectories, computed by the constructor from the output functions of the
%   blocks at each time (t from the start of the phase, as the solver). The outputs of a
%   tripped unit (its states are NaN) are NaN.
% - `odeResults` has the fields t (time [s], column), Bus(i).V (table Vreal, Vimag),
%   Bus(i).I (Ireal, Iimag), Bus(i).PQ (P, Q), Bus(i).Component(j).X (states, columns named
%   by sv_x), Bus(i).Component(j).U (inputs, columns named by sv_u) and
%   Bus(i).Component(j).Y (outputs, columns named by sv_y). Bus(i) follows net.a_Bus and
%   Component(j) follows a_Component of the bus. The states and outputs of the local and
%   global controllers are in rm_variable and rm_output only.
% - At a boundary between two phases the time appears twice in rv_t and odeResults: the
%   end of one phase, then the start of the next (see get_point).
%
% <@Examples>
% ```matlab
% net = network.IEEE14bus();
% net.initialize();
% sc = net.add_scenario("fault");
% sc.add_fault("B008", [1, 1.05]);
% [result, flag] = net.simulate("fault");
% r = result.odeResults;               % r.t, r.Bus(i).V, r.Bus(i).Component(j).X, ...
% x = result.get_point(2);             % all variables at t = 2, in variable-map order
% result.plot_trajectory(Quantity="omega");       % a state of the components
% result.export("sim.mat");
% verdict = result.judge_out_of_step();   % "stable" / "out-of-step" / "incomplete"
% ```
%
% See also SolverODE, Scenario, ResultBase, PowerNetwork.get_variable_map

    properties (SetAccess=private) % Result
        rv_t (:,1) double = zeros(0,1)      % [s] Output times, ascending; a phase boundary appears twice (end of one phase, start of the next).
        tab_variable table = table()        % Variable map at the time of the simulation: its rows are the columns of rm_variable. <@Type> table ((n_x + n_v + n_u) x 7)
        rm_variable double = zeros(0,0)     % Trajectory of all variables: row k at rv_t(k), column m the variable tab_variable(m,:). <@Type> double (n_t x (n_x + n_v + n_u))
        rm_I double = zeros(0,0)            % [pu] Currents injected into the buses: Ireal, Iimag of each bus in the order of sv_bus. <@Type> double (n_t x 2 n_bus)
        tab_output table = table()          % Outputs y and yc of the variable map: its rows are the columns of rm_output; columns as tab_variable. <@Type> table (n_out x 7)
        rm_output double = zeros(0,0)       % Trajectory of the outputs: row k at rv_t(k), column m the output tab_output(m,:); NaN while the unit is tripped. <@Type> double (n_t x n_out)
        sv_bus (:,1) string = strings(0,1)  % Bus tags, in the order of odeResults.Bus.
        c_component (:,1) cell = cell(0,1)  % Component tags of each bus, in the order of odeResults.Bus(i).Component.
        sct_network struct = struct()       % Snapshot of the network at the simulation: struct(net, false).
    end

    properties (Dependent) % Result
        odeResults                          % Trajectories per bus and component: a view of rv_t, rm_variable, rm_I and rm_output (see the class help). <@Type> struct (1x1)
    end

    properties (Access=private, Hidden) % Internal state
        c_index (:,1) cell = cell(0,1)      % Columns for odeResults: c_index{i}.iv_V, .c_x{j}, .c_u{j} (rm_variable) and .c_y{j} (rm_output) of component j of bus i. <@Type> cell of struct (n_bus x 1)
        sct_view struct = struct([])        % odeResults, built on first access. <@Type> struct (0x0 or 1x1)
    end

    methods
        function obj = ResultODE(sct_sol, sct_dae, sct_network, sct_solver)
        % Create a time simulation result from data.
        %
        % Takes the variables x, Vre, Vim, u (the leading rows of the variable map) from
        % the trajectories of the solver and computes the outputs y, yc with the output
        % functions of the blocks; no network object is read.
            arguments (Input)
                sct_sol      struct = struct() % Solver data: rv_t, rm_variable (variable rows of sct_dae.tab_variable: x, Vre, Vim, u, uc), rm_I, rv_phase (phase of each time).
                sct_dae      struct = struct() % Data of the run: tab_variable (the variable map) and the blocks c_comp, c_lc, c_gc (iv_x, iv_u, iv_y, i_bus, f_Y, s_tag), to recompute the outputs.
                sct_network  struct = struct() % Snapshot of the network: struct(net, false).
                sct_solver   struct = struct() % Solver information: solver, options, flag, output, elapsed (s or a tic value).
            end
            arguments (Output)
                obj % The result object.
            end
            sct_default = struct("solver", "SolverODE", "options", struct(), "flag", false, ...
                "output", struct(), "elapsed", NaN);
            for s_name = string(fieldnames(sct_default)).'
                if ~isfield(sct_solver, s_name)
                    sct_solver.(s_name) = sct_default.(s_name);      % missing field: its default
                end
            end
            obj@ResultBase([], sct_solver.solver, sct_solver.options, sct_solver.flag, sct_solver.output, sct_solver.elapsed);
            if isfield(sct_network, "s_tag")
                obj.s_network = string(sct_network.s_tag);
            end
            obj.sct_network = sct_network;
            if ~isfield(sct_dae, "tab_variable") || ~isfield(sct_network, "a_Bus")
                return
            end

            a_bus = reshape(sct_network.a_Bus, [], 1);
            obj.sv_bus      = string(cellfun(@(b) b.s_tag, a_bus, 'UniformOutput', false));
            obj.c_component = cellfun(@(b) string(cellfun(@(c) c.s_tag, reshape(b.a_Component, [], 1), 'UniformOutput', false)), ...
                                      a_bus, 'UniformOutput', false);
            for i = 1:numel(a_bus)              % a bus without components
                obj.c_component{i} = reshape(string(obj.c_component{i}), [], 1);
            end

            tab   = sct_dae.tab_variable;
            lv_xu = ismember(tab.Kind, ["x","Vre","Vim","u"]);     % the variables of the linearization
            lv_y  = ismember(tab.Kind, ["y","yc"]);
            obj.tab_variable = tab(lv_xu, :);
            obj.tab_output   = tab(lv_y, :);

            n_var = nnz(tab.Role == "variable");                  % the variables are the leading rows
            obj.rv_t        = sct_sol.rv_t;
            obj.rm_variable = sct_sol.rm_variable(:, lv_xu(1:n_var));
            obj.rm_I        = sct_sol.rm_I;
            obj.rm_output   = output_trajectory(sct_sol, sct_dae);
            obj.c_index     = simulator_columns(obj.tab_variable, obj.tab_output, obj.sv_bus, obj.c_component);
        end

        function s = get.odeResults(obj)
            if isempty(obj.sct_view)
                obj.sct_view = obj.build_view();
            end
            s = obj.sct_view;
        end

        rv = get_point(obj, t, tab_map, opt)
        ax = plot_trajectory(obj, opt)
        s_file = export(obj, filename)
        verdict = judge_out_of_step(obj, opt)
    end

    methods (Access=private)
        iv = columns_of(obj, tab_map)
        s = build_view(obj)
    end
end
