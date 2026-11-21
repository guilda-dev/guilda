function rv_lim = color_limits(obj)
% Color limits in use: ColorLimits when it is finite, else the automatic limits.
%
% The automatic limits (ColorLimits with a NaN) are those of ColorMode over all samples
% (update_color_scale); with "user" they are the 5th to 95th percentiles of the finite
% color data set (BusColorData, ComponentColorData, BranchColorData, LinkColorData;
% color_percentile: [min, max] with fewer than 20 values or when they are equal), [0 1]
% without one.
% Limits closer together than 1e-6 of their magnitude (a field that is constant up to
% rounding, e.g. one price everywhere) are shown as c*(1 -/+ 1e-3) around their middle c
% ([c-1, c+1] when c is 0), so that the colorbar ticks are a few readable values instead
% of the digits of the rounding.
    arguments (Input)
        obj
    end
    arguments (Output)
        rv_lim (1,2) double  % [cmin cmax], increasing.
    end
    rv_lim = obj.ColorLimits;
    if any(isnan(rv_lim))
        if obj.ColorMode == "user"
            rv_v = [obj.BusColorData; obj.ComponentColorData; obj.BranchColorData; obj.LinkColorData];
            rv_v = real(rv_v(isfinite(rv_v)));
            rv_lim = [0 1];
            if ~isempty(rv_v)
                rv_lim = [GraphNetDiagram.color_percentile(rv_v, 0.05), GraphNetDiagram.color_percentile(rv_v, 0.95)];
                if ~(rv_lim(2) > rv_lim(1))
                    rv_lim = [min(rv_v), max(rv_v)];
                end
            end
        else
            rv_lim = obj.rv_climAuto;
        end
    end
    r_mid = (rv_lim(1) + rv_lim(2))/2;
    if rv_lim(2) - rv_lim(1) <= 1e-6*max(abs(rv_lim))
        r_half = 1e-3*abs(r_mid);
        if r_half == 0
            r_half = 1;
        end
        rv_lim = r_mid + [-r_half, r_half];
    end
end
