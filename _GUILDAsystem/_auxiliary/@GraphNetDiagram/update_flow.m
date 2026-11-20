function update_flow(obj)
% Set the speeds and directions of the flow dots for the sample shown, and draw the dots (2D).
%
% The speed of the dots of an element is FlowSpeed*d0*|q|/q_max [coordinates/s], with q
% its flow at the sample shown and q_max the largest |q| over all samples (flow_values).
% The direction is the sign of BranchDirection and LinkDirection (the sign of q, see
% reflect_arrow_forward). An element with no flow (NaN), a flow below 1e-3*q_max, or no
% q_max has no dots. The phases stay; an element whose direction turns takes the phase
% Delta - phase, so its dots move back from where they are. In 3D there is nothing.
    arguments (Input)
        obj
    end
    if validate(obj) || isempty(obj.sct_flowPath)
        return
    end
    n_all = obj.n_branch + obj.n_component;
    f = obj.sct_flow;
    if numel(f.rv_phase) ~= n_all
        f.rv_phase = zeros(n_all, 1);
        f.rv_dir   = zeros(n_all, 1);
    end
    rv_q = nan(n_all, 1);
    if size(f.rm_q, 1) == n_all && obj.i_time <= size(f.rm_q, 2)
        rv_q = f.rm_q(:, obj.i_time);
    end
    rv_dir = [reshape(obj.BranchDirection, [], 1); reshape(obj.LinkDirection, [], 1)];
    if numel(rv_dir) ~= n_all
        rv_dir = rv_q;
    end
    rv_dir = sign(rv_dir);
    r_qmax = f.r_qmax;
    lv_on  = isfinite(rv_q) & abs(rv_q) >= 1e-3*r_qmax & r_qmax > 0 & rv_dir ~= 0 & ~isnan(rv_dir);
    rv_dir(~lv_on) = 0;
    rv_v = zeros(n_all, 1);
    rv_v(lv_on) = obj.FlowSpeed * obj.sct_plt.D0 * abs(rv_q(lv_on)) / r_qmax;

    r_delta = 0.25*obj.sct_plt.D0;
    lv_turn = f.rv_dir ~= 0 & rv_dir ~= 0 & f.rv_dir ~= rv_dir;
    f.rv_phase(lv_turn) = mod(r_delta - f.rv_phase(lv_turn), r_delta);
    f.rv_v   = rv_v;
    f.rv_dir = rv_dir;
    obj.sct_flow = f;
    obj.step_flow(0);
end
