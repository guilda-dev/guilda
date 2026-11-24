function G = plot_eigenvalue(obj, opt)
% Plot the eigenvalue map.
%
% Draws the eigenvalue map of the linear model: the finite generalized eigenvalues of
% (A, E) of get_ss(Type) in the complex plane, with the imaginary axis (the port
% model for an object-level result, see ResultLIN). It needs no toolbox.
% Eigenvalues with a positive real part (larger than Tolerance) are drawn in red.
% Index chooses the section shown first (default res.Index; see ResultLIN). The only
% figure of the analysis besides plot_eigenvalue_path: get_sys draws none (its PlotFcn is
% a live display during the linearization).
%
% It returns the chart G (GraphChart) with two marker sets of filled dots ("." markers,
% MarkerSize 16): "stable" (the eigenvalues with a real part up to Tolerance, blue) and
% "unstable" (red; a set without points when the model is stable). The imaginary axis is fixed drawing, not an element.
% The subtitle says what the map shows: each eigenvalue lambda is a mode e^(lambda t) of
% the linear model; Re lambda < 0 decays (its decay rate), Im lambda / 2 pi is its
% frequency [Hz], and the damping ratio is -Re lambda / |lambda|.
%
% A result with several sections (numel(rv_t) > 1) gives a chart of every section: its
% samples are the sections, at the times rv_t (the section numbers when rv_t is not
% finite and nondecreasing), and G.set_time(t) shows the eigenvalues of the section
% nearest to t, with the section in the title (also in the panel of show_controls). It
% starts at Index. The axis limits hold the eigenvalues of every section, so that
% G.animate() and a link to the graphs of the same simulation (G.link(S)) show the
% eigenvalues move.
%
% On a contribution result (sv_target nonempty, see get_contribution) the numbers are of
% the part alone and have no meaning for the whole system.
%
% <@Examples>
% ```matlab
% G = res.plot_eigenvalue();
% G.set_style("unstable", MarkerSize=12);
% res = net.get_sys({sim, 0:0.1:2});           % sections along a simulation
% G = res.plot_eigenvalue();
% G.link(sim.plot_spring_model());             % the eigenvalues follow the animation
% ```
%
% See also GraphChart, ResultLIN.get_ss, ResultLIN.plot_eigenvalue_path
    arguments (Input)
        obj
        opt.Type (1,1) string {mustBeMember(opt.Type, ["ODE","DAE"])} = obj.Type  % Model whose eigenvalues are drawn: "ODE" or "DAE"; the Type of the result when omitted.
        opt.Tolerance (1,1) double {mustBeNonnegative} = 1e-6  % Real part above which an eigenvalue is drawn as unstable.
        opt.Parent = []                                        % Container (figure, uifigure, uipanel, uitab, uigridlayout) or axes/uiaxes to draw in; [] for a new figure.
        opt.Index (1,1) double {mustBeInteger, mustBePositive} = obj.Index  % Section shown first (1 ... numel(rv_t)); res.Index when omitted.
    end
    arguments (Output)
        G  % The chart (GraphChart), marker sets "stable" and "unstable".
    end
    n_t = numel(obj.rv_t);
    if opt.Index > n_t
        error(msg("GUILDA:ResultLIN:IndexRange", string(n_t)))
    end
    if ~(isfield(obj.output, "s_layer") && obj.output.s_layer == "PowerNetwork")
        s_title = "Eigenvalues (" + obj.output.s_layer + ")";
    else
        s_title = "Eigenvalues (" + opt.Type + ")";
    end
    if isfield(obj.output, "l_equilibrium") && ~obj.output.l_equilibrium
        s_title = s_title + " at the given point";
    end

    s_explain = "Each dot is a mode e^{\lambda t}: Re \lambda < 0 decays, Im \lambda/2\pi is its frequency; red: Re \lambda > " + opt.Tolerance;
    sct = struct();
    sct.sct_refline = struct("s_axis", "x", "r_value", 0, "rv_color", [0.15 0.15 0.15], "s_lineStyle", ":");
    if n_t == 1
        sys = obj.get_ss(opt.Type, Index=opt.Index, Format="struct");
        e = eig(full(sys.A), full(sys.E));
        e = e(isfinite(e));
        lv_unstable = real(e) > opt.Tolerance;
        sct.sct_panel  = struct("s_title", s_title, "s_xlabel", "Real", "s_ylabel", "Imag", "s_legendLocation", "none");
        sct.sct_series = struct("s_type", "marker", "s_marker", ".", "r_markerSize", 16, ...
            "rv_x",     {real(e(~lv_unstable)), real(e(lv_unstable))}, ...
            "rm_y",     {imag(e(~lv_unstable)), imag(e(lv_unstable))}, ...
            "sv_tag",   {"stable", "unstable"}, ...
            "rm_color", {[0 0.30 0.80], [0.85 0 0]});
        G = GraphChart(sct, Parent=opt.Parent);
        subtitle(G.ax(1), s_explain, "FontSize", 8);
        return
    end

    % Every section: the eigenvalues stacked, each row with the sample of its section
    [c_e, rv_sample, sv_text] = section_eigenvalues(obj, opt.Type);
    e = vertcat(complex(zeros(0, 1)), c_e{:});
    iv_section = repelem(1:n_t, cellfun(@numel, c_e))';
    lv_unstable = real(e) > opt.Tolerance;
    rv_xlim = pad_limits([real(e); 0]);
    rv_ylim = pad_limits(imag(e));
    sct.rv_t = rv_sample;
    sct.s_sampleName  = "Section";
    sct.sv_sampleText = "S" + extractAfter(sv_text, 1);
    sct.sct_panel  = struct("s_title", s_title + " (" + sv_text + ")", "s_xlabel", "Real", "s_ylabel", "Imag", ...
        "s_legendLocation", "none", "rv_xlim", rv_xlim, "rv_ylim", rv_ylim);
    sct.sct_series = struct("s_type", "marker", "s_marker", ".", "r_markerSize", 16, ...
        "rv_x",      {real(e(~lv_unstable)), real(e(lv_unstable))}, ...
        "rm_y",      {imag(e(~lv_unstable)), imag(e(lv_unstable))}, ...
        "iv_sample", {iv_section(~lv_unstable), iv_section(lv_unstable)}, ...
        "sv_tag",    {"stable", "unstable"}, ...
        "rm_color",  {[0 0.30 0.80], [0.85 0 0]});
    G = GraphChart(sct, Parent=opt.Parent);
    subtitle(G.ax(1), s_explain, "FontSize", 8);
    G.set_time(rv_sample(opt.Index));
end


function rv = pad_limits(rv_v)
% Limits that hold the values with a margin of 5 % ([] when they are all equal: automatic)
    arguments (Input)
        rv_v (:,1) double  % Values.
    end
    arguments (Output)
        rv  % [min max] with the margin, or [].
    end
    r_lo = min(rv_v);
    r_hi = max(rv_v);
    rv = [];
    if ~isempty(rv_v) && r_hi > r_lo
        r_pad = 0.05 * (r_hi - r_lo);
        rv = [r_lo - r_pad, r_hi + r_pad];
    end
end
