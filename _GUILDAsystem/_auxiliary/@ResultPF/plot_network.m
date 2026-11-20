function G = plot_network(obj, opt)
% Plot the network with the bus voltages and the branch flows, as a GraphNetMap.
%
% Draws the buses as nodes and the branches as edges of a MATLAB graph plot. The node
% color is |V| [pu] (Color="V") or the angle [deg] (Color="angle"), with a colorbar.
% With Arrow="P" or "Q", each edge is an arrow in the direction of the active or reactive
% power flow (from the end where the power enters the branch) and its width grows with the
% larger |P| or |Q| of the two ends; Arrow="none" draws plain lines. The node positions
% are X and Y (the centers) of the graph parameters of the buses in the network snapshot.
% The buses without a position are placed near their neighbours by
% tools.layout_place_buses, as in PowerNetwork.plot_diagram (the buses with a position
% never move). It reads only the stored result. The returned map changes its buses and branches by tag
% (set_style, set_position) or by its vector properties (BusColor, BranchLineWidth, ...);
% G.sct_plt.Graph is the graph plot.
%
% <@Examples>
% ```matlab
% res = network.IEEE14bus().calculate_powerflow();
% G = res.plot_network();                      % |V| colors, P arrows
% G = res.plot_network(Color="angle", Arrow="none");
% G.set_style("B001", Color="r");
% ```
%
% See also GraphNetMap, ResultPF.plot_voltage, ResultPF.plot_branch, PowerNetwork.plot_diagram
    arguments (Input)
        obj
        opt.Parent = []  % Container (figure, uifigure, uipanel, uitab, uigridlayout) or axes/uiaxes to draw in; a new figure when empty.
        opt.Color (1,1) string {mustBeMember(opt.Color, ["V","angle"])} = "V"  % Node color: |V| [pu] or the angle [deg].
        opt.Arrow (1,1) string {mustBeMember(opt.Arrow, ["P","Q","none"])} = "P"  % Edge arrows along the P or Q flow, or plain lines.
    end
    arguments (Output)
        G (1,1) GraphNetMap  % Map of the network (tab_element: buses and branches).
    end
    sct_net = obj.sct_network;
    if ~isfield(sct_net, "a_Bus") || ~isfield(sct_net, "a_Branch")
        error(msg("GUILDA:ResultPF:NoNetworkSnapshot"))
    end
    sv_bus = string(obj.tab_bus.Properties.RowNames);
    n_bus  = numel(sv_bus);
    tab_br = obj.tab_branch;
    n_br   = height(tab_br);
    im_end = zeros(n_br, 2);
    for k = 1:n_br
        im_end(k,:) = bus_index(sct_net.a_Branch{k}.a_Bus, sv_bus).';
    end
    rm_xy  = nan(n_bus, 2);
    rv_len = nan(n_bus, 1);
    for i_bus = 1:n_bus
        tab_g = sct_net.a_Bus{i_bus}.tab_parameter.graph;
        rm_xy(i_bus, :) = [tab_g.X, tab_g.Y];
        rv_len(i_bus)   = tab_g.Length * ((tab_g.Shape == "hbar") - (tab_g.Shape == "vbar"));   % signed bar length
    end
    rv_len(rv_len == 0) = NaN;
    c_path = cell(n_br, 1);
    for k = 1:n_br
        c_path{k} = tools.layout_parse_path(sct_net.a_Branch{k}.tab_parameter.graph.Path);
    end
    sct = struct("sv_bus", sv_bus, "rm_xy", rm_xy, "rv_length", rv_len, "c_path", {c_path}, "cv_V", obj.tab_bus.Vphasor, ...
        "sv_branch", string(tab_br.Properties.RowNames), "im_end", im_end, ...
        "rm_P", [tab_br.Pfrom, tab_br.Pto], "rm_Q", [tab_br.Qfrom, tab_br.Qto], ...
        "s_color", opt.Color, "s_arrow", opt.Arrow);
    G = GraphNetMap(sct, Parent=opt.Parent);
end
