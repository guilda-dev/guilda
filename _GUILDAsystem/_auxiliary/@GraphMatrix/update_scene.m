function update_scene(obj, k)
% Draw sample k in the Display chosen: the dots of the pattern, or the image with its colormap, limits and colorbar; the title shows the time.
%
% The automatic color limits are taken over all samples once per Tolerance and kept. A
% NaN in ColorLimits takes that limit from them; a pair that is not increasing falls back
% to the automatic limits.
    arguments (Input)
        obj
        k (1,1) double  % Index of the sample.
    end
    d   = obj.sct_data;
    plt = obj.sct_plt;
    ax  = obj.ax(1);
    M   = d.c_matrix{k};
    r_tol = obj.Tolerance;

    if obj.Display == "pattern"
        [iv_i, iv_j] = find(abs(M) > r_tol);
        set(plt.Pattern, "XData", reshape(iv_j, 1, []), "YData", reshape(iv_i, 1, []), "Visible", "on");
        if d.s_pattern == "circle"     % the zero entries (not NaN) as hollow circles
            [iv_i, iv_j] = find(~(abs(M) > r_tol) & ~isnan(M));
            set(plt.Zero, "XData", reshape(iv_j, 1, []), "YData", reshape(iv_i, 1, []), "Visible", "on");
        end
        set(plt.Image, "Visible", "off");
        set(plt.Colorbar, "Visible", "off");
    else
        % Automatic limits over all samples, for this Tolerance
        if isempty(obj.sct_limitAuto) || obj.sct_limitAuto.r_tol ~= r_tol
            r_min = Inf;
            r_max = 0;
            for j = 1:numel(d.c_matrix)
                rv_a = abs(nonzeros(d.c_matrix{j}));
                rv_a = rv_a(rv_a > r_tol & isfinite(rv_a));
                r_min = min([r_min; rv_a]);
                r_max = max([r_max; rv_a]);
            end
            rv_mag = [0 1];
            rv_val = [-1 1];
            if r_max > 0
                rv_mag = log10([r_min r_max]);
                if rv_mag(2) - rv_mag(1) < 1e-12
                    rv_mag = rv_mag + [-0.5 0.5];
                end
                rv_val = [-r_max r_max];
            end
            obj.sct_limitAuto = struct("r_tol", r_tol, "rv_magnitude", rv_mag, "rv_value", rv_val);
        end

        C = full(M);
        l_show = abs(C) > r_tol;                        % NaN is not shown
        if obj.Display == "magnitude"
            C = log10(abs(C));
            rv_lim = obj.sct_limitAuto.rv_magnitude;
            rm_map = parula(256);
            s_label = "log_{10}|value|";
        else
            rv_lim = obj.sct_limitAuto.rv_value;
            rv_s = linspace(0, 1, 128)';
            rm_map = [[rv_s, rv_s, ones(128, 1)]; [ones(128, 1), flipud(rv_s), flipud(rv_s)]];   % blue - white - red
            s_label = "value";
        end
        C(~l_show) = NaN;
        l_set = isfinite(obj.ColorLimits);
        rv_lim(l_set) = obj.ColorLimits(l_set);
        if ~(rv_lim(1) < rv_lim(2))
            rv_lim = obj.sct_limitAuto.("rv_" + obj.Display);
        end
        if isempty(C)
            set(plt.Image, "CData", NaN, "AlphaData", 0, "Visible", "off");
        else
            set(plt.Image, "CData", C, "AlphaData", double(l_show), "Visible", "on");
        end
        set([plt.Pattern, plt.Zero], "Visible", "off");
        colormap(ax, rm_map);
        ax.CLim = rv_lim;
        set(plt.Colorbar, "Visible", "on");
        plt.Colorbar.Label.String = s_label;
    end

    % Values written in the cells (l_valueText): the entries above Tolerance, up to 900
    delete(plt.Text(isgraphics(plt.Text)));
    obj.sct_plt.Text = gobjects(0, 1);
    if d.l_valueText
        [iv_i, iv_j] = find(abs(M) > r_tol);
        rv_v = M(sub2ind(size(M), iv_i, iv_j));
        if numel(rv_v) <= 900
            obj.sct_plt.Text = text(ax, iv_j, iv_i, compose("%.3g", full(rv_v)), "HorizontalAlignment", "center", ...
                "FontSize", 8, "HitTest", "off", "PickableParts", "none", "Interpreter", "none", "Tag", "Value");
        end
    end

    % Title: the title of the data and the sample (not for one sample at t = 0 without a text)
    s_title = d.s_title;
    if numel(obj.rv_t) > 1 || obj.rv_t(1) ~= 0 || ~isempty(obj.sv_sampleText)
        s_time = obj.sample_text(k, "t = %.4g s");
        s_title = join([s_title(s_title ~= ""), s_time], ", ");
    end
    title(ax, s_title, "Interpreter", "none");
end
