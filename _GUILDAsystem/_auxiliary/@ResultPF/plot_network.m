function h = plot_network(obj, opt)
% Plot the network with the bus voltages and the branch flows.
%
% Draws the buses as nodes and the branches as edges of a MATLAB graph plot. The node
% color is |V| [pu] (Color="V") or the angle [deg] (Color="angle"), with a colorbar.
% With Arrow="P" or "Q", each edge is an arrow in the direction of the active or reactive
% power flow (from the end where the power enters the branch) and its width grows with the
% larger |P| or |Q| of the two ends; Arrow="none" draws plain lines. The node positions
% are Xaxis and Yaxis of the graph parameters of the buses in the network snapshot. When a
% bus has none (NaN), the positions of all buses come from the "force" layout of MATLAB
% (graph plot), so the drawing stays readable; the given positions are then not used. It
% reads only the stored result.
%
% <@Examples>
% ```matlab
% res = network.IEEE14bus().calculate_powerflow();
% res.plot_network();                          % |V| colors, P arrows
% res.plot_network(Color="angle", Arrow="none");
% ```
%
% See also ResultPF.plot_voltage, ResultPF.plot_branch, PowerNetwork.plot_diagram
    arguments (Input)
        obj
        opt.Parent = [] % Container to draw in. A new figure when empty.
        opt.Color (1,1) string {mustBeMember(opt.Color, ["V","angle"])} = "V" % Node color: |V| [pu] or the angle [deg].
        opt.Arrow (1,1) string {mustBeMember(opt.Arrow, ["P","Q","none"])} = "P" % Edge arrows along the P or Q flow, or plain lines.
    end
    arguments (Output)
        h % GraphPlot of the network (XData, YData, NodeCData; LineWidth per edge; UserData: the branch tag of each edge).
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

    % flow of each branch along its arrow
    switch opt.Arrow
        case "P"; rm_flow = [tab_br.Pfrom, tab_br.Pto];
        case "Q"; rm_flow = [tab_br.Qfrom, tab_br.Qto];
        otherwise; rm_flow = zeros(n_br, 2);
    end
    lv_rev = rm_flow(:,1) < 0;                 % the power enters at the second bus
    im_dir = im_end;
    im_dir(lv_rev,:) = im_end(lv_rev, [2 1]);
    rv_mag = max(abs(rm_flow), [], 2);

    if opt.Arrow == "none"
        G = graph(im_end(:,1), im_end(:,2), [], cellstr(sv_bus));
    else
        G = digraph(im_dir(:,1), im_dir(:,2), [], cellstr(sv_bus));
    end
    % the edges of G may be reordered: map each back to its branch
    iv_edge = edge_order(G, im_dir, opt.Arrow == "none", im_end);

    if isempty(opt.Parent)
        opt.Parent = figure();
    end
    ax = axes(opt.Parent);
    [rv_x, rv_y] = positions(sct_net, n_bus);
    if any(isnan([rv_x; rv_y]))
        h = plot(ax, G, "Layout", "force");
    else
        h = plot(ax, G, "XData", rv_x, "YData", rv_y);
    end
    switch opt.Color
        case "V";     h.NodeCData = obj.tab_bus.V;               s_bar = "|V| [pu]";
        case "angle"; h.NodeCData = rad2deg(obj.tab_bus.Varg);   s_bar = "\angleV [deg]";
    end
    h.MarkerSize = 7;
    colormap(ax, parula);
    cb = colorbar(ax);
    cb.Label.String = s_bar;
    rv_width = ones(n_br,1);
    if opt.Arrow ~= "none" && max(rv_mag) > 0
        rv_width = 0.5 + 4.5 * rv_mag / max(rv_mag);
        h.ArrowSize = 9;
    end
    h.LineWidth = rv_width(iv_edge);
    h.UserData  = string(tab_br.Properties.RowNames(iv_edge));   % branch tag of each edge, in plot order
    title(ax, "Power flow (color: " + opt.Color + ", arrows: " + opt.Arrow + ")");
    axis(ax, "off");
end


function [rv_x, rv_y] = positions(sct_net, n_bus)
% Xaxis and Yaxis of the graph parameters of the buses (NaN when not set)
    rv_x = nan(n_bus,1);
    rv_y = nan(n_bus,1);
    for i_bus = 1:n_bus
        tab_g = sct_net.a_Bus{i_bus}.tab_parameter.graph;
        rv_x(i_bus) = double(tab_g.Xaxis);
        rv_y(i_bus) = double(tab_g.Yaxis);
    end
end


function iv = edge_order(G, im_dir, l_undirected, im_end)
% Branch of each edge of G (G.Edges is sorted by its end nodes)
    n  = height(G.Edges);
    iv = zeros(n,1);
    lv_used = false(size(im_dir,1),1);
    im_ref = im_dir;
    if l_undirected
        im_ref = sort(im_end, 2);
    end
    im_G = findnode(G, G.Edges.EndNodes);
    im_G = reshape(im_G, [], 2);
    for k = 1:n
        i = find(~lv_used & im_ref(:,1) == im_G(k,1) & im_ref(:,2) == im_G(k,2), 1);
        iv(k) = i;
        lv_used(i) = true;
    end
end
