function [G, G_pv] = pair_pvcurve(obj, opt, target)
% Draw a plot of the steps with the PV curve: on top of a lambda-axis chart, or on the right of a picture.
%
% opt holds PVCurve, PVBus and Parent of the calling method. PVBus "" takes the buses of
% plot_pvcurve (options.LoadBus; every bus when it is empty), "all" every bus; a tag that
% is not in sv_bus stops with GUILDA:ResultCPF:UnknownBus before anything is drawn.
%
% - target a struct (data of a GraphChart whose time panels have lambda as x, from
%   plot_stability_index, plot_generator, plot_branch): the PV curves become panel 1 on
%   top (|V| against lambda, a dashed line at the nose, time panel with the marker
%   cursor), the panels of the data follow it, and the x axes of the lambda panels are
%   linked. The PV series is added after the series of the data, so the elements of the
%   data keep their rows of tab_element; its lines are tagged "V_" + bus tag (legend: the
%   bus tag). G_pv is G.
% - target a function handle (fcn_graph(h) draws the picture of plot_diagram or
%   plot_spring_model in a parent h): the container Parent (a new figure of 1400 x 600 px
%   when it is empty; a uigridlayout gets a borderless uipanel first) holds two
%   borderless panels side by side, the picture on the left (2/3 of the width) and
%   plot_pvcurve(Bus=PVBus) on the right (1/3), linked with G.link(G_pv). A drawing that
%   fails removes the panels (and the new figure) it made.
%
% PVCurve false, or an axes or uiaxes Parent, draws the plot alone as before (G_pv []).
    arguments (Input)
        obj    ResultCPF   % The result.
        opt    (1,1) struct  % Options of the calling method: PVCurve, PVBus, Parent.
        target             % Chart data (struct) or fcn_graph (function handle) of the plot.
    end
    arguments (Output)
        G     % The plot (GraphChart, GraphNetDiagram, GraphSpring2D or GraphSpring3D).
        G_pv  % The PV chart (GraphChart) linked to G; G itself for a lambda-axis chart; [] without one.
    end
    l_chart = isstruct(target);
    sv_container = ["matlab.ui.Figure", "matlab.ui.container.Panel", "matlab.ui.container.Tab", ...
                    "matlab.ui.container.GridLayout"];
    l_container = isempty(opt.Parent) || (isscalar(opt.Parent) && isgraphics(opt.Parent) ...
        && any(arrayfun(@(s) isa(opt.Parent, s), sv_container)));
    G_pv = [];
    if ~opt.PVCurve || ~l_container        % alone (an axes, or a wrong Parent: the error of the graph)
        if l_chart
            G = GraphChart(target, Parent=opt.Parent);
        else
            G = target(opt.Parent);
        end
        return
    end

    % Buses of the PV curves (as plot_pvcurve)
    sv_pv = string(opt.PVBus);
    if isequal(sv_pv, "")
        sv_pv = "all";
        if isfield(obj.options, "LoadBus") && ~isempty(obj.options.LoadBus)
            sv_pv = string(obj.options.LoadBus);
        end
    end
    if isequal(sv_pv, "all")
        sv_pv = obj.sv_bus;
    end
    sv_pv = sv_pv(:);
    [lv_found, iv_bus] = ismember(sv_pv, obj.sv_bus);
    if ~all(lv_found)
        error(msg("GUILDA:ResultCPF:UnknownBus", char(join(sv_pv(~lv_found), ", "))));
    end

    if l_chart
        % PV panel on top; the panels of the data move down by one
        sct = target;
        sct_new = struct("s_title", "PV curve", "s_xlabel", "\lambda", "s_ylabel", "|V| [pu]", ...
            "l_time", true, "s_cursor", "marker", "s_legendLocation", "southwest");
        lv_lambda = [true, arrayfun(@(p) isfield(p, "l_time") && isequal(p.l_time, true), sct.sct_panel)];
        sct.sct_panel = append_struct(sct.sct_panel, sct_new);
        sct.sct_panel = sct.sct_panel([end, 1:end-1]);   % one column of panels (no rv_grid in the data)

        if ~isfield(sct.sct_series, "i_panel")
            [sct.sct_series.i_panel] = deal([]);
        end
        for k = 1:numel(sct.sct_series)
            sct.sct_series(k).i_panel = max([sct.sct_series(k).i_panel, 1]) + 1;
        end
        sct.sct_series = append_struct(sct.sct_series, struct("i_panel", 1, ...
            "rv_x", reshape(obj.rv_lambda, 1, []), "rm_y", abs(obj.cm_Vbus(iv_bus, :)).', ...
            "sv_tag", "V_" + obj.sv_bus(iv_bus), "sv_legend", obj.sv_bus(iv_bus), "r_lineWidth", 1.2));

        if ~isfield(sct, "sct_refline") || isempty(sct.sct_refline)
            sct.sct_refline = struct("i_panel", {}, "s_axis", {}, "r_value", {}, "s_label", {}, "rv_color", {}, "s_lineStyle", {});
        end
        if ~isfield(sct.sct_refline, "i_panel")
            [sct.sct_refline.i_panel] = deal([]);
        end
        for k = 1:numel(sct.sct_refline)
            sct.sct_refline(k).i_panel = max([sct.sct_refline(k).i_panel, 1]) + 1;
        end
        if ~isnan(obj.r_lambdaMax)
            sct.sct_refline = append_struct(sct.sct_refline, struct("i_panel", 1, "s_axis", "x", ...
                "r_value", obj.r_lambdaMax, "s_label", "\lambda_{max} = " + compose("%.4g", obj.r_lambdaMax), ...
                "rv_color", [0.15 0.15 0.15], "s_lineStyle", "--"));
        end
        G = GraphChart(sct, Parent=opt.Parent);
        G_pv = G;
        if nnz(lv_lambda) > 1
            linkaxes(G.ax(lv_lambda), "x");
        end
        return
    end

    % Picture on the left (2/3), PV chart on the right (1/3)
    h_host = opt.Parent;
    h_made = gobjects(0);                           % what is deleted when the drawing fails
    if isempty(h_host)
        h_host = figure("Color", "w", "Position", [100 100 1400 600]);
        h_made = h_host;
    elseif isa(h_host, "matlab.ui.container.GridLayout")
        h_host = uipanel(h_host, "BorderType", "none");
        h_made = h_host;
    end
    rv_back = [1 1 1];
    if isprop(h_host, "Color")
        rv_back = h_host.Color;
    elseif isprop(h_host, "BackgroundColor")
        rv_back = h_host.BackgroundColor;
    end
    h_left  = uipanel(h_host, "Units", "normalized", "Position", [0 0 2/3 1], "BorderType", "none", ...
        "BackgroundColor", rv_back);
    h_right = uipanel(h_host, "Units", "normalized", "Position", [2/3 0 1/3 1], "BorderType", "none", ...
        "BackgroundColor", rv_back);
    if isempty(h_made)
        h_made = [h_left, h_right];
    end
    try
        G_pv = obj.plot_pvcurve(Bus=obj.sv_bus(iv_bus), Parent=h_right);
        G = target(h_left);
    catch err
        delete(h_made(isgraphics(h_made)));
        rethrow(err);
    end
    G.link(G_pv);
end


function sct = append_struct(sct, sct_new)
% Append sct_new to the struct array sct; a field missing on one side is [] there (the default of GraphChart).
    arguments (Input)
        sct           % Struct array (may be empty).
        sct_new (1,1) struct  % Struct to append.
    end
    arguments (Output)
        sct  % The struct array with sct_new last.
    end
    if isempty(sct)
        sct = sct_new;
        return
    end
    for s_field = setdiff(string(fieldnames(sct_new))', string(fieldnames(sct))')
        [sct.(s_field)] = deal([]);
    end
    for s_field = setdiff(string(fieldnames(sct))', string(fieldnames(sct_new))')
        sct_new.(s_field) = [];
    end
    sct_new = orderfields(sct_new, sct);
    sct(end + 1) = sct_new;
end
