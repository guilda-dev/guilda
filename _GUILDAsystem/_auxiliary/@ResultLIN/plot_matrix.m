function [G, G_block] = plot_matrix(obj, opt)
% Plot a matrix of the linear model by element, and a block of it with its values.
%
% What it shows: which variables of the model act on which. Each row is an equation (the
% derivative of a state, or the balance of a bus) and each column a variable; an entry is
% the coefficient of the column in the row (e.g. A(i, j) = d(dx_i/dt)/dx_j). The
% variables are grouped by their element (the owner tag: the component, controller or
% bus, tab_variable.Owner; a bus variable of the "DAE" belongs to its bus), so a diagonal
% block is the internal dynamics of one element and an off-diagonal block the coupling of
% two elements.
%
% Draws the matrix with GraphMatrix: with Display "pattern" (default) a red filled circle
% per nonzero entry and a hollow circle per zero entry, or log10|value| ("magnitude").
% The rows and columns are sorted by element (in the order of the first variable of each
% element, the order of the model within one); the tick labels are the element tags, one
% at the middle of each element's rows and columns; separator lines run between the
% elements and a box frames each diagonal block. An input or output that is not in
% tab_variable belongs to the group "(other)".
%
% Matrix chooses the matrix:
%
% - "A" (default), "B", "C", "D", "E": the matrix of get_ss(Type) (E dx/dt = A x + B u,
%   y = C x + D u) with the Input and Output of get_sys. An output without a name (the
%   states of "ODE") is named y1, y2, ....
% - "J": the full Jacobian of the DAE over [x; v], the state matrix A of
%   get_ss("DAE") in Port (the dynamic states, then the bus variables; rows: the state
%   equations, then the bus balance). Only a result of the network (output.s_layer
%   "PowerNetwork") has it; another layer stops with GUILDA:ResultLIN:NetworkOnly.
%
% Clicking anywhere in a block of the matrix (a circle, an empty cell, or a data tip on
% it: the graph turns on the data cursor mode) shows that block on the right, in G_block
% (GraphMatrix, Display "value", a line around each cell): its title is the element tag
% (or "row tag × column tag"), its rows and columns the variable names without the tag
% (delta, omega, Eq) and its cells the values. It starts with the first diagonal block; a
% gray line separates the two panels.
% With an axes as Parent only the matrix is drawn (G_block is empty). G.Display,
% G.Tolerance and G.ColorLimits change the view later. Form chooses the view as in get_ss
% ("hessian": the Hessian H of the energy function).
%
% A result with several sections (numel(rv_t) > 1) draws the matrix of every section:
% its samples are the sections at the times rv_t (the section numbers when rv_t is not
% finite and nondecreasing), switched by the playback bar or G.set_time(t), with the
% section in the title; the block follows (G and G_block are linked). It starts at
% Index. A section whose model cannot be formed (e.g. "ODE" with a singular Avv) is drawn
% empty (NaN); when no section has it, get_ss stops.
%
% <@Examples>
% ```matlab
% res = net.get_sys();
% [G, Gb] = res.plot_matrix();                   % A by element; click a block
% G = res.plot_matrix(Matrix="J", Type="DAE", Display="magnitude");
% G.Tolerance = 1e-8;                             % hide the tiny entries
% G.select("B001SG1");                            % the rows and columns of an element
% res = net.get_sys({sim, [0.5 1 2]});
% G = res.plot_matrix(Index=2);                   % three sections, the second first
% ```
%
% See also GraphMatrix, ResultLIN.get_ss, ResultLIN.get_reduced_matrix
    arguments (Input)
        obj
        opt.Matrix (1,1) string {mustBeMember(opt.Matrix, ["J","A","B","C","D","E"])} = "A"  % Matrix drawn: "A" ... "E" of get_ss(Type) or "J" (A of get_ss("DAE") over [x; v]).
        opt.Display (1,1) string {mustBeMember(opt.Display, ["pattern","magnitude"])} = "pattern"  % "pattern" (nonzero entries) or "magnitude" (log10|value|).
        opt.Type (1,1) string {mustBeMember(opt.Type, ["ODE","DAE"])} = obj.Type  % Model of "A" ... "E": "ODE" or "DAE"; the Type of the result when omitted.
        opt.Port (1,1) string {mustBeMember(opt.Port, ["PI","PQ","I"])} = default_port(obj)  % Bus port of the "DAE" (see get_ss); options.Port of the result when omitted.
        opt.Form (1,1) string {mustBeMember(opt.Form, ["descriptor","absorbed","hessian"])} = obj.Form  % View (see get_ss); res.Form when omitted.
        opt.Index (1,1) double {mustBeInteger, mustBePositive} = obj.Index  % Section shown first (1 ... numel(rv_t)); res.Index when omitted.
        opt.Parent = []                                        % Container (figure, uifigure, uipanel, uitab, uigridlayout) or axes/uiaxes to draw in; [] for a new figure.
    end
    arguments (Output)
        G        % The matrix (GraphMatrix), elements the groups of the rows ("rowgroup") and of the columns ("colgroup").
        G_block  % The block clicked (GraphMatrix, Display "value"); empty for an axes as Parent.
    end
    n_t = numel(obj.rv_t);
    if opt.Index > n_t
        error(msg("GUILDA:ResultLIN:IndexRange", string(n_t)))
    end
    l_network = isfield(obj.output, "s_layer") && obj.output.s_layer == "PowerNetwork";
    s_type = opt.Type;
    if opt.Matrix == "J"
        if ~l_network
            error(msg("GUILDA:ResultLIN:NetworkOnly", 'plot_matrix(Matrix="J")'))
        end
        s_type = "DAE";
    end
    c_nv = cell(1, 0);
    if opt.Matrix ~= "J"
        for str = ["Input","Output"]
            if isfield(obj.options, str)
                c_nv = [c_nv, {str, obj.options.(str)}]; %#ok<AGROW>
            end
        end
    end

    % The model of every section (an unusable section stays empty until a size is known)
    c_sys = cell(1, n_t);
    err_first = [];
    for k = 1:n_t
        try
            c_sys{k} = obj.get_ss(s_type, c_nv{:}, Port=opt.Port, Form=opt.Form, Index=k, Format="struct");
        catch err
            if isempty(err_first)
                err_first = err;
            end
        end
    end
    k_ok = find(~cellfun(@isempty, c_sys), 1);
    if isempty(k_ok)
        rethrow(err_first)
    end
    sys = c_sys{k_ok};
    s_field = opt.Matrix;
    if s_field == "J"
        s_field = "A";
    end
    c_matrix = cell(1, n_t);
    for k = 1:n_t
        if isempty(c_sys{k})
            c_matrix{k} = NaN(size(sys.(s_field)));
        else
            c_matrix{k} = c_sys{k}.(s_field);
        end
    end

    % Names and owners: the states (bus variables owned by their bus), the inputs and outputs by tab_variable
    tab = obj.tab_variable;
    sv_out = sys.OutputName;
    sv_out(sv_out == "") = "y" + find(sv_out == "");
    sct_side = struct();
    for s_side = ["x","u","y"]
        switch s_side
            case "x"
                sv_name = sys.StateName;
                sv_owner = state_owner(obj, sv_name);
            case "u"
                sv_name = sys.InputName;
            case "y"
                sv_name = sv_out;
        end
        if s_side ~= "x"
            [lv_known, iv_row] = ismember(sv_name, tab.Label);
            sv_owner = repmat("(other)", numel(sv_name), 1);
            sv_owner(lv_known) = tab.Owner(iv_row(lv_known));
        end
        sv_owner(sv_owner == "" | ismissing(sv_owner)) = "(other)";
        sct_side.(s_side) = struct("sv_name", sv_name, "sv_owner", sv_owner);
    end
    switch opt.Matrix
        case {"J","A","E"}, s_row = "x"; s_col = "x";
        case "B",           s_row = "x"; s_col = "u";
        case "C",           s_row = "y"; s_col = "x";
        case "D",           s_row = "y"; s_col = "u";
    end
    sv_label = struct("x", "state", "u", "input", "y", "output");
    if opt.Matrix == "J" || s_type == "DAE"
        sv_label.x = "variable";
    end

    % Groups: the owner tag of each variable, the rows and columns sorted by group (in the
    % order of the first variable of each)
    for s_side = ["x","u","y"]
        [~, ~, iv_g] = unique(sct_side.(s_side).sv_owner, "stable");
        [~, iv_perm] = sort(iv_g);
        sct_side.(s_side).iv_perm = iv_perm;
    end
    iv_r = sct_side.(s_row).iv_perm;
    iv_c = sct_side.(s_col).iv_perm;
    for k = 1:n_t
        c_matrix{k} = c_matrix{k}(iv_r, iv_c);
    end

    s_title = opt.Matrix + " (" + s_type;
    if s_type == "DAE" && l_network
        s_title = s_title + ", " + opt.Port;
    end
    if opt.Form ~= "descriptor"
        s_title = s_title + ", " + opt.Form;
    end
    s_title = s_title + ")";
    sct = struct();
    sct.c_matrix    = c_matrix;
    sct.sv_rowName  = sct_side.(s_row).sv_name(iv_r);
    sct.sv_colName  = sct_side.(s_col).sv_name(iv_c);
    sct.sv_rowGroup = sct_side.(s_row).sv_owner(iv_r);
    sct.sv_colGroup = sct_side.(s_col).sv_owner(iv_c);
    sct.l_frame     = true;
    sct.l_groupTicks = true;
    sct.s_pattern   = "circle";
    sct.s_title     = s_title;
    sct.s_rowLabel  = sv_label.(s_row);
    sct.s_colLabel  = sv_label.(s_col);
    if n_t > 1
        rv_sample = reshape(double(obj.rv_t), 1, []);
        if ~(all(isfinite(rv_sample)) && all(diff(rv_sample) >= 0))
            rv_sample = 1:n_t;
        end
        sct.rv_t = rv_sample;
        sct.s_sampleName  = "Section";
        sct.sv_sampleText = compose("section %d of %d, t = %g", (1:n_t)', n_t, reshape(double(obj.rv_t), [], 1))';
    end

    % Layout: the matrix, and the block clicked on the right (not for an axes as Parent)
    h_parent = opt.Parent;
    if isempty(h_parent)
        h_parent = figure("Color", "w");
    end
    G_block = GraphMatrix.empty;
    if isa(h_parent, "matlab.graphics.axis.Axes")
        G = GraphMatrix(sct, Parent=h_parent, Display=opt.Display);
    else
        c_fill = {"Units", "normalized", "Position", [0 0 1 1]};
        if isa(h_parent, "matlab.ui.container.GridLayout")
            c_fill = {};            % a cell of the grid sets its size
        end
        h_root = uipanel(h_parent, "BorderType", "none", c_fill{:}, ...
            "Tag", "GUILDA:ResultLIN:Matrix");
        if isprop(h_parent, "Color")
            h_root.BackgroundColor = h_parent.Color;
        end
        c_panel = {"BorderType", "none", "Units", "normalized", "BackgroundColor", h_root.BackgroundColor};
        G = GraphMatrix(sct, Parent=uipanel(h_root, c_panel{:}, "Position", [0 0 0.6 1]), Display=opt.Display);
        uipanel(h_root, "BorderType", "none", "Units", "normalized", "Position", [0.6 0.03 0.002 0.94], ...
            "BackgroundColor", [0.7 0.7 0.7], "Tag", "GUILDA:ResultLIN:MatrixSeparator");   % the line between the two panels
        G_block = GraphMatrix(block_data(sct, sct.sv_rowGroup(1), sct.sv_colGroup(1)), ...
            Parent=uipanel(h_root, c_panel{:}, "Position", [0.602 0 0.398 1]), Display="value");
        G.ElementClickedFcn = @(G, data) show_block(G, data, G_block, sct);
        if n_t > 1
            G.link(G_block);
        end
    end
    subtitle(G.ax(1), ["Red: nonzero (row: equation, column: variable), hollow: zero"; "Click a block to see its values"], "FontSize", 8);
    if n_t > 1
        G.set_time(sct.rv_t(opt.Index));
    end
end


function show_block(G, data, G_block, sct)
% Click on the matrix: the block of the group of the row and of the column of the cell clicked (ClickedCell), in G_block
    arguments (Input)
        G             % The matrix (GraphMatrix).
        data          % Event data (GraphEventData).
        G_block       % The graph of the block (GraphMatrix).
        sct struct    % Data of the matrix.
    end
    if data.Kind ~= "rowgroup" || ~isvalid(G_block)
        return
    end
    rv_cell = G.ClickedCell;
    if any(isnan(rv_cell))
        return
    end
    G_block.set_data(block_data(sct, sct.sv_rowGroup(rv_cell(1)), sct.sv_colGroup(rv_cell(2))));
    G_block.set_time(G.rv_t(G.i_time));
end


function sct_block = block_data(sct, s_row, s_col)
% Data of the block of the rows of group s_row and the columns of group s_col: the values written in the cells
    arguments (Input)
        sct struct          % Data of the matrix.
        s_row (1,1) string  % Group of the rows.
        s_col (1,1) string  % Group of the columns.
    end
    arguments (Output)
        sct_block struct    % Data of the graph of the block.
    end
    lv_r = sct.sv_rowGroup == s_row;
    lv_c = sct.sv_colGroup == s_col;
    sct_block = sct;
    sct_block.c_matrix    = cellfun(@(M) M(lv_r, lv_c), sct.c_matrix, "UniformOutput", false);
    sct_block.sv_rowName  = strip_tag(sct.sv_rowName(lv_r), s_row);
    sct_block.sv_colName  = strip_tag(sct.sv_colName(lv_c), s_col);
    sct_block.sv_rowGroup = sct.sv_rowGroup(lv_r);
    sct_block.sv_colGroup = sct.sv_colGroup(lv_c);
    sct_block.s_title     = s_row + " × " + s_col;
    if s_row == s_col
        sct_block.s_title = s_row;
    end
    sct_block.l_frame     = false;
    sct_block.l_groupTicks = false;
    sct_block.l_cellGrid  = true;
    sct_block.s_pattern   = "dot";
    sct_block.l_valueText = true;
end


function sv = strip_tag(sv, s_tag)
% Names of the variables without the tag of their owner: delta_B001SG1 -> delta
    arguments (Input)
        sv (:,1) string       % Names.
        s_tag (1,1) string    % Tag of the owner.
    end
    arguments (Output)
        sv (:,1) string       % Names without "_" + tag at their end.
    end
    lv = endsWith(sv, "_" + s_tag);
    sv(lv) = extractBefore(sv(lv), strlength(sv(lv)) - strlength(s_tag));
end
