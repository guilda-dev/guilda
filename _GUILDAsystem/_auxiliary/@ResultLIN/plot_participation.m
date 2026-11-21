function sct_graph = plot_participation(obj, opt)
% Plot the participation of the buses in a mode, picked on the eigenvalue map.
%
% Draws one figure (in Parent) with three parts:
%
% - left: the eigenvalue map of plot_eigenvalue (GraphChart, marker sets "stable" and
%   "unstable"). Clicking an eigenvalue picks the mode of that eigenvalue (the nearest
%   eigenvalue, or its conjugate, of the modes of get_participation in the section shown
%   to the point clicked), marked by a black ring on it and its conjugate.
% - right: the diagram of the snapshot sct_network (GraphNetDiagram, the topology), whose
%   buses are colored by tab_bus.Participation of get_participation in the mode picked,
%   on the colormap of the diagram with a colorbar from 0 to the largest participation of
%   the mode. A bus without states (no component or controller states at it, and no bus
%   variable in Type "DAE") is gray (NaN), and so is every bus of a section that has fewer
%   modes. The title gives the mode, its eigenvalue, frequency and damping ratio.
% - below the diagram: a table of the bus clicked (or selected) on the diagram, with the
%   participation of each state of that bus in the mode picked (a component clicked shows
%   its bus). Its panel title is the tag of the bus.
%
% Mode is the mode picked first: the column of get_participation (the modes of get_mode,
% one of each complex pair, sorted by the real part, the largest first). Type chooses the
% model, as in get_participation.
%
% A result with several sections (numel(rv_t) > 1) has one sample per section in both
% graphs, which are linked (G.link): the playback bar of either switches the section of
% both, and the colors, the ring and the table follow the mode of the same number in that
% section. It starts at Index; a Mode beyond the modes of that section stops with
% GUILDA:ResultLIN:ModeRange. Only a result of the network has a diagram; another layer
% stops with GUILDA:ResultLIN:NetworkOnly.
%
% It returns a struct with the parts: Eigenvalue (the GraphChart), Diagram (the
% GraphNetDiagram) and Table (the uitable). The two graphs are GraphBase objects; a bus
% clicked is also selected on the diagram (Diagram.select). Their ElementClickedFcn are
% used by the figure: add more with addlistener(G, "ElementClicked", ...).
%
% <@Examples>
% ```matlab
% res = net.get_sys();
% sct = res.plot_participation();             % click an eigenvalue, then a bus
% sct = res.plot_participation(Mode=3);       % the third mode of get_participation
% sct.Diagram.BusColorData                    % = tab_bus.Participation(:, 3), NaN without states
% res = net.get_sys({sim, [0.5 1 2]});
% sct = res.plot_participation(Index=2);      % sections switched by the playback bar
% ```
%
% See also ResultLIN.get_participation, ResultLIN.plot_eigenvalue, ResultLIN.get_mode, GraphNetDiagram
    arguments (Input)
        obj
        opt.Mode (1,1) double {mustBeInteger, mustBePositive} = 1  % Mode picked first: a column of get_participation.
        opt.Type (1,1) string {mustBeMember(opt.Type, ["ODE","DAE"])} = obj.Type  % Model whose modes are used: "ODE" or "DAE"; the Type of the result when omitted.
        opt.Index (1,1) double {mustBeInteger, mustBePositive} = obj.Index  % Section shown first (1 ... numel(rv_t)); res.Index when omitted.
        opt.Parent = []                                        % Container (figure, uifigure, uipanel, uitab, uigridlayout) to draw in; [] for a new figure.
    end
    arguments (Output)
        sct_graph struct  % Eigenvalue (GraphChart), Diagram (GraphNetDiagram) and Table (uitable).
    end
    if ~(isfield(obj.output, "s_layer") && obj.output.s_layer == "PowerNetwork")
        error(msg("GUILDA:ResultLIN:NetworkOnly", "plot_participation"))
    end
    n_t = numel(obj.rv_t);
    if opt.Index > n_t
        error(msg("GUILDA:ResultLIN:IndexRange", string(n_t)))
    end
    sct_part = obj.get_participation(Type=opt.Type, Index="all");
    if opt.Mode > numel(sct_part(opt.Index).cv_lambda)
        error(msg("GUILDA:ResultLIN:ModeRange", string(numel(sct_part(opt.Index).cv_lambda))))
    end

    % Layout: the eigenvalues on the left, the diagram and the table on the right
    h_parent = opt.Parent;
    if isempty(h_parent)
        h_parent = figure("Color", "w");
    end
    h_root = uipanel(h_parent, "BorderType", "none", "Units", "normalized", "Position", [0 0 1 1], ...
        "Tag", "GUILDA:ResultLIN:Participation");
    if isprop(h_parent, "Color")
        h_root.BackgroundColor = h_parent.Color;
    end
    c_panel = {"BorderType", "none", "Units", "normalized", "BackgroundColor", h_root.BackgroundColor};
    h_eig  = uipanel(h_root, c_panel{:}, "Position", [0 0 0.42 1]);
    h_net  = uipanel(h_root, c_panel{:}, "Position", [0.42 0.28 0.58 0.72]);
    h_info = uipanel(h_root, "Units", "normalized", "Position", [0.43 0.01 0.56 0.26], "Title", "Click a bus");
    h_tab  = uitable(h_info, "Units", "normalized", "Position", [0 0 1 1], "Data", cell(0, 2), ...
        "ColumnName", {'Variable', 'Participation'}, "RowName", {}, "Tag", "GUILDA:ResultLIN:ParticipationTable");

    G_eig = obj.plot_eigenvalue(Type=opt.Type, Index=opt.Index, Parent=h_eig);
    [G_net, sv_bus, ~, sv_title] = section_diagram(obj, "Participation", {"ColorbarLabel", "participation", "Parent", h_net});

    % The bus of each state of every section, and the participation of the buses (NaN without states)
    tab = obj.tab_variable;
    c_at  = cell(1, n_t);
    c_bus = cell(1, n_t);
    for s = 1:n_t
        P = sct_part(s);
        [lv_known, iv_row] = ismember(P.sv_state, tab.Label);
        sv_at = P.sv_owner;
        sv_at(lv_known) = tab.Bus(iv_row(lv_known));
        [~, iv] = ismember(sv_bus, P.tab_bus.Bus);
        rm = P.tab_bus.Participation(iv, :);
        rm(~ismember(sv_bus, sv_at), :) = NaN;
        c_at{s}  = sv_at;
        c_bus{s} = rm;
    end
    h_root.UserData = struct("sct_part", sct_part, "c_at", {c_at}, "c_bus", {c_bus}, "i_mode", opt.Mode, ...
        "s_bus", "", "sv_title", sv_title, "G_eig", G_eig, "G_net", G_net, "h_tab", h_tab, "h_info", h_info, ...
        "h_ring", line(G_eig.ax(1), NaN, NaN, "LineStyle", "none", "Marker", "o", "MarkerSize", 12, ...
        "LineWidth", 1.5, "Color", "k", "HitTest", "off", "PickableParts", "none", "HandleVisibility", "off", ...
        "Tag", "GUILDA:ResultLIN:PickedMode"));

    G_eig.ElementClickedFcn = @(G, data) pick_mode(h_root, G);
    G_net.ElementClickedFcn = @(G, data) pick_bus(h_root, data);
    if n_t > 1
        G_net.TimeChangedFcn = @(G, data) show_mode(h_root);
        G_net.set_time(G_net.rv_t(opt.Index));
        G_eig.link(G_net);
    end
    show_mode(h_root);
    sct_graph = struct("Eigenvalue", G_eig, "Diagram", G_net, "Table", h_tab);
