function sct_graph = mode_diagram(obj, opt, sct_spec)
% Figure of the eigenvalue map, the network diagram and a table, with the mode picked on
% the map (plot_participation, plot_eigenvector, plot_contribution).
%
% Layout in a borderless uipanel of opt.Parent: the eigenvalue map of plot_eigenvalue on
% the left, the diagram of section_diagram on the right and a table below it. Mode 1 (the
% first row of get_mode) is picked first. Picking a mode on the map: a data tip on an
% eigenvalue (a click while the data cursor mode of the figure is on, which the diagram
% turns on) or a click on its marker set (ElementClicked, with the CurrentPoint of the
% axes) picks the mode whose eigenvalue or its conjugate is nearest, marked by a black
% ring (Tag GUILDA:ResultLIN:PickedMode); the data tip shows lambda, f, zeta and the mode.
% Clicking a bus (or a component or link: its bus), also by its data tip, selects it and
% fills the table with the rows at that bus, without drawing the colors again; its data
% tip gets the value of the bus. The colors, their limits and the ring are drawn only
% when the mode or the section changes (ColorLimits is set only when it changes). With
% several sections the two graphs are linked and the TimeChangedFcn of the diagram shows
% the mode of the same number in the new section.
%
% sct_spec.fcn_section(sv_bus, sv_comp, sv_branch) returns the data of every section
% (1 x n_t struct), in the orders of the diagram:
%
% - cv_lambda (modes): the eigenvalue of each mode;
% - rm_bus (buses x modes): the color value of each bus (NaN: gray);
% - sm_busLabel (buses x modes, or empty): the label of each bus (LabelMode "user"),
%   else the bus tags;
% - rm_comp (components x modes, or empty), rm_branch (branches x modes, or empty): the
%   color values of the components and branches (empty: none);
% - sv_row, sv_rowBus (rows), rm_row (rows x modes): the rows of the table, their bus
%   ("": no bus) and their values: one column for one name in sv_column, else the
%   magnitude and phase in degrees, or the real and imaginary parts with
%   sct_spec.l_cartesian true.
% - sm_compLabel (components x modes, optional): the label of each component.
%
% With sct_spec.l_modeFree true the values do not depend on a mode: the data has one
% column (rm_bus, rm_comp, rm_branch, sm_*Label) and rm_row has one column per name in
% sv_column; the eigenvalue map is shown for reference and picks nothing.
%
% Other fields of sct_spec: s_name (start of the title), s_colorbar (label),
% s_explain (what the colors are: the subtitle of the diagram), s_value (the name of the
% value in the data tip of a bus), s_limit ("zero": [0 max] of the mode shown;
% "symmetric": [-m m]), sv_column (names of the value columns of the table), l_tableAll
% (true: the table shows every row until a bus is clicked), l_cartesian (optional: Re and
% Im of complex rows), l_modeFree and s_quantity (optional: the name of a mode-free
% quantity, in the titles).
    arguments (Input)
        obj    ResultLIN          % The result (of the network).
        opt    struct             % Options of the method: Type, Index, Parent.
        sct_spec (1,1) struct     % What is shown (see above).
    end
    arguments (Output)
        sct_graph struct          % Eigenvalue (GraphChart), Diagram (GraphNetDiagram) and Table (uitable).
    end
    % Layout: the eigenvalues on the left, the diagram and the table on the right
    h_parent = opt.Parent;
    if isempty(h_parent)
        h_parent = figure("Color", "w");
    end
    c_fill = {"Units", "normalized", "Position", [0 0 1 1]};
    if isa(h_parent, "matlab.ui.container.GridLayout")
        c_fill = {};                % a cell of the grid sets its size
    end
    h_root = uipanel(h_parent, "BorderType", "none", c_fill{:}, ...
        "Tag", "GUILDA:ResultLIN:ModeFigure");
    if isprop(h_parent, "Color")
        h_root.BackgroundColor = h_parent.Color;
    end
    c_panel = {"BorderType", "none", "Units", "normalized", "BackgroundColor", h_root.BackgroundColor};
    h_eig  = uipanel(h_root, c_panel{:}, "Position", [0 0 0.42 1]);
    h_net  = uipanel(h_root, c_panel{:}, "Position", [0.42 0.28 0.58 0.72]);
    s_hint = "Click a bus";
    if sct_spec.l_tableAll
        s_hint = "All elements (click a bus)";
    end
    h_info = uipanel(h_root, "Units", "normalized", "Position", [0.43 0.01 0.56 0.26], "Title", s_hint);
    h_tab  = uitable(h_info, "Units", "normalized", "Position", [0 0 1 1], "Data", cell(0, 1 + numel(sct_spec.sv_column)), ...
        "ColumnName", cellstr(["Variable", sct_spec.sv_column]), "RowName", {}, "Tag", "GUILDA:ResultLIN:ModeTable");

    G_eig = obj.plot_eigenvalue(Type=opt.Type, Index=opt.Index, Parent=h_eig);
    l_free = isfield(sct_spec, "l_modeFree") && sct_spec.l_modeFree;
    s_hint = "Click an eigenvalue to pick its mode";
    if l_free
        s_hint = "The eigenvalues of the DAE, for reference";
    end
    subtitle(G_eig.ax(1), [string(G_eig.ax(1).Subtitle.String); s_hint], "FontSize", 8);
    [G_net, sv_bus, sv_comp, sv_title] = section_diagram(obj, sct_spec.s_name, ...
        {"ColorbarLabel", sct_spec.s_colorbar, "Parent", h_net});
    tab = G_net.tab_element;
    sv_branch = tab.Tag(tab.Kind == "branch");
    sct_sec = sct_spec.fcn_section(sv_bus, sv_comp, sv_branch);
    h_root.UserData = struct("sct_sec", sct_sec, "sct_spec", sct_spec, "i_mode", 1, "s_bus", "", ...
        "sv_title", sv_title, "G_eig", G_eig, "G_net", G_net, "h_tab", h_tab, "h_info", h_info, ...
        "h_ring", line(G_eig.ax(1), NaN, NaN, "LineStyle", "none", "Marker", "o", "MarkerSize", 12, ...
        "LineWidth", 1.5, "Color", "k", "HitTest", "off", "PickableParts", "none", "HandleVisibility", "off", ...
        "Tag", "GUILDA:ResultLIN:PickedMode"));

    G_eig.ElementClickedFcn = @(G, data) pick_mode(h_root, G.ax(1).CurrentPoint(1, 1:2));
    G_net.ElementClickedFcn = @(G, data) pick_bus(h_root, data);
    if numel(obj.rv_t) > 1
        G_net.TimeChangedFcn = @(G, data) show_colors(h_root);
        G_net.set_time(G_net.rv_t(opt.Index));
        G_eig.link(G_net);
    end
    show_colors(h_root);
    sct_graph = struct("Eigenvalue", G_eig, "Diagram", G_net, "Table", h_tab);
