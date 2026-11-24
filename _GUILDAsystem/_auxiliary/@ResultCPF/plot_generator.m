function [G, G_pv] = plot_generator(obj, opt)
% Plot the active or reactive power of the generators along the path.
%
% The generators are the components with Q = NaN in the powerflow parameters of the
% snapshot sct_network (the components that take the free Q of their bus, and the free P
% of the slack bus). At each step their power is S = V conj(I), from cm_Vbus and
% cm_Icomponent, drawn against lambda by Quantity:
%
% - "P": the active power [pu] of each generator.
% - "Q": the reactive power [pu] of each generator.
% - "Qmargin": the distance of Q to the nearer of Qmin and Qmax (operating limits of the
%   generator in the snapshot) [pu]; it is 0 at a limit and negative beyond it. A
%   generator with no finite limit (Inf or NaN Qmin and Qmax) has no line; a dotted line
%   marks 0.
%
% A dotted vertical line marks the lambda of each switch of tab_switch (a PV bus fixed at
% Qmin or Qmax by Limits "Q"), labelled with the bus and the limit, and a dashed line the
% nose. The samples of the chart are the steps (rv_t = 1 ... n_step, named "Step"):
% G.set_time(k) puts a marker on each line at step k, and G.link(G2) keeps it in step with
% plot_pvcurve, plot_diagram and the other plots of the steps. A result without the data
% of the steps stops with GUILDA:ResultCPF:NoStepData; Quantity "Qmargin" with no finite
% limit stops with GUILDA:ResultCPF:NoLimit.
%
% It returns the chart G (GraphChart): one line per generator, tagged with the component
% tag.
%
% With PVCurve true (default), the PV curves of PVBus (|V| [pu] against lambda, as
% plot_pvcurve, with the nose line) are an extra panel on top of the chart: it shares the
% lambda axis (the x axes of the lambda panels are linked) and is a time panel with the
% marker cursor, so set_time(k) puts a marker on each PV curve at step k too. Its lines
% are tagged "V_" + bus tag (legend: the bus tag) and come after the elements above in
% tab_element, so their tags and rows stay. G_pv is then G. PVCurve false, or an axes or
% uiaxes Parent, draws the chart alone as before (G_pv []). A PVBus tag that is not in
% sv_bus stops with GUILDA:ResultCPF:UnknownBus.
%
% <@Examples>
% ```matlab
% res = net.calculate_continuation_powerflow(LoadBus=["B009","B014"], Limits="Q");
% G = res.plot_generator(Quantity="Q");
% res.plot_generator(Quantity="Qmargin", Generator=["B002SG1","B003SG1"]);
% ```
%
% See also ResultCPF.tab_switch, ResultCPF.plot_pvcurve, SolverCPF
    arguments (Input)
        obj
        opt.Quantity (1,1) string {mustBeMember(opt.Quantity, ["P","Q","Qmargin"])} = "Q"  % Value of the lines (see the list).
        opt.Generator {mustBeText} = "all"  % Tags of the generators (components with Q = NaN in powerflow) to draw; "all" for every one.
        opt.PVCurve (1,1) logical = true  % Draw the PV curves with the plot (see the help); false: the plot alone.
        opt.PVBus {mustBeText} = ""       % Buses of the PV curves: "" those of plot_pvcurve (options.LoadBus; every bus when none), "all" every bus, or bus tags.
        opt.Parent = []  % Container (figure, uifigure, uipanel, uitab, uigridlayout) or axes/uiaxes to draw in; [] for a new figure.
    end
    arguments (Output)
        G     % The chart (GraphChart), one line per generator.
        G_pv  % The chart with the PV panel: G itself; [] with PVCurve false or an axes Parent.
    end
    check_step_data(obj, "plot_generator", ["cm_Vbus", "cm_Icomponent", "sct_network"]);

    % Generators: Q = NaN in powerflow, in the network order of cm_Icomponent
    a_bus = reshape(obj.sct_network.a_Bus, [], 1);
    sv_gen = strings(0, 1);
    iv_comp = zeros(0, 1);
    iv_bus  = zeros(0, 1);
    rm_lim  = zeros(0, 2);
    i_comp = 0;
    for i = 1:numel(a_bus)
        a_comp = reshape(a_bus{i}.a_Component, [], 1);
        for j = 1:numel(a_comp)
            i_comp = i_comp + 1;
            tab = a_comp{j}.tab_parameter;
            if ~(ismember("powerflow", tab.Properties.VariableNames) && ismember("Q", tab.powerflow.Properties.VariableNames) ...
                    && isnan(tab.powerflow.Q))
                continue
            end
            rv_lim = [-Inf, Inf];
            if ismember("operation", tab.Properties.VariableNames)
                sv_ope = string(tab.operation.Properties.VariableNames);
                if ismember("Qmin", sv_ope); rv_lim(1) = tab.operation.Qmin; end
                if ismember("Qmax", sv_ope); rv_lim(2) = tab.operation.Qmax; end
            end
            sv_gen(end+1, 1)  = string(a_comp{j}.s_tag);   %#ok<AGROW>
            iv_comp(end+1, 1) = i_comp;                    %#ok<AGROW>
            iv_bus(end+1, 1)  = find(obj.sv_bus == string(a_bus{i}.s_tag), 1);   %#ok<AGROW>
            rm_lim(end+1, :)  = rv_lim;                    %#ok<AGROW>
        end
    end
    if isempty(sv_gen)
        error(msg("GUILDA:ResultCPF:NoGenerator"));
    end
    sv_plot = string(opt.Generator);
    if isequal(sv_plot, "all")
        sv_plot = sv_gen;
    end
    [lv_found, iv_sel] = ismember(sv_plot(:), sv_gen);
    if ~all(lv_found)
        error(msg("GUILDA:ResultCPF:UnknownGenerator", join(sv_plot(~lv_found), ", "), join(sv_gen, ", ")));
    end

    cm_S = obj.cm_Vbus(iv_bus(iv_sel), :) .* conj(obj.cm_Icomponent(iv_comp(iv_sel), :));   % generators x steps
    switch opt.Quantity
        case "P"
            rm_y = real(cm_S).';
            s_ylabel = "P [pu]";
        case "Q"
            rm_y = imag(cm_S).';
            s_ylabel = "Q [pu]";
        case "Qmargin"
            rm_l = rm_lim(iv_sel, :);
            rm_l(isnan(rm_l(:, 1)), 1) = -Inf;                  % NaN limit: none
            rm_l(isnan(rm_l(:, 2)), 2) = Inf;
            rm_y = min(imag(cm_S) - rm_l(:, 1), rm_l(:, 2) - imag(cm_S)).';
            lv_keep = any(isfinite(rm_l), 2);
            if ~any(lv_keep)
                error(msg("GUILDA:ResultCPF:NoLimit", "generator", "Qmin or Qmax", opt.Quantity));
            end
            rm_y = rm_y(:, lv_keep);
            iv_sel = iv_sel(lv_keep);
            s_ylabel = "Q margin [pu]";
    end

    sct = step_sample(obj);
    sct.sct_panel = struct("s_title", "Generators (" + opt.Quantity + ")", "s_xlabel", "\lambda", ...
        "s_ylabel", s_ylabel, "l_time", true, "s_cursor", "marker", "s_legendLocation", "best");
    sct.sct_series = struct("rv_x", reshape(obj.rv_lambda, 1, []), "rm_y", rm_y, ...
        "sv_tag", sv_gen(iv_sel), "r_lineWidth", 1.2);
    sct.sct_refline = struct("s_axis", {}, "r_value", {}, "s_label", {}, "rv_color", {}, "s_lineStyle", {});
    tab_sw = obj.tab_switch;
    for k = 1:height(tab_sw)
        sct.sct_refline(end+1) = struct("s_axis", "x", "r_value", tab_sw.lambda(k), ...
            "s_label", string(tab_sw.Bus(k)) + " " + string(tab_sw.Limit(k)), "rv_color", [0.5 0.5 0.5], "s_lineStyle", ":");
    end
    if ~isnan(obj.r_lambdaMax)
        sct.sct_refline(end+1) = struct("s_axis", "x", "r_value", obj.r_lambdaMax, ...
            "s_label", "\lambda_{max}", "rv_color", [0.15 0.15 0.15], "s_lineStyle", "--");
    end
    if opt.Quantity == "Qmargin"
        sct.sct_refline(end+1) = struct("s_axis", "y", "r_value", 0, "s_label", "", ...
            "rv_color", [0.15 0.15 0.15], "s_lineStyle", ":");
    end
    [G, G_pv] = pair_pvcurve(obj, opt, sct);
end
