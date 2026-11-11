function [tab, c_idxBus, c_idxGC, tab_connection] = get_variable_map(obj, s_form)
% Return the variable map (every variable and signal of the network) and the connection map.
%
% Variable map of the network: the single definition of the order of the variables and
% signals of the network model, used by net.linearize (ResultLIN blocks and Point), by
% net.simulate (the order of the DAE vector) and by the other analyses. The order is
%   1. x: states. For each bus in a_Bus, for each component in a_Component, the states of
%      the component and then of its local controllers (depth first: the AVR or "local"
%      controller, the PSS attached under the AVR, then the governor, whatever the order
%      of attachment); then the states of each global controller in a_GlobalController
%   2. Vre, Vim: bus voltages of each bus in a_Bus (B1 Vre, B1 Vim, B2 Vre, ...)
%   3. u: inputs sv_u of each component (bus by bus)
%   4. uc: inputs of the controllers: those of the local controllers (bus by bus, component
%      by component, depth first), then those of each global controller, unit by unit
%      (sv_u of unit 1, sv_u of unit 2, ...)
%   5. y: outputs sv_y of each component (bus by bus)
%   6. yc: outputs of the controllers, in the order of 4 (sv_y of each unit for a global
%      controller)
% Rows 1-4 are the variables of the DAE (Role "variable"); rows 5-6 are signals computed
% from them at each evaluation (Role "signal"). The rows of the kinds x, Vre, Vim and u
% come first and are the variables of the linearization (net.linearize, get_sys and their
% Point); the controller inputs uc are eliminated there. The bus current of the simulation
% is not in the map: SolverODE places it after the voltages.
% The map of a bus or a component (bus.get_variable_map, comp.get_variable_map) is the
% restriction of this map to its rows, in the same relative order.
% Columns: Index (row number), Kind ("x" | "Vre" | "Vim" | "u" | "uc" | "y" | "yc"),
% Role ("variable" | "signal"), Owner (tag of the component, controller or bus that owns
% the row), Name (variable or port name, e.g. "delta"), Label (tagged name, equal to the
% StateName / InputName / OutputName used by get_sys; an output with the name of a state of
% its owner is "Y_" + name; a row of a global controller is labelled
% gc.attach_tag(name + "_" + unit tag), as it has one per controlled unit),
% Bus (tag of the bus the owner is attached to; "" for a global controller).
%
% The connection map tab_connection is the only place where it is decided which signal
% drives which input. One row per connection, in the order of the inputs they drive:
%   "local"       the output of a local controller into the input of the same name of its
%                 parent (the component, or the AVR for a PSS)
%   "observe"     an output (before a state of the same name) or a state of a component
%                 into an input of a local controller that observes it, or into an input
%                 of a global controller that controls it
%   "equilibrium" an input without a "local" or "observe" source keeps its equilibrium
%   "global"      an output of a global controller, for each unit: into every local
%                 controller of the unit (nested ones included, depth first) that has an
%                 input of that name, otherwise into the input of that name of the unit
%                 (no row when neither exists: the users of the map report it)
% Columns: Index, Kind, Source and Target (Labels; Source is "" for "equilibrium"),
% SourceIndex and TargetIndex (Index of the rows in tab; 0 for no source). An input is the
% sum of its sources; the inputs of the components also get the input events of a scenario.
% A table is used so that the map prints as is and can be filtered with the usual
% table operations (tab(tab.Kind == "x", :)); the Label column is the key that links it
% to state-space models and results.
% The tables are made once, at the end: the bus and component methods return their rows
% with get_variable_map("rows"), the cell {sm_x; sm_V; sm_u; sm_uc; sm_y; sm_yc} of string
% matrices with the columns Kind, Owner, Name, Label, Bus, and the connections as a string
% matrix (Kind, kind and label of the source, kind and label of the target).
%
% <@Examples>
% ```matlab
% [tab, ~, ~, tab_connection] = net.get_variable_map();
% tab(tab.Kind == "x", ["Owner","Name"])
% tab_connection(tab_connection.Kind == "global", :)
% x0 = net.linearize().rv_point;   % values of the rows x, Vre, Vim, u
% ```
%
% See also PowerNetwork.linearize, PowerNetwork.simulate, Bus.get_variable_map, Component.get_variable_map
%
% <@Group> Called by analyses
    arguments (Input)
        obj
        s_form (1,1) string {mustBeMember(s_form, ["table","rows"])} = "table" % "rows" (internal): return the rows without the tables.
    end
    arguments (Output)
        tab              % One row per variable or signal: Index, Kind, Role, Owner, Name, Label, Bus.
        c_idxBus         % c_idxBus{i}: rows of tab that form a_Bus{i}.get_variable_map(), in its order.
        c_idxGC          % c_idxGC{k}: rows of tab of a_GlobalController{k} (its x, uc, yc).
        tab_connection   % One row per connection: Index, Kind, Source, Target, SourceIndex, TargetIndex.
    end
    a_bus = obj.a_Bus;
    a_gc  = obj.a_GlobalController;
    n_bus = numel(a_bus);
    n_gc  = numel(a_gc);
    n_kind = 6;

    c_bus  = cell(n_bus,1);
    c_conn = cell(n_bus + n_gc,1);
    for i = 1:n_bus
        [c_bus{i}, ~, c_conn{i}] = a_bus{i}.get_variable_map("rows");
    end
    c_gc = cell(n_gc,1);
    for k = 1:n_gc
        [c_gc{k}, c_conn{n_bus+k}] = gc_rows(a_gc{k});
    end

    % The rows of each kind: those of each bus, then of each global controller
    c_rows = cell(n_kind,1);
    nm = zeros(n_bus + n_gc, n_kind);
    for m = 1:n_kind
        c_m = [tools.cellfun(@(r) r{m}, c_bus); tools.cellfun(@(r) r{m}, c_gc)];
        c_rows{m} = vertcat(strings(0,5), c_m{:});
        nm(:,m) = cellfun(@(r) size(r,1), c_m);
    end
    sm_conn = vertcat(strings(0,5), c_conn{:});

    n_all = sum(nm,1)';
    iv_0  = [0; cumsum(n_all(1:end-1))];
    c_idx = cell(n_bus + n_gc,1);
    for p = 1:n_bus + n_gc
        c_p = cell(n_kind,1);
        for m = 1:n_kind
            c_p{m} = iv_0(m) + sum(nm(1:p-1,m)) + (1:nm(p,m))';
        end
        c_idx{p} = vertcat(c_p{:});
    end
    c_idxBus = c_idx(1:n_bus);
    c_idxGC  = c_idx(n_bus+1:end);

    if s_form == "rows"
        tab = c_rows;
        tab_connection = sm_conn;
        return
    end
    [tab, tab_connection] = make_tables(vertcat(c_rows{:}), sm_conn);
