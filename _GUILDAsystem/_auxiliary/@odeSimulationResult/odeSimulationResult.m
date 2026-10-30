classdef odeSimulationResult < AnalysisResult
% Result of net.simulate.
%
% Holds the time response of the bus voltages, currents and powers and of the states and
% inputs of the components and controllers. It holds computed values only; the settings of
% the buses and components stay with the network (a hidden reference, see AnalysisResult).
% flag is 1 when the simulation reached the end time, 0 when it stopped by TimeLimit and -1
% when the solver stopped early; then the trajectories end at output.tEnd.
%
% The trajectory is stored once, in the order of the variable map of the network
% (rm_variable, columns = rows of tab_variable): the states of the components with their
% local controllers, the states of the global controllers, the bus voltages and the inputs
% of the components. odeResults is a view of it per bus and component, and get_point gives
% the values at a time, for example for net.linearize(Point={sim, t}). Plot draws a
% trajectory of the buses or components. Export writes all trajectories as a table (CSV,
% Excel) or as a MAT-file.
%
% <@Examples>
% ```matlab
% net = network.IEEE14bus();
% net.initialize();
% ev = odeEventSet("fault", net, "TimeSpan", [1, 1.05], "FaultBus", "B008");
% [result, flag] = net.simulate([0, 10], ev);
% r = result.odeResults;               % r.t, r.Bus(i).V, r.Bus(i).Component(j).X, ...
% x = result.get_point(2);             % all variables at t = 2, in variable-map order
% result.Plot(Quantity="omega");       % a state of the components
% result.Export("sim.mat");
% ```
%
% See also odeSimulator, odeEventSet, AnalysisResult, PowerNetwork.get_variable_map

    properties (SetAccess=private) % Result
        % [s] Output times, ascending.
        % At a boundary between two phases the time appears twice: the end of one phase, then
        % the start of the next (see get_point).
        rv_t (:,1) double = zeros(0,1)

        % Variable map at the time of the simulation (see PowerNetwork.get_variable_map).
        % One row per variable with Index, Kind ("x" | "Vre" | "Vim" | "u"), Owner, Name, Label,
        % Bus. Its rows are the columns of rm_variable.
        % <@Type> table ((n_x + n_v + n_u) x 6)
        tab_variable table = table()

        % Trajectory of all variables, one row per output time.
        % Row k holds the values at rv_t(k), column m the variable tab_variable(m,:). The states
        % of a tripped unit are NaN while it is tripped. The inputs u are the inputs applied to
        % the components (steady value, outputs of the controllers and event inputs).
        % <@Type> double (n_t x (n_x + n_v + n_u))
        rm_variable double = zeros(0,0)

        % [pu] Currents injected into the buses.
        % Columns Ireal, Iimag of each bus in the order of sv_bus (B1 Ireal, B1 Iimag, B2 Ireal,
        % ...). They are not variables of the map; odeResults.Bus(i).I and .PQ are made from them.
        % <@Type> double (n_t x 2 n_bus)
        rm_I double = zeros(0,0)

        % Bus tags, in the order of odeResults.Bus.
        sv_bus (:,1) string = strings(0,1)

        % Component tags of each bus, in the order of odeResults.Bus(i).Component.
        c_component (:,1) cell = cell(0,1)
    end

    properties (Dependent) % Result
        % Trajectories per bus and component, as a struct (a view of rv_t, rm_variable and rm_I).
        % Fields: t (time [s], column), Bus(i).V (table Vreal, Vimag), Bus(i).I (Ireal, Iimag),
        % Bus(i).PQ (P, Q), Bus(i).Component(j).X (states, columns named by sv_x) and
        % Bus(i).Component(j).U (inputs, columns named by sv_u). Bus(i) follows net.a_Bus and
        % Component(j) follows a_Component of the bus. The states of the local and global
        % controllers are in rm_variable only. At a boundary between two phases the time appears
        % twice (end of one phase, start of the next).
        % <@Type> struct (1x1)
        odeResults
    end

    properties (Access=private, Hidden) % Internal state
        % Columns of rm_variable for the view odeResults.
        % c_index{i}.iv_V (2 x 1) and c_index{i}.c_x{j}, c_index{i}.c_u{j} for component j of
        % bus i.
        % <@Type> cell of struct (n_bus x 1)
        c_index (:,1) cell = cell(0,1)

        % odeResults, built on first access.
        % <@Type> struct (0x0 or 1x1)
        s_view struct = struct([])
    end

    methods
        function obj = odeSimulationResult(net, solver, options, flag, output, elapsed, c_phase)
        % Create a time simulation result.
        %
        % Collects the trajectories of the integration phases and reorders the state of the
        % simulator (odeSimulator order: each component with its inputs and local controllers,
        % the global controllers, then the voltage and current of each bus) into the order of
        % net.get_variable_map(). Created by odeSimulator.solve.
            arguments
                net             = [] % Analysed network; see AnalysisResult.
                solver          = "odeSimulator" % Solver object or its class name; see AnalysisResult.
                options  struct = struct() % Effective settings; see AnalysisResult.
                flag            = false % Success or convergence flag; see AnalysisResult.
                output   struct = struct() % Solver details; see AnalysisResult.
                elapsed         = NaN % [s] Elapsed time or tic value; see AnalysisResult.
                c_phase  cell   = {} % Result of each phase (odeEventSet.Event2State: t, x, i).
            end
            arguments (Output)
                obj % The result object.
            end
            obj@AnalysisResult(net, solver, options, flag, output, elapsed);
            if isempty(net) || isempty(c_phase)
                return
            end

            a_bus = net.a_Bus;
            obj.sv_bus      = string(a_bus(:));
            obj.c_component = cellfun(@(b) string(b.a_Component(:)), a_bus(:), 'UniformOutput', false);

            sol = reshape(c_phase, [], 1);
            obj.rv_t = cell2mat( cellfun(@(T) T.t{:,:}, sol, 'UniformOutput', false) );
            X        = cell2mat( cellfun(@(T) T.x{:,:}, sol, 'UniformOutput', false) );
            obj.rm_I = cell2mat( cellfun(@(T) T.i{:,:}, sol, 'UniformOutput', false) );

            obj.tab_variable = net.get_variable_map();
            [iv_sim, obj.c_index] = simulator_columns(net, obj.tab_variable);
            obj.rm_variable = X(:, iv_sim);
        end

        function s = get.odeResults(obj)
            if isempty(obj.s_view)
                obj.s_view = obj.build_view();
            end
            s = obj.s_view;
        end

        function rv = get_point(obj, t, tab_map, opt)
        % Get the values of the variable map at a time of the simulation.
        %
        % Returns the values of the variables at time t, in the order of the rows of tab_map
        % (by default the whole variable map tab_variable, so rv is a point for
        % net.linearize(Point=rv)). tab_map may be the variable map of a bus or component of
        % the simulated network (bus.get_variable_map(), comp.get_variable_map()); its rows are
        % found by Kind, Owner, Name and Bus.
        %
        % Between two output times the values are interpolated linearly. At a phase boundary,
        % where the time appears twice in rv_t, Side chooses the value: "after" (default) the
        % start of the later phase, i.e. the state after the event (an offset applied, a fault
        % cleared), "before" the end of the earlier phase. At any other output time Side has no
        % effect.
        %
        % <@Examples>
        % ```matlab
        % sim = net.simulate([0,5], odeEventSet("fault", net, "TimeSpan", [1,1.05], "FaultBus", "B008"));
        % x  = sim.get_point(2);                    % order of net.get_variable_map()
        % x0 = sim.get_point(1.05, Side="before");  % end of the fault
        % res = net.linearize(Point={sim, 2});      % same point as Point=x
        % ```
        %
        % See also PowerNetwork.get_variable_map, odeLinearizer
            arguments
                obj
                t        (1,1) double {mustBeReal} % [s] Time within [rv_t(1), rv_t(end)].
                tab_map  table = obj.tab_variable % Rows to return (a variable map or a part of it).
                opt.Side (1,1) string {mustBeMember(opt.Side, ["after","before"])} = "after" % Value at a phase boundary: after or before the event.
            end
            arguments (Output)
                rv % Values in the order of the rows of tab_map (column).
            end
            iv_col = obj.columns_of(tab_map);

            tv = obj.rv_t;
            if isempty(tv) || ~(t >= tv(1) && t <= tv(end))
                if isempty(tv)
                    tv = NaN;
                end
                error("GUILDA:odeSimulationResult:PointTime", ...
                      "t = %g is outside the simulated time [%g, %g].", t, tv(1), tv(end))
            end
            k = find(tv == t);
            if ~isempty(k)
                if opt.Side == "after"
                    k = k(end);
                else
                    k = k(1);
                end
                rv = obj.rm_variable(k, iv_col).';
                return
            end
            k = find(tv < t, 1, "last");
            w = (t - tv(k)) / (tv(k+1) - tv(k));
            rv = ((1-w) * obj.rm_variable(k, iv_col) + w * obj.rm_variable(k+1, iv_col)).';
        end

        ax = Plot(obj, opt)
        str_file = Export(obj, filename)
    end

    methods (Access=private)
        function iv = columns_of(obj, tab_map)
        % Columns of rm_variable for the rows of tab_map (matched by Kind, Owner, Name, Bus)
            str_key = @(T) string(T.Kind) + "|" + string(T.Owner) + "|" + string(T.Name) + "|" + string(T.Bus);
            if height(tab_map) == 0
                iv = zeros(0,1);
                return
            end
            if ~all(ismember(["Kind","Owner","Name","Bus"], string(tab_map.Properties.VariableNames)))
                error("GUILDA:odeSimulationResult:UnknownVariable", ...
                      "tab_map must be a variable map (columns Kind, Owner, Name, Bus), see get_variable_map.")
            end
            [lv, iv] = ismember(str_key(tab_map), str_key(obj.tab_variable));
            if ~all(lv)
                sv_label = string(tab_map.Label(~lv));
                error("GUILDA:odeSimulationResult:UnknownVariable", ...
                      "The simulation result has no values for %s. " + ...
                      "Give rows of result.tab_variable (the network as it was simulated).", ...
                      join(sv_label(1:min(end,5)), ", "))
            end
        end

        function s = build_view(obj)
        % odeResults from rv_t, rm_variable and rm_I (same layout as before the
        % trajectory was stored in variable-map order)
            s = struct();
            if isempty(obj.c_index)
                return
            end
            X = array2table(obj.rm_variable);
            I = array2table(obj.rm_I);
            Vmap = obj.tab_variable.Name;

            s.t = obj.rv_t;
            for i = 1:numel(obj.c_index)
                idx = obj.c_index{i};

                s.Bus(i).Component = struct();
                for j = 1:numel(idx.c_x)
                    sol_c_idx = X(:, idx.c_x{j});
                    sol_c_idx.Properties.VariableNames = Vmap(idx.c_x{j});
                    s.Bus(i).Component(j).X = sol_c_idx;

                    sol_c_idx = X(:, idx.c_u{j});
                    sol_c_idx.Properties.VariableNames = Vmap(idx.c_u{j});
                    s.Bus(i).Component(j).U = sol_c_idx;
                end

                sol_V_idx = X{:, idx.iv_V};
                sol_I_idx = I{:, [2*i-1,2*i]};
                sol_P_idx = array2table( sol_V_idx(:,1) .* sol_I_idx(:,1) + sol_V_idx(:,2) .* sol_I_idx(:,2) );
                sol_Q_idx = array2table( sol_V_idx(:,2) .* sol_I_idx(:,1) - sol_V_idx(:,1) .* sol_I_idx(:,2) );

                sol_V_idx = X(:, idx.iv_V);
                sol_I_idx = I(:, [2*i-1,2*i]);

                sol_V_idx.Properties.VariableNames = ["Vreal","Vimag"];
                sol_I_idx.Properties.VariableNames = ["Ireal","Iimag"];
                sol_P_idx.Properties.VariableNames = "P";
                sol_Q_idx.Properties.VariableNames = "Q";

                s.Bus(i).V  = sol_V_idx;
                s.Bus(i).I  = sol_I_idx;
                s.Bus(i).PQ = [sol_P_idx,sol_Q_idx];
            end
        end
    end

