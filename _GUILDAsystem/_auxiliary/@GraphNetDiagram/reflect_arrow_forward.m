function reflect_arrow_forward(obj)
% Set BranchDirection and LinkDirection from the sample shown: the directions of the arrows and dots.
%
% With a FlowMode other than "none", they are the sign of the flow q of each branch and
% link at the sample shown (flow_values; 0 for NaN), so the cones of 3D and the dots of
% 2D point the same way. With "none", a branch points from the end of the larger voltage
% angle and a link by the sign of the active power of its component.
    arguments (Input)
        obj
    end
    n_br = obj.n_branch;
    rm_q = obj.sct_flow.rm_q;
    if obj.FlowMode ~= "none" && size(rm_q, 1) == n_br + obj.n_component && obj.i_time <= size(rm_q, 2)
        rv_s = sign(rm_q(:, obj.i_time));
        rv_s(isnan(rv_s)) = 0;
        obj.BranchDirection = rv_s(1:n_br);
        obj.LinkDirection   = rv_s(n_br + 1:end);
        return
    end
    rm_Varg = angle(obj.cm_Vbranch);
    obj.BranchDirection = -diff(rm_Varg).';
    obj.LinkDirection = obj.rv_Pcomp(:);
end
