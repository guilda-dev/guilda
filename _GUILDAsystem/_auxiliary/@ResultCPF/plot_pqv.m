function G = plot_pqv(obj, opt)
% Plot the P-Q-V path of the buses in 3D: P, Q and |V| of each bus at every step.
%
% Draws one 3D line per bus through (P, Q, |V|) [pu] of its steps: P + jQ is the total
% power the bus injects into the network, S = V conj(sum of the currents of its
% components), from cm_Vbus and cm_Icomponent; it equals V conj(Y V) of the bus (a load
% bus has negative P). A bus without components has P = Q = 0. By default it draws the
% buses of plot_pvcurve (options.LoadBus; every bus when it is empty); Bus selects other
% buses ("all" for every bus), and a tag that is not in sv_bus stops with
% GUILDA:ResultCPF:UnknownBus. Drag the axes to turn the view.
%
% The samples of the chart are the steps (rv_t = 1 ... n_step, named "Step", text "Step k
% (λ = ...)"): G.set_time(k) puts a marker on each line at its point of step k (none
% before the first set_time), and G.link(G2) keeps it in step with the other plots of the
% steps (plot_pvcurve, plot_diagram, ...). A result without the data of the steps stops
% with GUILDA:ResultCPF:NoStepData.
%
% It returns the chart G (GraphChart, one 3D panel): one line per bus, tagged with the
% bus tag.
%
% <@Examples>
% ```matlab
% res = net.calculate_continuation_powerflow(LoadBus=["B009","B014"]);
% G = res.plot_pqv();
% G.set_time(res.r_noseStep);       % markers at the nose
% res.plot_pqv(Bus="all");
% ```
%
% See also ResultCPF.plot_pvcurve, ResultODE.plot_pqv, GraphChart
    arguments (Input)
        obj
        opt.Bus    {mustBeText} = default_bus(obj)  % Tags of the buses to draw; "all" for every bus.
        opt.Parent = []                             % Container (figure, uifigure, uipanel, uitab, uigridlayout) or axes/uiaxes to draw in; [] for a new figure.
    end
    arguments (Output)
        G  % The chart (GraphChart), one 3D line per bus.
    end
    check_step_data(obj, "plot_pqv", ["cm_Vbus", "cm_Icomponent", "sct_network"]);
    sv_plot = string(opt.Bus);
    if isequal(sv_plot, "all")
        sv_plot = obj.sv_bus;
    end
    sv_plot = sv_plot(:);
    [lv_found, iv_bus] = ismember(sv_plot, obj.sv_bus);
    if ~all(lv_found)
        error(msg("GUILDA:ResultCPF:UnknownBus", char(join(sv_plot(~lv_found), ", "))));
    end

    % Current each bus injects: the sum of the currents of its components (network order)
    a_bus = reshape(obj.sct_network.a_Bus, [], 1);
    cm_I  = complex(zeros(numel(obj.sv_bus), numel(obj.rv_lambda)));
    i_comp = 0;
    for i = 1:numel(a_bus)
        n_comp = numel(a_bus{i}.a_Component);
        i_row  = find(obj.sv_bus == string(a_bus{i}.s_tag), 1);
        cm_I(i_row, :) = sum(obj.cm_Icomponent(i_comp + (1:n_comp), :), 1, "omitnan");
        i_comp = i_comp + n_comp;
    end
    cm_S = obj.cm_Vbus(iv_bus, :) .* conj(cm_I(iv_bus, :));    % buses x steps
    rm_V = abs(obj.cm_Vbus(iv_bus, :));

    sct = step_sample(obj);
    sct.sct_panel = struct("s_title", "P-Q-V path", "s_xlabel", "P [pu]", "s_ylabel", "Q [pu]", ...
        "s_zlabel", "|V| [pu]", "l_3d", true, "l_time", true, "s_cursor", "marker", "s_legendLocation", "best");
    c_series = cell(1, numel(iv_bus));
    for k = 1:numel(iv_bus)
        c_series{k} = struct("rv_x", real(cm_S(k, :)), "rm_y", imag(cm_S(k, :)).', "rm_z", rm_V(k, :).', ...
            "sv_tag", obj.sv_bus(iv_bus(k)), "r_lineWidth", 1.2);
    end
    sct.sct_series = [c_series{:}];
    G = GraphChart(sct, Parent=opt.Parent);
end


function sv = default_bus(obj)
% Buses drawn by default: those of plot_pvcurve (options.LoadBus; every bus when it is empty).
    arguments (Input)
        obj  % The result. <@Type> ResultCPF
    end
    arguments (Output)
        sv  % Bus tags, or "all".
    end
    sv = "all";
    if isfield(obj.options, "LoadBus") && ~isempty(obj.options.LoadBus)
        sv = obj.options.LoadBus;
    end
end
