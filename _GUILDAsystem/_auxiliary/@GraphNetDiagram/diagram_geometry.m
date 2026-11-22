function sct_g = diagram_geometry(obj)
% Positions of the buses and components and paths of the branches and links, with heights.
%
% A bus is at its center (X, Y) and its height z (BusHeightMode of the sample shown; 0
% for "none" and for NaN values). A branch runs from the point where it meets its "from"
% bus through its bend points (Path) to the point where it meets its "to" bus; its height
% goes linearly along the path, by the length in x, y, from the height of one end to the
% other (rv_frac of each point: the length up to it over the whole length). A component
% is at the center of its bus + (DX, DY), and its link runs through its bend points
% (relative to the bus center) to the point on its bus, all at the height of its bus. A
% branch or a link meets a bar on its center line at its offset (NaN: the nearest bend
% point, or the component, projected onto the bar; no hint: the center), within the bar.
% In 3D (Dimension "3D", BusHeightMode other than "none") the heights are scaled about
% the reference value ref (|V| = 1 for "V", else 0): z = ref + scale*(value - ref), with
% scale such that the values of every sample of the state and ref span a quarter of span
% (1 when they are all equal). The heights then read the same at every sample and in any
% network, small (|V|) or large (P); the z axis of create_scene is labeled in the values.
% 2D keeps z = value.
% d0 is the median length of the branch paths (no branch: 0.1 times the larger side of
% the box of the bus centers, or 0.1); span is that larger side (at least eps).
    arguments (Input)
        obj
    end
    arguments (Output)
        sct_g (1,1) struct  % Fields rm_bus (n_bus x 3), rm_comp (n_comp x 3), c_branch, c_branchFrac (n_branch x 1 cells), c_link (n_comp x 1 cell), d0, r_span, sct_height (3D heights: Ref, Scale, Lim; empty otherwise).
    end
    tab_g = obj.tab_bus.graph;
    n_bus = obj.n_bus;
    rm_xy = zeros(n_bus, 2);
    if n_bus > 0
        rm_xy = tab_g{:, ["X", "Y"]};
    end

    % Heights of the buses at the sample shown
    switch obj.BusHeightMode
        case "V";     rv_z = abs(obj.cv_Vbus);
        case "angle"; rv_z = angle(obj.cv_Vbus);
        case "Vimag"; rv_z = imag(obj.cv_Vbus);
        case "P";     rv_z = obj.rv_Pbus;
        case "Q";     rv_z = obj.rv_Qbus;
        otherwise;    rv_z = zeros(n_bus, 1);
    end
    rv_z = real(rv_z(:));
    rv_z(isnan(rv_z)) = 0;             % no state (topology only): flat
    if isempty(rv_z)
        rv_z = zeros(n_bus, 1);
    end
    r_span = max([max(rm_xy(:, 1), [], 1) - min(rm_xy(:, 1), [], 1), ...
                  max(rm_xy(:, 2), [], 1) - min(rm_xy(:, 2), [], 1), eps]);

    % 3D: the heights over all samples and the reference (|V| = 1, else 0) span a quarter
    % of span, about the reference: z = ref + scale*(value - ref)
    sct_height = struct.empty;
    if obj.Dimension == "3D" && obj.BusHeightMode ~= "none"
        r_ref = double(obj.BusHeightMode == "V");
        cm_V  = obj.sct_state.cm_Vbus;
        switch obj.BusHeightMode
            case "V";     rm_z = abs(cm_V);
            case "angle"; rm_z = angle(cm_V);
            case "Vimag"; rm_z = imag(cm_V);
            otherwise
                cm_I0 = obj.sct_state.cm_Icomp;
                cm_I0(isnan(cm_I0)) = 0;
                cm_S  = cm_V .* conj(full(sparse(obj.tab_component.bus, 1:obj.n_component, 1, n_bus, obj.n_component) * cm_I0));
                rm_z  = real(cm_S);
                if obj.BusHeightMode == "Q"
                    rm_z = imag(cm_S);
                end
        end
        rv_all  = [real(rm_z(isfinite(rm_z))); rv_z; r_ref];
        rv_lim  = [min(rv_all), max(rv_all)];
        r_scale = 1;
        if diff(rv_lim) > 0
            r_scale = 0.25*r_span/diff(rv_lim);
        end
        rv_z = r_ref + r_scale*(rv_z - r_ref);
        sct_height = struct("Ref", r_ref, "Scale", r_scale, "Lim", rv_lim);
    end
    rm_bus = [rm_xy, rv_z];

    % Bars: axis along the bar (1: x, 2: y; 0: a point) and half length
    sv_shape = tab_g.Shape;
    iv_axis  = (sv_shape == "hbar") + 2*(sv_shape == "vbar");
    rv_half  = zeros(n_bus, 1);
    if n_bus > 0
        rv_half = tab_g.Length/2;
    end

    % Branches
    n_br = obj.n_branch;
    c_branch = cell(n_br, 1);
    c_frac   = cell(n_br, 1);
    rv_len   = zeros(n_br, 1);
    if n_br > 0                        % columns read once (a table row per branch is slow)
        tab_e   = obj.tab_branch.graph;
        sv_path = tab_e.Path;
        rv_from = tab_e.FromOffset;
        rv_to   = tab_e.ToOffset;
    end
    for k = 1:n_br
        rm_mid = tools.layout_parse_path(sv_path(k));
        iv_end = obj.im_edge(:, k);
        rm_p   = [attach(iv_end(1), rv_from(k), rm_mid(1:min(end, 1), :)); rm_mid; ...
                  attach(iv_end(2), rv_to(k),   rm_mid(max(end, 1):end, :))];
        rv_cum = [0; cumsum(vecnorm(diff(rm_p, 1, 1), 2, 2))];
        rv_len(k) = rv_cum(end);
        rv_f = zeros(size(rv_cum));
        if rv_cum(end) > 0
            rv_f = rv_cum / rv_cum(end);
        end
        rv_f(end) = 1;
        c_frac{k}   = rv_f;
        c_branch{k} = [rm_p, rv_z(iv_end(1)) + rv_f*(rv_z(iv_end(2)) - rv_z(iv_end(1)))];
    end

    % Components and their links
    n_c = obj.n_component;
    rm_comp = zeros(n_c, 3);
    c_link  = cell(n_c, 1);
    if n_c > 0
        tab_c   = obj.tab_component.graph;
        rm_d    = [tab_c.DX, tab_c.DY];
        sv_path = tab_c.Path;
        rv_off  = tab_c.Offset;
        iv_bus  = obj.tab_component.bus;
    end
    for c = 1:n_c
        i_bus = iv_bus(c);
        rm_comp(c, :) = [rm_xy(i_bus, :) + rm_d(c, :), rv_z(i_bus)];
        rm_mid = tools.layout_parse_path(sv_path(c)) + rm_xy(i_bus, :);   % relative to the bus center
        rm_p   = [rm_comp(c, 1:2); rm_mid];
        rm_p   = [rm_p; attach(i_bus, rv_off(c), rm_p(end, :))]; %#ok<AGROW>
        c_link{c} = [rm_p, repmat(rv_z(i_bus), size(rm_p, 1), 1)];
    end

    if n_br > 0
        d0 = median(rv_len);
    else
        d0 = 0.1*r_span*(r_span > eps);
    end
    if ~(d0 > 0)
        d0 = 0.1;
    end
    sct_g = struct("rm_bus", rm_bus, "rm_comp", rm_comp, "c_branch", {c_branch}, ...
                   "c_branchFrac", {c_frac}, "c_link", {c_link}, "d0", d0, "r_span", r_span, ...
                   "sct_height", {sct_height});

    function rv_p = attach(i_bus, r_offset, rm_hint)
    % Point [x y] where a branch or a link meets bus i_bus (see above).
        rv_p = rm_xy(i_bus, :);
        k_ax = iv_axis(i_bus);
        if k_ax == 0
            return
        end
        d = r_offset;
        if isnan(d)
            d = 0;
            if ~isempty(rm_hint)
                d = rm_hint(1, k_ax) - rv_p(k_ax);
            end
        end
        rv_p(k_ax) = rv_p(k_ax) + min(max(d, -rv_half(i_bus)), rv_half(i_bus));
    end
end