end


function pick_mode(h_root, G)
% Click on a marker set of the eigenvalues: the mode nearest to the point clicked (CurrentPoint of the axes)
    arguments (Input)
        h_root  % Panel of the figure, with the data in UserData.
        G       % The eigenvalue chart.
    end
    if ~isvalid(h_root)
        return
    end
    U = h_root.UserData;
    rv_p = G.ax(1).CurrentPoint(1, 1:2);
    cv_lambda = U.sct_part(U.G_net.i_time).cv_lambda;
    if isempty(cv_lambda)
        return
    end
    c_p = complex(rv_p(1), rv_p(2));
    [~, m] = min(min(abs(cv_lambda - c_p), abs(conj(cv_lambda) - c_p)));
    U.i_mode = m;
    h_root.UserData = U;
    show_mode(h_root);
end


function pick_bus(h_root, data)
% Click on the diagram: a bus, or the bus of a component, for the table
    arguments (Input)
        h_root  % Panel of the figure, with the data in UserData.
        data    % Event data (GraphEventData).
    end
    if ~isvalid(h_root)
        return
    end
    U = h_root.UserData;
    s_bus = "";
    switch data.Kind
        case "bus"
            s_bus = data.Tag;
        case {"component", "link"}
            tab = U.G_net.tab_element;
            sv_bus = tab.Tag(tab.Kind == "bus");
            s_bus = sv_bus(startsWith(data.Tag, sv_bus));
            if ~isempty(s_bus)
                [~, i] = max(strlength(s_bus));
                s_bus = s_bus(i);
            end
    end
    if isempty(s_bus) || s_bus == ""
        return
    end
    U.s_bus = s_bus;
    h_root.UserData = U;
    U.G_net.select(s_bus);
    show_mode(h_root);
