function [tab, c_idx, tab_connection] = get_variable_map(obj, s_form)
% Return the variable map of the bus and the connections inside its components.
%
% Variable map of the bus: the rows of net.get_variable_map() that belong to it, in the
% same relative order (see PowerNetwork.get_variable_map for the columns):
%   1. x: states of each component in a_Component (with its local controllers)
%   2. Vre, Vim of the bus
%   3. u: inputs of each component
%   4. uc: inputs of the local controllers of each component
%   5. y, 6. yc: outputs of each component and of its local controllers (signals)
% The rows of the kinds x, Vre, Vim and u come first: they are the order of the point
% vector of bus.get_sys(point). Index counts from 1 here. The column Equilibrium is
% as in the map of the network (NaN in every row before net.initialize). tab_connection lists the
% connections inside the components (Component.get_variable_map), with the indices of
% this map. get_variable_map("rows") is the form used inside the map: see
% PowerNetwork.get_variable_map.
%
% See also PowerNetwork.get_variable_map, PowerSystemModel.get_sys
%
% <@Group> Called by analyses
    arguments (Input)
        obj
        s_form (1,1) string {mustBeMember(s_form, ["table","rows"])} = "table" % "rows" (internal): return the rows without the tables.
    end
    arguments (Output)
        tab              % One row per variable or signal: Index, Kind, Role, Owner, Name, Label, Bus, Equilibrium.
        c_idx            % c_idx{j}: rows of tab that form a_Component{j}.get_variable_map(), in its order.
        tab_connection   % One row per connection: Index, Kind, Source, Target, SourceIndex, TargetIndex.
    end
    a_comp = obj.a_Component;
    n_comp = numel(a_comp);
    c_comp = cell(n_comp,1);
    c_conn = cell(n_comp,1);
    for j = 1:n_comp
        [c_comp{j}, c_conn{j}] = a_comp{j}.get_variable_map("rows");
    end

    % The rows of each kind: those of each component, except the bus voltage (once)
    sv_V  = string(obj.attach_tag(["Vre";"Vim"]));
    s_bus = string(obj.s_tag);
    sm_V  = [["Vre";"Vim"], repmat(s_bus,2,1), ["Vre";"Vim"], sv_V(:), repmat(s_bus,2,1)];
    n_kind = 6;
    c_rows = cell(n_kind,1);
    nm = zeros(n_comp, n_kind);       % rows of each component and kind
    for m = 1:n_kind
        if m == 2
            c_rows{m} = sm_V;
            nm(:,m) = 2;
            continue
        end
        c_m = tools.cellfun(@(r) r{m}, c_comp);
        c_rows{m} = vertcat(strings(0,5), c_m{:});
        nm(:,m) = cellfun(@(r) size(r{m},1), c_comp);
    end
    sm_conn = vertcat(strings(0,5), c_conn{:});

    % rows of each component: its rows of each kind, and the bus V
    n_all = cellfun(@(r) size(r,1), c_rows);
    iv_0  = [0; cumsum(n_all(1:end-1))];
    c_idx = cell(n_comp,1);
    for j = 1:n_comp
        c_j = cell(n_kind,1);
        for m = 1:n_kind
            if m == 2
                c_j{m} = iv_0(2) + (1:2)';
            else
                c_j{m} = iv_0(m) + sum(nm(1:j-1,m)) + (1:nm(j,m))';
            end
        end
        c_idx{j} = vertcat(c_j{:});
    end

    if s_form == "rows"
        tab = c_rows;
        tab_connection = sm_conn;
        return
    end
    [tab, tab_connection] = make_tables(vertcat(c_rows{:}), sm_conn);

    % Equilibrium: the values of the maps of the components and the bus voltage; NaN
    % everywhere when a part has none (before net.initialize)
    rv_eq = nan(height(tab),1);
    net = obj.a_PowerNetwork;
    if ~isempty(net) && ~any(net.sct_stale.powerflow == net.s_notInitialized)
        rv_eq(iv_0(2) + (1:2)) = [real(obj.c_Vequilibrium); imag(obj.c_Vequilibrium)];
        for j = 1:n_comp
            tab_j = a_comp{j}.get_variable_map();
            rv_eq(c_idx{j}) = tab_j.Equilibrium;
        end
        if any(isnan(rv_eq))
            rv_eq(:) = NaN;
        end
    end
    tab.Equilibrium = rv_eq;
end


function [tab, tab_connection] = make_tables(sm, sm_conn)
    % The tables from the rows; the connections point to the rows by Index
    n = size(sm,1);
    sv_role = repmat("variable", n, 1);
    sv_role(ismember(sm(:,1), ["y","yc"])) = "signal";
    tab = table((1:n)', sm(:,1), sv_role, sm(:,2), sm(:,3), sm(:,4), sm(:,5), ...
                'VariableNames', ["Index","Kind","Role","Owner","Name","Label","Bus"]);
    sv_key = sm(:,1) + "|" + sm(:,4);
    [~, iv_src] = ismember(sm_conn(:,2) + "|" + sm_conn(:,3), sv_key);
    [~, iv_tgt] = ismember(sm_conn(:,4) + "|" + sm_conn(:,5), sv_key);
    [iv_tgt, iv_ord] = sort(iv_tgt);
    sm_conn = sm_conn(iv_ord,:);
    m = size(sm_conn,1);
    tab_connection = table((1:m)', sm_conn(:,1), sm_conn(:,3), sm_conn(:,5), iv_src(iv_ord), iv_tgt, ...
                           'VariableNames', ["Index","Kind","Source","Target","SourceIndex","TargetIndex"]);
end
