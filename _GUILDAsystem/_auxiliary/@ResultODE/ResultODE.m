classdef ResultODE < ResultBase
% Result of net.simulate.
%
% Holds the time response of the bus voltages, currents and powers, of the states and
% inputs of the components and controllers, and of their outputs. It is built from data
% only: the trajectories of the solver, the variable map and the output functions of the
% run, a struct snapshot of the network (sct_network = struct(net, false)) and the solver
% information. It keeps no reference to the network: its methods (get_trajectory, plot_trajectory,
% get_point, export, judge_out_of_step, odeResults) work after the network is edited or
% deleted.
% flag is 1 when the simulation reached the end time, 2 when it stopped by StopOnOutOfStep
% (output.outOfStep holds the stop), 0 when it stopped by TimeLimit and -1 when the solver
% stopped early; then the trajectories end at output.tEnd. When the first phase could not
% be solved, they have no time points.
%
% The trajectory is stored once, in the order of the variable map of the network
% (rm_variable, columns = rows of tab_variable): the states of the components with their
% local controllers, the states of the global controllers, the bus voltages, the inputs
% of the components and the inputs of the controllers. odeResults is a view of it per bus and component, and get_point gives
% the values at a time, for example for net.get_sys({sim, t}). get_trajectory returns a
% trajectory of the buses or components as a table (one column per bus or component, also
% relative to the center of inertia) and plot_trajectory draws it, plot_spring_model an animated spring-mass
% picture of the phasors and plot_diagram a 3D network diagram of every output time.
% plot_pqv draws the path of each bus in (P, Q, |V|) as a 3D line over the output times.
% export writes all trajectories as a table (CSV, Excel) or as a MAT-file.
% judge_out_of_step judges the rotor angles (stable, out of step).
%
% - `tab_variable` has one row per variable with Index, Kind ("x" | "Vre" | "Vim" | "u" |
%   "uc"), Role, Owner, Name, Label, Bus and Equilibrium: the leading rows of
%   net.get_variable_map() (its rows y and yc, the signals, are in tab_output).
% - In `rm_variable` the states and inputs of a tripped unit are NaN while it is tripped
%   (u of a component, uc of a local controller, u of a global controller). The inputs u
%   are the inputs applied to the components (steady value, outputs of the controllers and
%   event inputs), the inputs uc those applied to the controllers.
% - `rm_I` holds the columns B1 Ireal, B1 Iimag, B2 Ireal, ... They are not variables of the
%   map; odeResults.Bus(i).I and .PQ are made from them.
% - `rm_Icomponent` holds the current each component injects into its bus (its f_I at each
%   time, positive into the bus): Ireal, Iimag of each component in the order of sv_bus and
%   c_component. It is NaN while the component is tripped. At each time the currents of
%   the components of a bus add up to its rm_I (Y V) within the tolerance of the solver
%   (the residual of the current balance), except at a faulted bus during the fault: rm_I
%   there also holds the fault current.
% - `tab_output` has the rows y (outputs of the components) and yc (outputs of the
%   controllers) of the variable map, with the columns of tab_variable. `rm_output` holds
%   their trajectories, computed by the constructor from the output functions of the
%   blocks at each time (t from the start of the phase, as the solver). The outputs of a
%   tripped unit (its states are NaN) are NaN.
% - `odeResults` has the fields t (time [s], column), Bus(i).V (table Vreal, Vimag),
%   Bus(i).I (Ireal, Iimag), Bus(i).PQ (P, Q), Bus(i).Component(j).X (states, columns named
%   by sv_x), Bus(i).Component(j).U (inputs, columns named by sv_u),
%   Bus(i).Component(j).Y (outputs, columns named by sv_y) and Bus(i).Component(j).I (the
%   current of the component: Ireal, Iimag of rm_Icomponent). Bus(i) follows net.a_Bus and
%   Component(j) follows a_Component of the bus. The states and outputs of the local and
%   global controllers are in rm_variable and rm_output only.
% - `sct_branchY` holds the admittance matrix of each branch at each time of rv_t, in the
%   branch states of the phase (opened circuits, a fault inside the branch): iv_Y picks
%   the set of matrices c_Ybranch of each time. plot_diagram computes the branch flows
%   from it, so an opened branch carries no current ("6open") or the current of the
%   circuits left ("3open"), and a faulted branch the currents of its two ends into the
%   fault.
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
% tab = result.get_trajectory("omega");          % t and one column per generator
% result.plot_trajectory(Quantity="omega");       % the same columns as a figure
% result.export("sim.mat");
% verdict = result.judge_out_of_step();   % "stable" / "out-of-step" / "incomplete"
% ```
%
% See also SolverODE, Scenario, ResultBase, PowerNetwork.get_variable_map

    properties (SetAccess=private) % Result
        rv_t (:,1) double = zeros(0,1)      % [s] Output times, ascending; a phase boundary appears twice (end of one phase, start of the next).
        tab_variable table = table()        % Variable map at the time of the simulation: its rows are the columns of rm_variable. <@Type> table ((n_x + n_v + n_u + n_uc) x 8)
        rm_variable double = zeros(0,0)     % Trajectory of all variables: row k at rv_t(k), column m the variable tab_variable(m,:). <@Type> double (n_t x (n_x + n_v + n_u + n_uc))
        rm_I double = zeros(0,0)            % [pu] Currents injected into the buses: Ireal, Iimag of each bus in the order of sv_bus. <@Type> double (n_t x 2 n_bus)
        rm_Icomponent double = zeros(0,0)   % [pu] Current each component injects into its bus (its f_I): Ireal, Iimag of each component in the order of sv_bus and c_component; NaN while it is tripped. <@Type> double (n_t x 2 n_component)
        tab_output table = table()          % Outputs y and yc of the variable map: its rows are the columns of rm_output; columns as tab_variable. <@Type> table (n_out x 8)
        rm_output double = zeros(0,0)       % Trajectory of the outputs: row k at rv_t(k), column m the output tab_output(m,:); NaN while the unit is tripped. <@Type> double (n_t x n_out)
        sv_bus (:,1) string = strings(0,1)  % Bus tags, in the order of odeResults.Bus.
        c_component (:,1) cell = cell(0,1)  % Component tags of each bus, in the order of odeResults.Bus(i).Component.
        sct_network struct = struct()       % Snapshot of the network at the simulation: struct(net, false).
        sct_branchY struct = struct("iv_Y", zeros(0,1), "c_Ybranch", {cell(0,1)})  % [pu] Branch admittances the run used: iv_Y (n_t x 1) is the position in c_Ybranch at each time of rv_t, c_Ybranch{k} the 2x2 matrix of each branch of sct_network.a_Branch in the k-th set of branch states (2 x 2 x n_branch; k = 1: all closed).
    end

    properties (Dependent) % Result
        odeResults                          % Trajectories per bus and component: a view of rv_t, rm_variable, rm_I, rm_Icomponent and rm_output (see the class help). <@Type> struct (1x1)
    end

    properties (Access=private, Hidden) % Internal state
        c_index (:,1) cell = cell(0,1)      % Columns for odeResults: c_index{i}.iv_V, .c_x{j}, .c_u{j} (rm_variable) and .c_y{j} (rm_output) of component j of bus i. <@Type> cell of struct (n_bus x 1)
        sct_view struct = struct([])        % odeResults, built on first access. <@Type> struct (0x0 or 1x1)
    end

    methods
        function obj = ResultODE(sct_sol, sct_dae, sct_network, sct_solver)
        % Create a time simulation result from data.
        %
        % Takes the variables x, Vre, Vim, u, uc (the leading rows of the variable map) from
        % the trajectories of the solver and computes the outputs y, yc with the output
        % functions of the blocks; no network object is read.
            arguments (Input)
                sct_sol      struct = struct()  % Solver data: rv_t, rm_variable (variable rows of sct_dae.tab_variable: x, Vre, Vim, u, uc), rm_I, rm_Icomponent (NaN when missing), rv_phase (phase of each time), iv_Y (set of branch admittances of each time).
                sct_dae      struct = struct()  % Data of the run: tab_variable (the variable map), the blocks c_comp, c_lc, c_gc (iv_x, iv_u, iv_y, i_bus, f_Y, s_tag), to recompute the outputs, and c_Ybranch (branch admittances of each set of branch states).
                sct_network  struct = struct()  % Snapshot of the network: struct(net, false).
                sct_solver   struct = struct()  % Solver information: solver, options, flag, output, elapsed (s or a tic value).
            end
            arguments (Output)
                obj  % The result object.
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
            lv_xu = ismember(tab.Kind, ["x","Vre","Vim","u","uc"]);   % the variables (of the linearization)
            lv_y  = ismember(tab.Kind, ["y","yc"]);
            obj.tab_variable = tab(lv_xu, :);
            obj.tab_output   = tab(lv_y, :);

            n_var = nnz(tab.Role == "variable");                  % the variables are the leading rows
            obj.rv_t        = sct_sol.rv_t;
            obj.rm_variable = sct_sol.rm_variable(:, lv_xu(1:n_var));
            obj.rm_I        = sct_sol.rm_I;
            if isfield(sct_sol, "rm_Icomponent")
                obj.rm_Icomponent = sct_sol.rm_Icomponent;
            else
                obj.rm_Icomponent = NaN(numel(obj.rv_t), 2*numel(vertcat(obj.c_component{:})));
            end
            if isfield(sct_sol, "iv_Y") && isfield(sct_dae, "c_Ybranch")
                obj.sct_branchY = struct("iv_Y", sct_sol.iv_Y, "c_Ybranch", {sct_dae.c_Ybranch});
            end
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
        tab = get_trajectory(obj, Quantity, opt)
        G = plot_trajectory(obj, opt)
        G = plot_pqv(obj, opt)
        [G, G_chart] = plot_spring_model(obj, opt)
        [G, G_chart] = plot_diagram(obj, opt)
        s_file = export(obj, filename)
        verdict = judge_out_of_step(obj, opt)
    end

    methods (Access=private)
        iv = columns_of(obj, tab_map)
        s = build_view(obj)
    end
end
