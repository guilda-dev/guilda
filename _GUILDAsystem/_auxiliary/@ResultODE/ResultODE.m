classdef ResultODE < ResultBase
% Result of net.simulate.
%
% Holds the time response of the bus voltages, currents and powers and of the states and
% inputs of the components and controllers. It holds computed values only; the settings of
% the buses and components stay with the network (a hidden reference, see ResultBase).
% flag is 1 when the simulation reached the end time, 0 when it stopped by TimeLimit and -1
% when the solver stopped early; then the trajectories end at output.tEnd. When the first
% phase could not be solved, they have no time points.
%
% The trajectory is stored once, in the order of the variable map of the network
% (rm_variable, columns = rows of tab_variable): the states of the components with their
% local controllers, the states of the global controllers, the bus voltages and the inputs
% of the components. odeResults is a view of it per bus and component, and get_point gives
% the values at a time, for example for net.linearize(Point={sim, t}). Plot draws a
% trajectory of the buses or components. export writes all trajectories as a table (CSV,
% Excel) or as a MAT-file.
%
% - `tab_variable` has one row per variable with Index, Kind ("x" | "Vre" | "Vim" | "u"),
%   Role, Owner, Name, Label and Bus: the leading rows of net.get_variable_map() (its
%   rows uc, y and yc, the controller inputs and the signals, are not variables here).
% - In `rm_variable` the states of a tripped unit are NaN while it is tripped. The inputs u
%   are the inputs applied to the components (steady value, outputs of the controllers and
%   event inputs).
% - `rm_I` holds the columns B1 Ireal, B1 Iimag, B2 Ireal, ... They are not variables of the
%   map; odeResults.Bus(i).I and .PQ are made from them.
% - `odeResults` has the fields t (time [s], column), Bus(i).V (table Vreal, Vimag),
%   Bus(i).I (Ireal, Iimag), Bus(i).PQ (P, Q), Bus(i).Component(j).X (states, columns named
%   by sv_x) and Bus(i).Component(j).U (inputs, columns named by sv_u). Bus(i) follows
%   net.a_Bus and Component(j) follows a_Component of the bus. The states of the local and
%   global controllers are in rm_variable only.
% - At a boundary between two phases the time appears twice in rv_t and odeResults: the
%   end of one phase, then the start of the next (see get_point).
%
% <@Examples>
% ```matlab
% net = network.IEEE14bus();
% net.initialize();
% sc = Scenario("fault");
% sc.add_fault("B008", [1, 1.05]);
% net.add_scenario(sc);
% [result, flag] = net.simulate([0, 10], sc);
% r = result.odeResults;               % r.t, r.Bus(i).V, r.Bus(i).Component(j).X, ...
% x = result.get_point(2);             % all variables at t = 2, in variable-map order
% result.Plot(Quantity="omega");       % a state of the components
% result.export("sim.mat");
% ```
%
% See also SolverODE, Scenario, ResultBase, PowerNetwork.get_variable_map

    properties (SetAccess=private) % Result
        rv_t (:,1) double = zeros(0,1)      % [s] Output times, ascending; a phase boundary appears twice (end of one phase, start of the next).
        tab_variable table = table()        % Variable map at the time of the simulation: its rows are the columns of rm_variable. <@Type> table ((n_x + n_v + n_u) x 7)
        rm_variable double = zeros(0,0)     % Trajectory of all variables: row k at rv_t(k), column m the variable tab_variable(m,:). <@Type> double (n_t x (n_x + n_v + n_u))
        rm_I double = zeros(0,0)            % [pu] Currents injected into the buses: Ireal, Iimag of each bus in the order of sv_bus. <@Type> double (n_t x 2 n_bus)
        sv_bus (:,1) string = strings(0,1)  % Bus tags, in the order of odeResults.Bus.
        c_component (:,1) cell = cell(0,1)  % Component tags of each bus, in the order of odeResults.Bus(i).Component.
    end

    properties (Dependent) % Result
        odeResults                          % Trajectories per bus and component: a view of rv_t, rm_variable and rm_I (see the class help). <@Type> struct (1x1)
    end

    properties (Access=private, Hidden) % Internal state
        c_index (:,1) cell = cell(0,1)      % Columns of rm_variable for odeResults: c_index{i}.iv_V, .c_x{j} and .c_u{j} of component j of bus i. <@Type> cell of struct (n_bus x 1)
        sct_view struct = struct([])        % odeResults, built on first access. <@Type> struct (0x0 or 1x1)
    end

    methods
        function obj = ResultODE(net, solver, options, flag, output, elapsed, c_phase)
        % Create a time simulation result.
        %
        % Collects the trajectories of the integration phases: the variables x, Vre, Vim, u
        % of net.get_variable_map() (its leading rows; SolverODE.phase_result takes them
        % from the DAE vector) and the bus currents. Created by SolverODE.solve.
            arguments (Input)
                net             = [] % Analysed network; see ResultBase.
                solver          = "SolverODE" % Solver object or its class name; see ResultBase.
                options  struct = struct() % Effective settings; see ResultBase.
                flag            = false % Success or convergence flag; see ResultBase.
                output   struct = struct() % Solver details; see ResultBase.
                elapsed         = NaN % [s] Elapsed time or tic value; see ResultBase.
                c_phase  cell   = {} % Result of each phase (SolverODE.phase_result: t, x, i).
            end
            arguments (Output)
                obj % The result object.
            end
            obj@ResultBase(net, solver, options, flag, output, elapsed);
            if isempty(net)
                return
            end

            a_bus = net.a_Bus;
            obj.sv_bus      = string(a_bus(:));
            obj.c_component = cellfun(@(b) string(b.a_Component(:)), a_bus(:), 'UniformOutput', false);

            tab = net.get_variable_map();
            obj.tab_variable = tab(ismember(tab.Kind, ["x","Vre","Vim","u"]), :);   % the variables of the linearization
            obj.c_index = simulator_columns(net, obj.tab_variable);
            if isempty(c_phase)
                obj.rv_t = zeros(0,1);
                obj.rm_I = zeros(0, 2*numel(a_bus));
                obj.rm_variable = zeros(0, height(obj.tab_variable));
                return
            end

            sol = reshape(c_phase, [], 1);
            obj.rv_t = cell2mat( cellfun(@(T) T.t, sol, 'UniformOutput', false) );
            X        = cell2mat( cellfun(@(T) T.x, sol, 'UniformOutput', false) );
            obj.rm_I = cell2mat( cellfun(@(T) T.i, sol, 'UniformOutput', false) );
            obj.rm_variable = X;
        end

        function s = get.odeResults(obj)
            if isempty(obj.sct_view)
                obj.sct_view = obj.build_view();
            end
            s = obj.sct_view;
        end

        rv = get_point(obj, t, tab_map, opt)
        ax = Plot(obj, opt)
        s_file = export(obj, filename)
    end

    methods (Access=private)
        iv = columns_of(obj, tab_map)
        s = build_view(obj)
    end
end
