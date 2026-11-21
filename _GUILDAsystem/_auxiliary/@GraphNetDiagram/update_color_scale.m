function update_color_scale(obj)
% Compute the automatic color limits of ColorMode over all samples of the state.
%
% With m the 95th percentile of |value| over the branches, the links and all samples
% (color_percentile; the largest |value| with fewer than 20 values, or when it is 0), a
% magnitude ("I", "Loss") gives [0, m] and a signed quantity ("P", "Q": the injections of
% the components are signed) gives [-m, m]; the values above m take the end colors.
% Without a finite value (or a largest value of 0) the limits are [0 1] or [-1 1]. "none" and "user" keep [0 1] here: the limits of "user" come from
% the color data set (color_limits). Called when the state or ColorMode changes.
    arguments (Input)
        obj
    end
    if isempty(obj.sct_state)
        return
    end
    [rm_branch, rm_link] = obj.color_values(1:numel(obj.sct_state.rv_t));
    rv_v  = [rm_branch(:); rm_link(:)];
    rv_a  = abs(rv_v(isfinite(rv_v)));
    r_max = GraphNetDiagram.color_percentile(rv_a, 0.95);   % the top 5% (outliers) take the top color
    if ~(r_max > 0 && isfinite(r_max))
        r_max = max([rv_a; 0]);
    end
    if ~(r_max > 0)
        r_max = 1;
    end
    if any(obj.ColorMode == ["P", "Q"])
        obj.rv_climAuto = [-r_max, r_max];
    else
        obj.rv_climAuto = [0, r_max];
    end
end