end


function pick_mode(h_root, rv_p)
% Pick the mode whose eigenvalue or its conjugate is nearest to the point rv_p of the map
    arguments (Input)
        h_root            % Panel of the figure, with the data in UserData.
        rv_p (1,2) double % Point [Re Im] on the eigenvalue map.
    end
    if ~isvalid(h_root)
        return
    end
    U = h_root.UserData;
    if isfield(U.sct_spec, "l_modeFree") && U.sct_spec.l_modeFree
        return
    end
    cv_lambda = U.sct_sec(U.G_net.i_time).cv_lambda;
    if isempty(cv_lambda)
        return
    end
    c_p = complex(rv_p(1), rv_p(2));
    [~, m] = min(min(abs(cv_lambda - c_p), abs(conj(cv_lambda) - c_p)));
    if m == U.i_mode
        return
    end
    U.i_mode = m;
    h_root.UserData = U;
    show_colors(h_root);
end


function pick_bus(h_root, data)
% Click (or data tip) on the diagram: a bus, or the bus of a component or link, for the table; the colors stay
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
            sv_bus = U.G_net.tab_element.Tag(U.G_net.tab_element.Kind == "bus");
            sv_bus = sv_bus(arrayfun(@(b) startsWith(data.Tag, b), sv_bus));
            if ~isempty(sv_bus)
                [~, i] = max(strlength(sv_bus));
                s_bus = sv_bus(i);
            end
    end
    if s_bus == "" || s_bus == U.s_bus
        return
    end
    U.s_bus = s_bus;
    h_root.UserData = U;
    U.G_net.select(s_bus);
    show_table(h_root);
