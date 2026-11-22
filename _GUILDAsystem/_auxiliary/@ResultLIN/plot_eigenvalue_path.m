function G = plot_eigenvalue_path(obj, opt)
% Plot the largest real part and the smallest damping ratio of the eigenvalues over the sections.
%
% For a result with several sections (numel(rv_t) > 1, e.g. net.get_sys({sim, rv_t})),
% draws two panels against the sections: the largest real part of the finite generalized
% eigenvalues of (A, E) of get_ss(Type) of each section, and the smallest damping ratio
% -Re lambda / |lambda| of its oscillatory modes (|Im lambda| > 1e-6, as in get_mode; NaN
% for a section without one). A dotted line marks 0 in both panels. The first section
% whose largest real part exceeds Tolerance is marked by a vertical line in both panels,
% labeled "Hopf" when that eigenvalue is complex (a pair crosses the imaginary axis) and
% "instability" when it is real; none when every section is stable.
%
% The x axis is rv_t when its times are finite and nondecreasing, else the section numbers
% 1 ... n_t. Both panels are time panels: set_time(t) draws the cursor at the section
% nearest to t, so the chart links with plot_eigenvalue of the same result and with the
% graphs of the simulation (G.link). The playback bar shows the section.
%
% It returns the chart G (GraphChart) with two lines: "max_real" (panel 1) and
% "min_damping" (panel 2). A result with one section is an error.
%
% On a contribution result (sv_target nonempty, see get_contribution) the numbers are of
% the part alone and have no meaning for the whole system.
%
% <@Examples>
% ```matlab
% res = net.get_sys({sim, 0:0.05:2});
% G = res.plot_eigenvalue_path();
% G.link(res.plot_eigenvalue());               % the map follows the cursor
% ```
%
% See also ResultLIN.plot_eigenvalue, ResultLIN.get_mode, GraphChart
    arguments (Input)
        obj
        opt.Type (1,1) string {mustBeMember(opt.Type, ["ODE","DAE"])} = obj.Type  % Model whose eigenvalues are used: "ODE" or "DAE"; the Type of the result when omitted.
        opt.Tolerance (1,1) double {mustBeNonnegative} = 1e-6  % Real part above which a section is unstable.
        opt.Parent = []                                        % Container (figure, uifigure, uipanel, uitab, uigridlayout) to draw in; [] for a new figure.
    end
    arguments (Output)
        G  % The chart (GraphChart), lines "max_real" and "min_damping".
    end
    n_t = numel(obj.rv_t);
    if n_t < 2
        error(msg("GUILDA:ResultLIN:OneSection", "plot_eigenvalue_path", string(n_t)))
    end
    [c_e, rv_sample, sv_text] = section_eigenvalues(obj, opt.Type);
    rv_real = nan(n_t, 1);
    rv_zeta = nan(n_t, 1);
    cv_lead = nan(n_t, 1);
    for k = 1:n_t
        e = c_e{k};
        if isempty(e)
            continue
        end
        [rv_real(k), i_max] = max(real(e));
        cv_lead(k) = e(i_max);
        lv_osc = abs(imag(e)) > 1e-6;
        if any(lv_osc)
            rv_zeta(k) = min(-real(e(lv_osc)) ./ abs(e(lv_osc)));
        end
    end

    s_xlabel = "t [s]";
    if ~isequal(rv_sample, reshape(double(obj.rv_t), 1, []))
        s_xlabel = "Section";
    end
    sct = struct();
    sct.rv_t = rv_sample;
    sct.s_sampleName  = "Section";
    sct.sv_sampleText = "S" + extractAfter(sv_text, 1);
    sct.s_title = "Eigenvalues over the sections (" + opt.Type + ")";
    sct.sct_panel = struct("s_title", {"Largest real part", "Smallest damping ratio"}, ...
        "s_xlabel", s_xlabel, "s_ylabel", {"max Re \lambda [1/s]", "min \zeta"}, ...
        "l_time", true, "s_legendLocation", "none");
    sct.sct_series = struct("i_panel", {1, 2}, "rv_x", rv_sample, "rm_y", {rv_real, rv_zeta}, ...
        "sv_tag", {"max_real", "min_damping"}, "s_marker", ".", "r_markerSize", 12);
    sct.sct_refline = struct("i_panel", {1, 2}, "s_axis", "y", "r_value", 0, "s_label", "", ...
        "rv_color", [0.15 0.15 0.15], "s_lineStyle", ":");
    k_cross = find(rv_real > opt.Tolerance, 1);
    if ~isempty(k_cross)
        s_label = "instability";
        if abs(imag(cv_lead(k_cross))) > 1e-6
            s_label = "Hopf";
        end
        s_label = s_label + " (" + sv_text(k_cross) + ")";
        sct.sct_refline(end+1:end+2) = struct("i_panel", {1, 2}, "s_axis", "x", "r_value", rv_sample(k_cross), ...
            "s_label", {s_label, ""}, "rv_color", [0.85 0.1 0.1], "s_lineStyle", "--");
    end
    G = GraphChart(sct, Parent=opt.Parent);
end
