function set_network(obj, sct_network)
% Read the buses, branches and components of a network snapshot (struct(net, false)).
%
% Uses the tags, classes and tab_parameter (operation, graph, dynamics) of the snapshot and
% the admittance matrix of each branch (its field cm_Y, added by Branch.struct). The graph
% columns are kept as in the model (notes/graph-layout.md): a bus has its center X, Y, a
% component its position DX, DY relative to the center of its bus. A bus without a
% position (NaN X or Y) keeps the position it had when the diagram already showed a
% network (by tag); the others are placed by tools.layout_place_buses, which never moves
% the buses with a position (all buses take the "force" layout only when none has one).
% A component without a position keeps the one it had (by tag), else it is placed around
% its bus at 0.3*d0 (d0: the length scale of tools.layout_place_buses). The positions are
% kept in the graph only (set_position changes them). The fixed colors (BusColor, ...) and
% the sizes (BusMarkerSize, ComponentMarkerSize, BranchLineWidth) start as NaN rows. Call
% load_data afterwards to set the state shown.
    arguments (Input)
        obj
        sct_network (1,1) struct  % Snapshot of the network: struct(net, false).
    end
    if ~isfield(sct_network, "a_Bus") || ~isfield(sct_network, "a_Branch")
        error(msg("GUILDA:GraphNetDiagram:NoNetworkSnapshot"));
    end
    % Positions shown before (a network set again keeps them for the same tags)
    sct_old = struct("sv_bus", strings(0, 1), "rm_bus", zeros(0, 2), "sv_comp", strings(0, 1), "rm_comp", zeros(0, 2));
    if ~isempty(obj.tab_bus)
        sct_old.sv_bus  = obj.sv_bus;
        sct_old.rm_bus  = obj.tab_bus.graph{:, ["X","Y"]};
        if ~isempty(obj.sv_componentTag)
            sct_old.sv_comp = obj.sv_componentTag;
            sct_old.rm_comp = obj.tab_component.graph{:, ["DX","DY"]};
        end
    end
    a_bus    = reshape(sct_network.a_Bus, [], 1);
    a_branch = reshape(sct_network.a_Branch, [], 1);
    obj.n_bus    = numel(a_bus);
    obj.n_branch = numel(a_branch);
    obj.n_component = sum(cellfun(@(b) numel(b.a_Component), a_bus));

    % One table per kind: the parameter tables stacked, then the type or class in front
    obj.tab_bus = [table(string(cellfun(@(b) b.s_bustype, a_bus, "UniformOutput", false)), 'VariableNames', "Type"), ...
                   tools.vcellfun(@(b) b.tab_parameter(:, ["operation","graph"]), a_bus)];
    obj.sv_bus  = string(cellfun(@(b) b.s_tag, a_bus, "UniformOutput", false));

    obj.tab_branch = [table(string(cellfun(@(b) b.class, a_branch, "UniformOutput", false)), 'VariableNames', "class"), ...
                      tools.vcellfun(@(b) b.tab_parameter(:, ["operation","graph","dynamics"]), a_branch)];
    obj.sv_branch  = string(cellfun(@(b) b.s_tag, a_branch, "UniformOutput", false));

    % End buses of each branch: "net.a_Bus{i}" in the snapshot, or a bus struct
    obj.im_edge = zeros(2, obj.n_branch);
    for k = 1:obj.n_branch
        a_end = a_branch{k}.a_Bus;
        for m = 1:2
            x = a_end{m};
            if isstruct(x)
                obj.im_edge(m, k) = find(obj.sv_bus == string(x.s_tag), 1);
            else
                obj.im_edge(m, k) = str2double(regexp(string(x), "a_Bus\{(\d+)\}$", "tokens", "once"));
            end
        end
    end

    % Bus positions: the model, else the position shown before (same tag), else placed
    % near the neighbours (kept in the graph, not in the network)
    d0 = 0.1;
    if obj.n_bus > 0
        rm_xy  = obj.tab_bus.graph{:, ["X","Y"]};
        l_free = any(isnan(rm_xy), 2);
        [l_old, i_old] = ismember(obj.sv_bus, sct_old.sv_bus);
        l_keep = l_free & l_old;
        rm_xy(l_keep, :) = sct_old.rm_bus(i_old(l_keep), :);
        sv_shape = obj.tab_bus.graph.Shape;
        rv_len   = nan(obj.n_bus, 1);
        rv_len(sv_shape == "hbar") =  obj.tab_bus.graph.Length(sv_shape == "hbar");
        rv_len(sv_shape == "vbar") = -obj.tab_bus.graph.Length(sv_shape == "vbar");
        c_path = cell(obj.n_branch, 1);
        for k = 1:obj.n_branch
            c_path{k} = tools.layout_parse_path(obj.tab_branch.graph.Path(k));
        end
        [rm_xy, d0] = tools.layout_place_buses(rm_xy, obj.im_edge', Length=rv_len, Path=c_path);
        obj.tab_bus.graph{:, ["X","Y"]} = rm_xy;
    end

    % Components, bus by bus
    i_comp = 0;
    obj.sv_component    = strings(obj.n_component, 1);
    obj.sv_componentTag = strings(obj.n_component, 1);
    iv_compBus  = zeros(obj.n_component, 1);
    sv_class    = strings(obj.n_component, 1);
    rm_d        = nan(obj.n_component, 2);
    c_par       = cell(obj.n_component, 1);
    for i = 1:obj.n_bus
        s_busi  = obj.sv_bus(i);
        a_compi = reshape(a_bus{i}.a_Component, [], 1);
        n_compi = numel(a_compi);
        for j = 1:n_compi
            compij = a_compi{j};
            i_comp = i_comp + 1;
            obj.sv_componentTag(i_comp) = string(compij.s_tag);
            obj.sv_component(i_comp) = regexprep(string(compij.s_tag), "^" + s_busi, "");   % without the leading bus tag
            iv_compBus(i_comp) = i;
            sv_class(i_comp)   = string(compij.class);
            c_par{i_comp}      = compij.tab_parameter(:, ["operation","graph"]);
            rv_d   = [c_par{i_comp}.graph.DX, c_par{i_comp}.graph.DY];
            i_prev = find(sct_old.sv_comp == obj.sv_componentTag(i_comp), 1);
            if any(isnan(rv_d)) && ~isempty(i_prev)
                rv_d = sct_old.rm_comp(i_prev, :);
            elseif any(isnan(rv_d))
                c_diff = 0.3 * d0 * exp(1j*2*pi*(j-1)/n_compi);   % spread the components around the bus
                rv_d = [real(c_diff), imag(c_diff)];
            end
            rm_d(i_comp, :) = rv_d;
        end
    end
    if obj.n_component > 0
        obj.tab_component = [table(iv_compBus, sv_class, 'VariableNames', ["bus","class"]), vertcat(c_par{:})];
        obj.tab_component.graph{:, ["DX","DY"]} = rm_d;
    else
        obj.tab_component = table(zeros(0,1), strings(0,1), 'VariableNames', ["bus","class"]);
    end

    % Maps from the bus voltages to the end voltages and currents of the branches
    obj.cm_Vbus2Ibranch = zeros(obj.n_branch*2, obj.n_bus);
    obj.cm_Vbus2Vbranch = zeros(obj.n_branch*2, obj.n_bus);
    Ysvd = nan(obj.n_branch, 1);
    for k = 1:obj.n_branch
        if ~isfield(a_branch{k}, "cm_Y")
            error(msg("GUILDA:GraphNetDiagram:NoBranchAdmittance", obj.sv_branch(k)));
        end
        cm_Yk = a_branch{k}.cm_Y;
        obj.cm_Vbus2Ibranch(2*k-1:2*k, obj.im_edge(:,k)) = cm_Yk;
        obj.cm_Vbus2Vbranch(2*k-1:2*k, obj.im_edge(:,k)) = eye(2);
        Ysvd(k) = max(svd(cm_Yk));
    end
    if obj.n_branch == 0                       % a network still being built: no branch yet
        tab_none = table('Size', [0, 0], 'VariableTypes', {});
        obj.tab_branch = table(strings(0, 1), tab_none, tab_none, ...
            table(zeros(0, 1), zeros(0, 1), zeros(0, 1), 'VariableNames', ["Ysvd", "R", "X"]), ...
            'VariableNames', ["class", "operation", "graph", "dynamics"]);
    else
        obj.tab_branch.dynamics = [table(Ysvd), obj.tab_branch.dynamics];
    end
    obj.cm_Vbus2Ibranch = sparse(obj.cm_Vbus2Ibranch);
    obj.cm_Vbus2Vbranch = sparse(obj.cm_Vbus2Vbranch);

    % Fixed colors and sizes: none until set_style or the properties set them
    obj.BusColor            = nan(obj.n_bus, 3);
    obj.ComponentColor      = nan(obj.n_component, 3);
    obj.BranchColor         = nan(obj.n_branch, 3);
    obj.LinkColor           = nan(obj.n_component, 3);
    obj.BusMarkerSize       = nan(obj.n_bus, 1);
    obj.ComponentMarkerSize = nan(obj.n_component, 1);
    obj.BranchLineWidth     = nan(obj.n_branch, 1);
    obj.BusLabel            = obj.sv_bus;
    obj.ComponentLabel      = obj.sv_component;
end

