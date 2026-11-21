function G = plot_matrix(obj, opt)
% Plot a matrix of the linear model: its pattern or its magnitude, with the variable names.
%
% Draws one matrix of the model with GraphMatrix: the rows and columns carry the names of
% the variables (StateName, InputName, OutputName of get_ss) and thin separator lines
% between the owners of the variables (the tag of the component, controller or bus,
% tab_variable.Owner; a bus variable of the "DAE" belongs to its bus).
%
% Matrix chooses the matrix:
%
% - "J" (default): the full Jacobian of the DAE over [x; v], the state matrix A of
%   get_ss("DAE") in Port (the dynamic states, then the bus variables; rows: the state
%   equations, then the bus balance). Only a result of the network (output.s_layer
%   "PowerNetwork") has it; another layer stops with GUILDA:ResultLIN:NetworkOnly.
% - "A", "B", "C", "D", "E": the matrix of get_ss(Type) (E dx/dt = A x + B u,
%   y = C x + D u) with the Input and Output of get_sys. An output without a name (the
%   states of "ODE") is named y1, y2, ...; an input or output that is not in tab_variable
%   belongs to the group "(other)".
%
% Display is "pattern" (default: a dot at every nonzero entry) or "magnitude"
% (log10|value| with a colorbar); G.Display, G.Tolerance and G.ColorLimits change it
% later (GraphMatrix also has "value"). Form chooses the view as in get_ss ("hessian": the
% Hessian H of the energy function).
%
% A result with several sections (numel(rv_t) > 1) draws the matrix of every section:
% its samples are the sections at the times rv_t (the section numbers when rv_t is not
% finite and nondecreasing), switched by the playback bar or G.set_time(t), with the
% section in the title. It starts at Index. A section whose model cannot be formed (e.g.
% "ODE" with a singular Avv) is drawn empty (NaN); when no section has it, get_ss stops.
%
% <@Examples>
% ```matlab
% res = net.get_sys();
% G = res.plot_matrix();                          % pattern of the DAE Jacobian
% G = res.plot_matrix(Matrix="A", Type="ODE", Display="magnitude");
% G.Tolerance = 1e-8;                             % hide the tiny entries
% G.select("G1");                                 % the rows and columns of an owner
% res = net.get_sys({sim, [0.5 1 2]});
% G = res.plot_matrix(Index=2);                   % three sections, the second first
% ```
%
% See also GraphMatrix, ResultLIN.get_ss, ResultLIN.get_reduced_matrix
    arguments (Input)
        obj
        opt.Matrix (1,1) string {mustBeMember(opt.Matrix, ["J","A","B","C","D","E"])} = "J"  % Matrix drawn: "J" (A of get_ss("DAE") over [x; v]) or "A" ... "E" of get_ss(Type).
        opt.Display (1,1) string {mustBeMember(opt.Display, ["pattern","magnitude"])} = "pattern"  % "pattern" (nonzero entries) or "magnitude" (log10|value|).
        opt.Type (1,1) string {mustBeMember(opt.Type, ["ODE","DAE"])} = obj.Type  % Model of "A" ... "E": "ODE" or "DAE"; the Type of the result when omitted.
        opt.Port (1,1) string {mustBeMember(opt.Port, ["PI","PQ","I"])} = default_port(obj)  % Bus port of the "DAE" (see get_ss); options.Port of the result when omitted.
        opt.Form (1,1) string {mustBeMember(opt.Form, ["descriptor","absorbed","hessian"])} = obj.Form  % View (see get_ss); res.Form when omitted.
        opt.Index (1,1) double {mustBeInteger, mustBePositive} = obj.Index  % Section shown first (1 ... numel(rv_t)); res.Index when omitted.
        opt.Parent = []                                        % Container (figure, uifigure, uipanel, uitab, uigridlayout) or axes/uiaxes to draw in; [] for a new figure.
    end
    arguments (Output)
        G  % The graph (GraphMatrix), elements the owners of the rows ("rowgroup") and of the columns ("colgroup").
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
    sct.sv_rowName  = sct_side.(s_row).sv_name;
    sct.sv_colName  = sct_side.(s_col).sv_name;
    sct.sv_rowGroup = sct_side.(s_row).sv_owner;
    sct.sv_colGroup = sct_side.(s_col).sv_owner;
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
    G = GraphMatrix(sct, Parent=opt.Parent, Display=opt.Display);
    if n_t > 1
        G.set_time(sct.rv_t(opt.Index));
    end
end

