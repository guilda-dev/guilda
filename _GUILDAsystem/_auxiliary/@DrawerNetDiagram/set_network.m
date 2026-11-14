function set_network(obj, sct_network)
% Read the buses, branches and components of a network snapshot (struct(net, false)).
%
% Uses the tags, classes and tab_parameter (operation, graph, dynamics) of the snapshot and
% the admittance matrix of each branch (its field cm_Y, added by Branch.struct). When a bus
% has no position (NaN Xaxis or Yaxis), the positions of all buses come from the "force"
% layout; a component without a position is placed around its bus. The positions are kept
% in the drawer only. Call set_powerflow afterwards to set the state shown.
    arguments (Input)
        obj
        sct_network (1,1) struct % Snapshot of the network: struct(net, false).
    end
    if ~isfield(sct_network, "a_Bus") || ~isfield(sct_network, "a_Branch")
        error(msg("GUILDA:DrawerNetDiagram:NoNetworkSnapshot"));
    end
    a_bus    = reshape(sct_network.a_Bus, [], 1);
    a_branch = reshape(sct_network.a_Branch, [], 1);
    obj.n_bus    = numel(a_bus);
    obj.n_branch = numel(a_branch);
    obj.n_component = sum(cellfun(@(b) numel(b.a_Component), a_bus));

    get_tab = @(bus) [table(string(bus.s_bustype), 'VariableNames', "Type"), ...
                      bus.tab_parameter(:, ["operation","graph"])];
    obj.tab_bus = tools.vcellfun(get_tab, a_bus);
    obj.sv_bus  = string(cellfun(@(b) b.s_tag, a_bus, "UniformOutput", false));

    get_tab = @(bra) [table(string(bra.class), 'VariableNames', "class"), ...
                      bra.tab_parameter(:, ["operation","graph","dynamics"])];
    obj.tab_branch = tools.vcellfun(get_tab, a_branch);
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

    % Force layout when a bus has no position (kept in the drawer, not in the network)
    rm_axis = obj.tab_bus.graph{:, ["Xaxis","Yaxis"]};
    if any(isnan(rm_axis), 'all')
        G      = graph(obj.im_edge(1,:), obj.im_edge(2,:), [], cellstr(obj.sv_bus));
        fig    = figure('Visible', 'off');
        h_temp = plot(axes(fig), G, 'Layout', 'force', 'UseGravity', true, 'Iterations', 100);
        rm_axis = [h_temp.XData(:), h_temp.YData(:)];
        close(fig);
        obj.tab_bus.graph{:, ["Xaxis","Yaxis"]} = rm_axis;
    end

    % Components, bus by bus
    i_comp = 0;
    obj.sv_component  = strings(obj.n_component, 1);
    obj.tab_component = cell(obj.n_component, 1);
    for i = 1:obj.n_bus
        s_busi  = obj.sv_bus(i);
        a_compi = reshape(a_bus{i}.a_Component, [], 1);
        n_compi = numel(a_compi);
        for j = 1:n_compi
            compij = a_compi{j};
            i_comp = i_comp + 1;
            obj.sv_component(i_comp) = regexprep(string(compij.s_tag), "^" + s_busi, "");   % without the leading bus tag
            tab_compi = [table(i, string(compij.class), 'VariableNames', ["bus","class"]), ...
                         compij.tab_parameter(:, ["operation","graph"])];
            if any(isnan(tab_compi.graph{:, ["Xaxis","Yaxis"]}))
                c_diff = 0.05 * exp(1j*2*pi*(j-1)/n_compi);   % spread the components around the bus
                tab_compi.graph.Xaxis = obj.tab_bus.graph.Xaxis(i) + real(c_diff);
                tab_compi.graph.Yaxis = obj.tab_bus.graph.Yaxis(i) + imag(c_diff);
            end
            obj.tab_component{i_comp} = tab_compi;
        end
    end
    obj.tab_component = vertcat(obj.tab_component{:});
    if isempty(obj.tab_component)
        obj.tab_component = table(zeros(0,1), strings(0,1), 'VariableNames', ["bus","class"]);
    end

    % Maps from the bus voltages to the end voltages and currents of the branches
    obj.cm_Vbus2Ibranch = zeros(obj.n_branch*2, obj.n_bus);
    obj.cm_Vbus2Vbranch = zeros(obj.n_branch*2, obj.n_bus);
    Ysvd = nan(obj.n_branch, 1);
    for k = 1:obj.n_branch
        if ~isfield(a_branch{k}, "cm_Y")
            error(msg("GUILDA:DrawerNetDiagram:NoBranchAdmittance", obj.sv_branch(k)));
        end
        cm_Yk = a_branch{k}.cm_Y;
        obj.cm_Vbus2Ibranch(2*k-1:2*k, obj.im_edge(:,k)) = cm_Yk;
        obj.cm_Vbus2Vbranch(2*k-1:2*k, obj.im_edge(:,k)) = eye(2);
        Ysvd(k) = max(svd(cm_Yk));
    end
    obj.tab_branch.dynamics = [table(Ysvd), obj.tab_branch.dynamics];
    obj.cm_Vbus2Ibranch = sparse(obj.cm_Vbus2Ibranch);
    obj.cm_Vbus2Vbranch = sparse(obj.cm_Vbus2Vbranch);
end
