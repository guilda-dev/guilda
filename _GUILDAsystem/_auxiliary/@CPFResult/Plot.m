function ax = Plot(obj, opt)
% <@Desc>
% Draws the PV curves: the voltage magnitude [pu] of each bus against the load parameter
% lambda along the path. A dashed line marks the nose (maximum loading, r_lambdaMax).
% By default it draws the load buses (options.LoadBus); Bus selects other buses.
% calculate_continuation_powerflow(..., Plot=true) calls it.
% <@Role> Plot
% <@Summary> Plot the PV curves.
% <@Signatures>
% [
%   "Plot(result)",
%   "ax = Plot(result, Bus=sv_bus, Parent=container)"
% ]
% <@Parameters>
% [
%   {"Name": "result", "Type": "CPFResult", "Description": "Result to plot.", "Required": true, "Default": "-"},
%   {"Name": "Bus", "Type": "string", "Description": "Tags of the buses to draw; \"all\" for every bus.", "Required": false, "Default": "result.options.LoadBus"},
%   {"Name": "Parent", "Type": "figure, panel or tab", "Description": "Container to draw in. A new figure when empty.", "Required": false, "Default": "[]"}
% ]
% <@Returns>
% [
%   {"Name": "ax", "Type": "matlab.graphics.axis.Axes", "Description": "Axes holding the PV curves."}
% ]
    arguments
        obj
        opt.Bus    {mustBeText} = default_bus(obj)
        opt.Parent = []
    end
    sv_plot = string(opt.Bus);
    if isequal(sv_plot, "all")
        sv_plot = obj.sv_bus;
    end
    [lv_found, iv_bus] = ismember(sv_plot, obj.sv_bus);
    if ~all(lv_found)
        error('GUILDA:CPFResult:UnknownBus', '%s', ...
              msg('GUILDA:CPFResult:UnknownBus', char(join(sv_plot(~lv_found), ", "))));
    end
    if isempty(opt.Parent)
        opt.Parent = figure();
    end

    ax = axes(opt.Parent);
    plot(ax, obj.rv_lambda, abs(obj.cm_Vbus(iv_bus,:)), "LineWidth", 1.2);
    hold(ax, "on");
    if ~isnan(obj.r_lambdaMax)
        xline(ax, obj.r_lambdaMax, "--", "\lambda_{max} = " + compose("%.4g", obj.r_lambdaMax), ...
              "HandleVisibility", "off");
    end
    hold(ax, "off");
    xlabel(ax, "\lambda");
    ylabel(ax, "|V| [pu]");
    legend(ax, sv_plot, "Location", "southwest");
    grid(ax, "on");
    str_title = "PV curve";
    if ~obj.l_success
        str_title = str_title + " - nose not reached";
    end
    title(ax, str_title);
end


function sv = default_bus(obj)
    sv = "all";
    if isfield(obj.options, "LoadBus") && ~isempty(obj.options.LoadBus)
        sv = obj.options.LoadBus;
    end
end