end


function [iv_sim, c_index] = simulator_columns(net, tab)
% iv_sim(m): column of the simulator state (iv_odeX / iv_odeU set by
% odeSimulator.initialize_index) that holds the variable tab(m,:). Walks the network in
% the order of get_variable_map and checks the result against the labels of tab.
% c_index{i}: columns of tab for the view odeResults (bus i).
    a_bus = net.a_Bus;
    a_gc  = net.a_GlobalController;
    n_bus = numel(a_bus);

    c_x = cell(0,1);  c_lx = cell(0,1);     % states: simulator indices and labels
    c_u = cell(0,1);  c_lu = cell(0,1);     % inputs
    c_comp = cell(n_bus,1);                 % per bus, per component: [n_x, n_u] of the component
    for i = 1:n_bus
        a_comp = a_bus{i}.a_Component;
        c_comp{i} = zeros(numel(a_comp), 2);
        for j = 1:numel(a_comp)
            comp  = a_comp{j};
            a_obj = [{comp}; all_controllers(comp)];
            for k = 1:numel(a_obj)
                c_x{end+1,1}  = reshape(a_obj{k}.iv_odeX, [], 1); %#ok<AGROW>
                c_lx{end+1,1} = label(a_obj{k}, a_obj{k}.sv_x);   %#ok<AGROW>
            end
            c_u{end+1,1}  = reshape(comp.iv_odeU, [], 1); %#ok<AGROW>
            c_lu{end+1,1} = label(comp, comp.sv_u);       %#ok<AGROW>
            c_comp{i}(j,:) = [numel(comp.sv_x), numel(comp.sv_u)];
        end
    end
    c_gx = tools.cellfun(@(g) reshape(g.iv_odeX, [], 1), a_gc);
    c_gl = tools.cellfun(@(g) label(g, g.sv_x), a_gc);
    c_V  = tools.cellfun(@(b) reshape(b.iv_odeX, [], 1), a_bus);
    c_lV = tools.cellfun(@(b) label(b, ["Vre";"Vim"]), a_bus);

    iv_sim   = vertcat(zeros(0,1), c_x{:}, c_gx{:}, c_V{:}, c_u{:});
    sv_label = vertcat(strings(0,1), c_lx{:}, c_gl{:}, c_lV{:}, c_lu{:});
    if numel(iv_sim) ~= height(tab) || ~isequal(sv_label, string(tab.Label))
        error("GUILDA:odeSimulationResult:VariableMap", ...
              "The state of the simulator does not match net.get_variable_map(); report this as a bug.")
    end

    % columns of the view: the component's own states (not its controllers) and inputs
    [~, c_idxBus] = net.get_variable_map();
    c_index = cell(n_bus,1);
    iv_u0 = find(tab.Kind == "u", 1) - 1;
    if isempty(iv_u0)
        iv_u0 = height(tab);
    end
    n_u = 0;
    for i = 1:n_bus
        a_comp = a_bus{i}.a_Component;
        iv_bus = c_idxBus{i};
        iv_bx  = iv_bus(tab.Kind(iv_bus) == "x");
        s = struct();
        s.iv_V = iv_bus(tab.Kind(iv_bus) == "Vre" | tab.Kind(iv_bus) == "Vim");
        s.c_x  = cell(1, numel(a_comp));
        s.c_u  = cell(1, numel(a_comp));
        n_x = 0;
        for j = 1:numel(a_comp)
            s.c_x{j} = iv_bx(n_x + (1:c_comp{i}(j,1)));
            s.c_u{j} = iv_u0 + n_u + (1:c_comp{i}(j,2))';
            n_x = n_x + numel(a_comp{j}.sv_x) + sum(cellfun(@(c) numel(c.sv_x), all_controllers(a_comp{j})));
            n_u = n_u + c_comp{i}(j,2);
        end
        c_index{i} = s;
    end
end

function sv = label(owner, sv_name)
% Tagged name, as in the Label column of get_variable_map
    if isempty(sv_name)
        sv = strings(0,1);
    else
        sv = reshape(string(owner.attach_tag(sv_name)), [], 1);
    end
end

function list = all_controllers(parent)
% Local controllers of parent, depth first (the order of get_variable_map)
    list = cell(0,1);
    for k = 1:numel(parent.a_LocalController)
        con  = parent.a_LocalController{k};
        list = [list; {con}; all_controllers(con)]; %#ok<AGROW>
    end
end