end


function txt = mode_text(h_root, event, txt)
% Data tip of the figure: an eigenvalue picks its mode and shows it; a bus gets its value
    arguments (Input)
        h_root  % Panel of the figure, with the data in UserData.
        event   % Event data of the data tip (Target, Position).
        txt     % Text of the data tip before (the diagram, or "No Data").
    end
    arguments (Output)
        txt     % Text of the data tip.
    end
    U = h_root.UserData;
    h = event.Target;
    rv_p = event.Position;
    if isequal(ancestor(h, "axes"), U.G_eig.ax(1))
        c_l = complex(rv_p(1), rv_p(2));
        txt = {sprintf('\\lambda = %.4g %+.4gj [1/s]', real(c_l), imag(c_l)), ...
               sprintf('f = %.3g Hz, \\zeta = %.3g', abs(imag(c_l))/(2*pi), -real(c_l)/max(abs(c_l), eps))};
        if ~(isfield(U.sct_spec, "l_modeFree") && U.sct_spec.l_modeFree)
            pick_mode(h_root, rv_p(1:2));
            U = h_root.UserData;
            txt{end+1} = sprintf('mode %d (picked)', U.i_mode);
        end
        return
    end
    if ~(isprop(h, "UserData") && isstruct(h.UserData) && isfield(h.UserData, "Type") && h.UserData.Type == "Bus")
        return
    end
    i = h.UserData.Index;
    rv_c = U.G_net.BusColorData;
    if i <= numel(rv_c)
        txt = [cellstr(string(txt(:)')), {char(U.sct_spec.s_value + ": " + sprintf("%.4g", rv_c(i)))}];
    end
end


function show_colors(h_root)
% Colors, labels, title, ring and table of the mode picked in the section shown (on a change of the mode or section; also the TimeChangedFcn of the diagram)
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
    S = U.sct_sec(k);
    l_free = isfield(U.sct_spec, "l_modeFree") && U.sct_spec.l_modeFree;
    l_mode = l_free || m <= numel(S.cv_lambda);
    s_mode = sprintf("mode %d", m);
    if l_free
        s_mode = U.sct_spec.s_quantity;
    elseif l_mode
        c_l = S.cv_lambda(m);
        s_sign = "+";
        if imag(c_l) < 0
            s_sign = "-";
        end
        s_mode = s_mode + sprintf(": \\lambda = %.4g %s %.4gj, f = %.3g Hz, \\zeta = %.3g", real(c_l), s_sign, ...
            abs(imag(c_l)), abs(imag(c_l))/(2*pi), -real(c_l)/max(abs(c_l), eps));
        set(U.h_ring, "XData", real([c_l, conj(c_l)]), "YData", imag([c_l, conj(c_l)]));
    else
        s_mode = s_mode + " (not in this section)";
        set(U.h_ring, "XData", NaN, "YData", NaN);
    end

    % Colors of the mode (NaN when the section has fewer modes) and their limits, set when they change
    rv_bus = column_of(S.rm_bus, m, size(S.rm_bus, 1));
    G.BusColorData = rv_bus;
    rv_all = rv_bus;
    if ~isempty(S.rm_comp)
        G.ComponentColorData = column_of(S.rm_comp, m, size(S.rm_comp, 1));
        rv_all = [rv_all; G.ComponentColorData];
    end
    if ~isempty(S.rm_branch)
        G.BranchColorData = column_of(S.rm_branch, m, size(S.rm_branch, 1));
        rv_all = [rv_all; G.BranchColorData];
    end
    r_max = max(abs(rv_all(isfinite(rv_all))));
    if ~isempty(r_max) && r_max > 0
        rv_lim = [0 r_max];
        if U.sct_spec.s_limit == "symmetric"
            rv_lim = [-r_max r_max];
        end
        if ~isequal(G.ColorLimits, rv_lim)
            G.ColorLimits = rv_lim;
        end
    end
    l_compLabel = isfield(S, "sm_compLabel") && ~isempty(S.sm_compLabel);
    if ~isempty(S.sm_busLabel) || l_compLabel
        sv_label = G.tab_element.Tag(G.tab_element.Kind == "bus");
        if l_mode && ~isempty(S.sm_busLabel)
            sv_label = S.sm_busLabel(:, m);
        end
        G.BusLabel = sv_label;
        sv_label = strings(nnz(G.tab_element.Kind == "component"), 1);
        if l_mode && l_compLabel
            sv_label = S.sm_compLabel(:, m);
        end
        G.ComponentLabel = sv_label;
        G.LabelMode = "user";
    end
    title(G.ax(1), [U.sv_title(min(k, end)); s_mode]);
    subtitle(G.ax(1), U.sct_spec.s_explain, "FontSize", 8);
    % the data tips of the figure (wrapped again when a graph has set its own)
    datatip_wrap(ancestor(h_root, "figure"), h_root, @(event, txt) mode_text(h_root, event, txt));
    show_table(h_root);
end


function show_table(h_root)
% Table: the rows of the bus clicked (every row before a click with l_tableAll) in the mode and section shown
    arguments (Input)
        h_root  % Panel of the figure, with the data in UserData.
    end
    U = h_root.UserData;
    k = U.G_net.i_time;
    m = U.i_mode;
    S = U.sct_sec(k);
    if U.s_bus == "" && ~U.sct_spec.l_tableAll
        return
    end
    lv = true(numel(S.sv_row), 1);
    s_title = "All elements";
    if U.s_bus ~= ""
        lv = S.sv_rowBus == U.s_bus;
        s_title = U.s_bus;
    end
    if isfield(U.sct_spec, "l_modeFree") && U.sct_spec.l_modeFree
        U.h_tab.Data = [cellstr(S.sv_row(lv)), num2cell(S.rm_row(lv, :))];
        U.h_info.Title = s_title + ": " + U.sct_spec.s_quantity;
        return
    end
    cv = column_of(S.rm_row, m, numel(S.sv_row));
    cv = cv(lv);
    if isfield(U.sct_spec, "l_cartesian") && U.sct_spec.l_cartesian
        c_data = [cellstr(S.sv_row(lv)), num2cell(real(cv)), num2cell(imag(cv))];
        s_sum = sprintf(" (sum %.4g %+.4gj)", real(sum(cv)), imag(sum(cv)));
    elseif numel(U.sct_spec.sv_column) == 1
        c_data = [cellstr(S.sv_row(lv)), num2cell(cv)];
        s_sum = sprintf(" (sum %.3g)", sum(cv));
    else
        c_data = [cellstr(S.sv_row(lv)), num2cell(abs(cv)), num2cell(rad2deg(angle(cv)))];
        s_sum = "";
    end
    U.h_tab.Data = c_data;
    U.h_info.Title = s_title + " in " + sprintf("mode %d", m) + s_sum;
end


function cv = column_of(rm, m, n_row)
% Column m of rm, or NaN when it has fewer columns
    arguments (Input)
        rm               % Values (rows x modes).
        m (1,1) double   % Mode.
        n_row (1,1) double  % Number of rows.
    end
    arguments (Output)
        cv (:,1)         % Column m (NaN: no such mode).
    end
    cv = NaN(n_row, 1);
    if m <= size(rm, 2)
        cv = rm(:, m);
    end
end
