function G = plot_diagram(obj, opt)
% Draw the network diagram of the equilibrium: buses, branches and components.
%
% The diagram is a single-line diagram in 2D (lines and markers); Dimension="3D" draws
% solids with lighting instead. The branch widths follow the admittance of the branches
% (BranchWidthMode "Ysvd") in BranchWidthRange, the bus and component sizes MarkerSizeMode
% in MarkerSizeRange (see GraphNetDiagram).
%
% State chooses what is drawn:
%
% - "auto" (default): the equilibrium of initialize (c_Vequilibrium of the buses,
%   c_Iequilibrium of the components) when the network is up to date; otherwise, before
%   net.initialize() or after an edit that made a layer stale, the topology only, with an
%   INFO message (GUILDA:PowerNetwork:DiagramTopology).
% - "equilibrium": the equilibrium; a network that is not up to date stops with
%   GUILDA:PowerNetwork:DiagramStale ("Run net.initialize() first").
% - "topology": the buses, branches and components only, with no state (the state is
%   NaN): no colors of values (no colorbar), no heights, no arrows, and the data tips show tags and
%   parameters. It works on a network still being built (no slack bus, a bus without
%   components or branches).
%
% The diagram is built from a snapshot of the network with the fields of struct(obj, false)
% that it reads (the tags, classes, bus types and parameter tables of the buses, branches
% and components, and the admittance matrix cm_Y of each branch; much faster than the
% whole struct) and does not change the network; positions from the automatic layout stay in the drawing. Graph=G draws into an
% existing diagram instead of a new one: G.set_data takes the new snapshot and state, in
% the same axes, keeping the positions, set_style settings and selection of the elements
% by tag, and G is returned. The other Name-Value options set the properties of the
% GraphNetDiagram. To draw a power flow solution or a time simulation, use
% ResultPF.plot_diagram or ResultODE.plot_diagram.
%
% <@Examples>
% ```matlab
% net = network.IEEE14bus();
% G = net.plot_diagram();                       % topology (not initialized yet)
% net.initialize();
% G = net.plot_diagram(Graph=G);                % the same diagram, now the equilibrium
% G = net.plot_diagram(ColorMode="P", BusHeightMode="V", State="equilibrium");
% G = net.plot_diagram(Dimension="3D");         % solids with lighting
% ```
%
% See also GraphNetDiagram, ResultPF.plot_diagram, ResultODE.plot_diagram, PowerNetwork.plot_spring_model
%
% <@Group> Queries and display
    arguments (Input)
        obj
        opt.?GraphNetDiagram  % Name-Value options; each sets the property of the same name of the GraphNetDiagram.
        opt.Parent = []       % Container (figure, uifigure, uipanel, uitab, uigridlayout) or axes/uiaxes to draw in; [] for a new figure.
        opt.State (1,1) string {mustBeMember(opt.State, ["auto", "equilibrium", "topology"])} = "auto"  % What is drawn: the equilibrium, the topology, or "auto" (see the help).
        opt.Graph = []        % Existing diagram to draw into; [] for a new one. <@Type> GraphNetDiagram
    end
    arguments (Output)
        G  % GraphNetDiagram object of the drawing.
    end
    s_state = opt.State;
    G_old   = opt.Graph;
    opt     = rmfield(opt, ["State", "Graph"]);
    if ~isempty(G_old) && ~(isa(G_old, "GraphNetDiagram") && isscalar(G_old) && isvalid(G_old) ...
            && ~isempty(G_old.ax) && all(isgraphics(G_old.ax)))
        error(msg("GUILDA:PowerNetwork:DiagramGraph", class(G_old)));
    end

    % Equilibrium, or topology only
    l_topology = s_state == "topology";
    if s_state == "equilibrium"
        simulateFcn_check(obj, "GUILDA:PowerNetwork:DiagramStale");
    elseif s_state == "auto"
        try                                         % its only error is DiagramStale
            simulateFcn_check(obj, "GUILDA:PowerNetwork:DiagramStale");
        catch
            show_msg("info", "GUILDA:PowerNetwork:DiagramTopology", char(obj.s_tag));
            l_topology = true;
        end
    end

    % Snapshot with the fields of struct(obj, false) the diagram reads (GraphNetDiagram.set_network);
    % the whole struct copies every property of every layer and takes most of the drawing time
    a_bus  = reshape(obj.a_Bus, [], 1);
    n_bus  = numel(a_bus);
    c_bus  = cell(n_bus, 1);
    for i = 1:n_bus
        bus = a_bus{i};
        a_comp = reshape(bus.a_Component, [], 1);
        c_comp = cell(numel(a_comp), 1);
        for j = 1:numel(a_comp)
            c_comp{j} = struct("class", string(class(a_comp{j})), "s_tag", a_comp{j}.s_tag, ...
                "tab_parameter", a_comp{j}.tab_parameter);
        end
        c_bus{i} = struct("class", string(class(bus)), "s_tag", bus.s_tag, "s_bustype", bus.s_bustype, ...
            "tab_parameter", bus.tab_parameter, "a_Component", {c_comp});
    end
    a_branch = reshape(obj.a_Branch, [], 1);
    c_branch = cell(numel(a_branch), 1);
    for k = 1:numel(a_branch)
        br = a_branch{k};
        c_end = cell(2, 1);
        for m = 1:2
            c_end{m} = "net.a_Bus{" + find(cellfun(@(b) b == br.a_Bus{m}, a_bus), 1) + "}";
        end
        c_branch{k} = struct("class", string(class(br)), "s_tag", br.s_tag, "tab_parameter", br.tab_parameter, ...
            "a_Bus", {c_end}, "cm_Y", br.get_admittance_matrix());
    end
    sct_net = struct("class", string(class(obj)), "s_tag", obj.s_tag, "a_Bus", {c_bus}, "a_Branch", {c_branch});

    n_comp  = sum(cellfun(@(b) numel(b.a_Component), a_bus));
    sct_state = struct();
    sct_state.rv_t = 0;
    if l_topology
        sct_state.cm_Vbus  = complex(nan(n_bus, 1));
        sct_state.cm_Icomp = complex(nan(n_comp, 1));
    else
        sct_state.cm_Vbus  = cellfun(@(b) b.c_Vequilibrium, a_bus);
        c_Icomp            = cellfun(@(b) cellfun(@(c) c.c_Iequilibrium, reshape(b.a_Component, [], 1)), ...
                                     a_bus, "UniformOutput", false);
        sct_state.cm_Icomp = vertcat(c_Icomp{:}, zeros(0, 1));
    end

    if isempty(G_old)
        c_opt = namedargs2cell(opt);
        G = GraphNetDiagram(sct_net, sct_state, c_opt{:});
        return
    end
    G = G_old;
    for s_field = setdiff(string(fieldnames(opt))', "Parent")
        G.(s_field) = opt.(s_field);
    end
    sct_state.sct_network = sct_net;
    G.set_data(sct_state);
end