end


function show_mode(h_root)
% Colors, title, ring and table of the mode picked in the section shown (also the TimeChangedFcn of the diagram)
    arguments (Input)
        h_root  % Panel of the figure, with the data in UserData.
    end
    if ~isvalid(h_root)
        return
    end
    U = h_root.UserData;
    G = U.G_net;
    k = G.i_time;
    m = U.i_mode;
    P = U.sct_part(k);
    rm = U.c_bus{k};
    s_mode = sprintf("mode %d", m);
    if m <= size(rm, 2)
        rv_c = rm(:, m);
        c_l = P.cv_lambda(m);
        s_sign = "+";
        if imag(c_l) < 0
            s_sign = "-";
        end
        s_mode = s_mode + sprintf(": \\lambda = %.4g %s %.4gj, f = %.3g Hz, \\zeta = %.3g", real(c_l), s_sign, ...
            abs(imag(c_l)), abs(imag(c_l))/(2*pi), -real(c_l)/max(abs(c_l), eps));
        set(U.h_ring, "XData", real([c_l, conj(c_l)]), "YData", imag([c_l, conj(c_l)]));
    else
        rv_c = NaN(size(rm, 1), 1);
        s_mode = s_mode + " (not in this section)";
        set(U.h_ring, "XData", NaN, "YData", NaN);
    end
    G.BusColorData = rv_c;
    r_max = max(rv_c(isfinite(rv_c)));
    if ~isempty(r_max) && r_max > 0
        G.ColorLimits = [0 r_max];
    end
    title(G.ax(1), [U.sv_title(min(k, end)); s_mode]);

    % Table of the bus clicked
    if U.s_bus == ""
        return
    end
    lv = U.c_at{k} == U.s_bus;
    rv_v = NaN(nnz(lv), 1);
    if m <= size(P.rm_value, 2)
        rv_v = P.rm_value(lv, m);
    end
    U.h_tab.Data = [cellstr(P.sv_state(lv)), num2cell(rv_v)];
    U.h_info.Title = U.s_bus + " in " + sprintf("mode %d", m) + sprintf(" (sum %.3g)", sum(rv_v));
end