end


function [c_rows, sm_conn] = gc_rows(gc)
    % Rows of a global controller (its x; its uc and yc, one set per unit) and its
    % connections: what each input observes, and where each output goes
    s_gc   = string(gc.s_tag);
    sv_x   = reshape(string(gc.sv_x), [], 1);
    sv_u   = reshape(string(gc.sv_u), [], 1);
    sv_y   = reshape(string(gc.sv_y), [], 1);
    a_unit = gc.controlledUnits;
    n_unit = numel(a_unit);
    sm_x   = rows("x", s_gc, sv_x, label(gc, sv_x));
    c_uc   = cell(n_unit,1);
    c_yc   = cell(n_unit,1);
    c_conn = cell(n_unit,1);
    n_u    = numel(sv_u);
    for idx = 1:n_unit
        unit = a_unit{idx};
        s_unit = string(unit.s_tag);
        sv_lu = label(gc, sv_u + "_" + s_unit);
        sv_ly = label(gc, sv_y + "_" + s_unit);
        c_uc{idx} = rows("uc", s_gc, sv_u, sv_lu);
        c_yc{idx} = rows("yc", s_gc, sv_y, sv_ly);

        % Inputs: an output of the unit (before a state of the same name), or a state
        sm = strings(0,5);
        iv_k = (idx-1)*n_u + (1:n_u)';
        for k = 1:n_u
            i_y = gc.iv_obsY(iv_k(k));
            i_x = gc.iv_obsX(iv_k(k));
            if i_y > 0
                sm(end+1,:) = ["observe", "y", label_y(unit, unit.sv_y(i_y)), "uc", sv_lu(k)]; %#ok<AGROW>
            elseif i_x > 0
                sm(end+1,:) = ["observe", "x", label(unit, unit.sv_x(i_x)), "uc", sv_lu(k)]; %#ok<AGROW>
            end
        end

        % Outputs: to every local controller of the unit with an input of that name,
        % otherwise to the input of that name of the unit
        c_LC = all_controllers(unit);
        for m = 1:numel(sv_y)
            lv_LC = cellfun(@(c) any(c.sv_u == sv_y(m)), c_LC);
            if any(lv_LC)
                sv_to = cellfun(@(c) label(c, sv_y(m)), c_LC(lv_LC));
                sm = [sm; repmat(["global", "yc", sv_ly(m), "uc"], numel(sv_to), 1), reshape(sv_to, [], 1)]; %#ok<AGROW>
            elseif any(unit.sv_u == sv_y(m))
                sm(end+1,:) = ["global", "yc", sv_ly(m), "u", label(unit, sv_y(m))]; %#ok<AGROW>
            end
        end
        c_conn{idx} = sm;
    end
    c_rows  = {sm_x; strings(0,5); strings(0,5); vertcat(strings(0,5), c_uc{:}); strings(0,5); vertcat(strings(0,5), c_yc{:})};
    sm_conn = vertcat(strings(0,5), c_conn{:});
