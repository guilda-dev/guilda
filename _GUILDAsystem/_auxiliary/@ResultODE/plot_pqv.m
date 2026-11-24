function G = plot_pqv(obj, opt)
% Plot the P-Q-V trajectory of the buses in 3D: P, Q and |V| of each bus at every output time.
%
% Draws one 3D line per bus through (P, Q, |V|) [pu] of its output times: P + jQ is the
% total power the bus injects into the network, S = V conj(sum of the currents of its
% components), from the bus voltages (Vre, Vim of rm_variable) and rm_Icomponent; it
% equals V conj(Y V) of the bus (rm_I) within the tolerance of the solver, except at a
% faulted bus during the fault (the fault current is not a component current). A
% tripped component (NaN current) counts as 0, and a bus without components has
% P = Q = 0. By default it draws every bus; Bus selects some (a tag that is not in sv_bus
% stops with GUILDA:ResultODE:UnknownBus). Drag the axes to turn the view.
%
% The samples of the chart are the output times rv_t: G.set_time(t) puts a marker on each
% line at its point of the time nearest to t (none before the first set_time), and
% G.link(G2) keeps it in step with plot_diagram, plot_spring_model and plot_trajectory.
% A result without time points or component currents stops with
% GUILDA:ResultODE:NoDiagramData.
%
% It returns the chart G (GraphChart, one 3D panel): one line per bus, tagged with the
% bus tag.
%
% <@Examples>
% ```matlab
% net = network.IEEE9bus();
% sc = net.add_scenario("fault");
% sc.add_fault("B007", [1, 1.05]);
% res = net.simulate("fault", Time=[0, 5]);
% G = res.plot_pqv(Bus=["B005", "B007"]);
% G.set_time(1.02);       % markers during the fault
% ```
%
% See also ResultODE.plot_trajectory, ResultCPF.plot_pqv, GraphChart
    arguments (Input)
        obj
        opt.Bus    {mustBeText} = "all"  % Tags of the buses to draw; "all" for every bus.
        opt.Parent = []                  % Container (figure, uifigure, uipanel, uitab, uigridlayout) or axes/uiaxes to draw in; [] for a new figure.
    end
    arguments (Output)
        G  % The chart (GraphChart), one 3D line per bus.
    end
    if isempty(obj.rv_t) || isempty(obj.c_index) || isempty(obj.rm_Icomponent) ...
            || all(isnan(obj.rm_Icomponent), "all")
        error(msg("GUILDA:ResultODE:NoDiagramData"));
    end
    sv_plot = string(opt.Bus);
    if isequal(sv_plot, "all")
        sv_plot = obj.sv_bus;
    end
    sv_plot = sv_plot(:);
    [lv_found, iv_bus] = ismember(sv_plot, obj.sv_bus);
    if ~all(lv_found)
        error(msg("GUILDA:ResultODE:UnknownBus", char(join(sv_plot(~lv_found), ", "))));
    end

    rm_tr = obj.rm_variable.';                                     % variables x time
    cm_Ic = obj.rm_Icomponent(:, 1:2:end).' + 1j*obj.rm_Icomponent(:, 2:2:end).';   % components x time
    iv_first = cumsum([0; cellfun(@numel, obj.c_component)]);     % components before each bus
    sct = struct("rv_t", obj.rv_t.');
    sct.sct_panel = struct("s_title", "P-Q-V trajectory", "s_xlabel", "P [pu]", "s_ylabel", "Q [pu]", ...
        "s_zlabel", "|V| [pu]", "l_3d", true, "l_time", true, "s_cursor", "marker", "s_legendLocation", "best");
    c_series = cell(1, numel(iv_bus));
    for k = 1:numel(iv_bus)
        i = iv_bus(k);
        rv_V = [1, 1j]*rm_tr(obj.c_index{i}.iv_V, :);
        rv_I = sum(cm_Ic(iv_first(i) + (1:numel(obj.c_component{i})), :), 1, "omitnan");
        rv_S = rv_V .* conj(rv_I);
        c_series{k} = struct("rv_x", real(rv_S), "rm_y", imag(rv_S).', "rm_z", abs(rv_V).', ...
            "sv_tag", obj.sv_bus(i), "r_lineWidth", 1.2);
    end
    sct.sct_series = [c_series{:}];
    G = GraphChart(sct, Parent=opt.Parent);
end
