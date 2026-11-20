function update_scale(obj)
% Compute the scales [vmin vmax] of the size quantities over all samples of the state.
%
% The values are the finite values over every element of its kind and every sample. The
% marker scales (Bus, Comp) are [smallest, largest]. The branch scale leaves out the top
% outliers, as the automatic ColorLimits do: [smallest, p95], with p95 the 95th percentile
% (color_percentile; the largest value with fewer than 20 values), so the top 5 % take the
% largest width (range_map keeps them in the range). When p95 equals the smallest value
% (one-value rule of range_map) while the values differ, the scale is [smallest, largest],
% so that the widths do not all collapse to the middle of the range. No finite value gives
% [NaN NaN]. load_data and the setters of BranchWidthMode and MarkerSizeMode call it;
% set_time does not.
    arguments (Input)
        obj
    end
    if isempty(obj.sct_state)
        return
    end
    sct_v = obj.size_values(1:numel(obj.sct_state.rv_t));
    rv_branch = finite_range(sct_v.Branch);
    rv_b      = sct_v.Branch(isfinite(sct_v.Branch));
    r_p95     = GraphNetDiagram.color_percentile(rv_b(:), 0.95);
    if ~isnan(r_p95) && r_p95 - rv_branch(1) > 1e-12*max([abs([rv_branch(1), r_p95]), 1])
        rv_branch(2) = r_p95;   % the top 5% (outliers) take the largest width
    end
    obj.sct_scale = struct("Branch", rv_branch, "Bus", finite_range(sct_v.Bus), ...
                           "Comp", finite_range(sct_v.Comp));
end


function rv_lim = finite_range(rm_v)
% Smallest and largest finite value, or [NaN NaN] when there is none.
    arguments (Input)
        rm_v double  % Values.
    end
    arguments (Output)
        rv_lim (1,2) double  % [vmin vmax].
    end
    rv_v = rm_v(isfinite(rm_v));
    rv_lim = [NaN NaN];
    if ~isempty(rv_v)
        rv_lim = [min(rv_v), max(rv_v)];
    end
end