end

function [tab, tab_connection] = make_tables(sm, sm_conn)
    % The tables from the rows; the connections point to the rows by Index, in the order
    % of the inputs they drive (stable: the "global" rows after the others)
    n = size(sm,1);
    sv_role = repmat("variable", n, 1);
    sv_role(ismember(sm(:,1), ["y","yc"])) = "signal";
    tab = table((1:n)', sm(:,1), sv_role, sm(:,2), sm(:,3), sm(:,4), sm(:,5), ...
                'VariableNames', ["Index","Kind","Role","Owner","Name","Label","Bus"]);
    sv_key = sm(:,1) + "|" + sm(:,4);
    [~, iv_src] = ismember(sm_conn(:,2) + "|" + sm_conn(:,3), sv_key);
    [~, iv_tgt] = ismember(sm_conn(:,4) + "|" + sm_conn(:,5), sv_key);
    lv_glob = sm_conn(:,1) == "global";
    [~, iv_ord] = sortrows([iv_tgt, double(lv_glob)]);
    sm_conn = sm_conn(iv_ord,:);
    m = size(sm_conn,1);
    tab_connection = table((1:m)', sm_conn(:,1), sm_conn(:,3), sm_conn(:,5), iv_src(iv_ord), iv_tgt(iv_ord), ...
                           'VariableNames', ["Index","Kind","Source","Target","SourceIndex","TargetIndex"]);
end

function sm = rows(s_kind, s_owner, sv_name, sv_label)
    n = numel(sv_name);
    sm = [repmat(s_kind,n,1), repmat(s_owner,n,1), sv_name, sv_label, strings(n,1)];
end

function sv = label(owner, sv_name)
    % Tagged name: the state, input or port name used by get_sys
    if isempty(sv_name)
        sv = strings(0,1);
    else
        sv = reshape(string(owner.attach_tag(reshape(string(sv_name), [], 1))), [], 1);
    end
end

function sv = label_y(owner, sv_name)
    % Tagged output name, as in get_sys: "Y_" + name when owner has a state of that name
    sv_name = reshape(string(sv_name), [], 1);
    lv = ismember(sv_name, owner.sv_x);
    sv_name(lv) = "Y_" + sv_name(lv);
    sv = label(owner, sv_name);
end

function list = all_controllers(parent)
    % Local controllers of parent, depth first
    list = cell(0,1);
    for k = 1:numel(parent.a_LocalController)
        con  = parent.a_LocalController{k};
        list = [list; {con}; all_controllers(con)]; %#ok<AGROW>
    end
end
