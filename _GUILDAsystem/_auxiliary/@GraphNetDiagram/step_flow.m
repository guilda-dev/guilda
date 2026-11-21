function step_flow(obj, r_dt)
% Advance the flow dots by r_dt seconds and draw them (2D; the timer, export_video and tests).
%
% Each element moves its phase by its speed times r_dt, modulo the spacing Delta =
% 0.25*d0. Its dots lie at the lengths phase + k*Delta (k = 0, 1, ...) along its path,
% measured from its "from" end (from the component for a link), or from the other end
% when it flows backwards. A dot is a triangle pointing in the flow direction, 0.06*d0
% long along the path and 0.035*d0 wide across it in the horizontal plane (along x
% when the path is vertical), at the height of the path. The dots of the branches are
% one patch (sct_plt.FlowBranch), those of the links another (FlowLink), one face per
% dot, white with a thin dark edge (draw_diagram_2d); UserData.Index of a patch holds the
% element of each face (the row among the branches, or among the links). With r_dt = 0
% the dots are drawn where they are.
    arguments (Input)
        obj
        r_dt (1,1) double {mustBeNonnegative, mustBeFinite}  % [s] Time to advance.
    end
    if validate(obj) || isempty(obj.sct_flowPath)
        return
    end
    f     = obj.sct_flow;
    n_br  = obj.n_branch;
    n_all = n_br + obj.n_component;
    if numel(f.rv_phase) ~= n_all || numel(f.rv_v) ~= n_all
        return
    end
    d0      = obj.sct_plt.D0;
    r_delta = 0.25*d0;
    f.rv_phase = mod(f.rv_phase + f.rv_v*r_dt, r_delta);
    obj.sct_flow.rv_phase = f.rv_phase;

    c_rows  = {1:n_br, n_br + 1:n_all};
    c_patch = {obj.sct_plt.FlowBranch, obj.sct_plt.FlowLink};
    r_half  = 0.03*d0;                 % half length of a dot
    r_wide  = 0.0175*d0;               % half width of a dot
    for j = 1:2
        h_patch = c_patch{j};
        if ~any(isgraphics(h_patch))
            continue
        end
        p      = obj.sct_flowPath(j);
        rv_ph  = f.rv_phase(c_rows{j});
        rv_dir = f.rv_dir(c_rows{j});
        iv_e   = p.iv_e;
        rv_s   = rv_ph(iv_e) + p.rv_k*r_delta;
        rv_L   = p.rv_len(iv_e);
        lv     = rv_dir(iv_e) ~= 0 & rv_s <= rv_L;
        iv_e   = iv_e(lv);
        rv_s   = rv_s(lv);
        rv_L   = rv_L(lv);
        rv_d   = rv_dir(iv_e);
        rv_s(rv_d < 0) = rv_L(rv_d < 0) - rv_s(rv_d < 0);
        if isempty(iv_e)                   % no dots (also no element, or a path of one point)
            set(h_patch, "Faces", zeros(0, 3), "Vertices", zeros(0, 3), "UserData", struct("Type", "Flow", "Index", zeros(0, 1)));
            continue
        end
        rv_sg  = p.rv_g(iv_e) + min(max(rv_s, 0), rv_L*(1 - 1e-9));
        iv_seg = discretize(rv_sg, p.rv_cum);
        rm_t   = p.rm_t(iv_seg, :) .* rv_d;                         % flow direction
        rm_c   = p.rm_p(iv_seg, :) + (rv_sg - p.rv_cum(iv_seg)) .* p.rm_t(iv_seg, :);
        rm_n   = [rm_t(:, 2), -rm_t(:, 1), zeros(numel(iv_e), 1)];  % across, in the horizontal plane
        rv_nn  = vecnorm(rm_n, 2, 2);
        lv_up  = rv_nn < 1e-9;
        rm_n(lv_up, :) = repmat([1 0 0], nnz(lv_up), 1);
        rv_nn(lv_up) = 1;
        rm_n   = rm_n ./ rv_nn;
        rm_v   = cat(3, rm_c + r_half*rm_t, rm_c - r_half*rm_t + r_wide*rm_n, rm_c - r_half*rm_t - r_wide*rm_n);
        rm_v   = reshape(permute(rm_v, [3 1 2]), [], 3);
        n_dot  = numel(iv_e);
        set(h_patch, "Faces", reshape(1:3*n_dot, 3, n_dot)', "Vertices", rm_v, ...
            "UserData", struct("Type", "Flow", "Index", iv_e(:)));
    end
end
