function [G_chart, G_net] = plot_iteration(obj, opt)
% Draw the iterations of the AC optimal power flow, with the playback bar of the diagram.
%
% Draws sct_iteration (recorded by fmincon at every "AC OPF" run) as two linked graphs.
% G_chart (GraphChart, on the left) has four panels in a 2-by-2 grid against the iteration
% number, in rows: the
% objective (line tag "Fval"), the largest constraint violation on a log scale (tag
% "ConstrViolation"), P of each generator (a component whose P bounds differ; tags of the
% generators) and |V| of each bus (tags of the buses); its time cursor marks the iteration
% shown, and the title of the chart names it. G_net (GraphNetDiagram of sct_network, on
% the right, axes Tag "Network") is the network diagram of the iteration shown:
%
% - the color of a bus is its |V| (color limits: the lowest lower and the highest upper
%   bound of V), the size of a component its |P| (the middle of MarkerSizeRange times 0.5
%   to 1.5, in pt) and the width of a branch its |P| (the mean of the two ends; 1 to 5 pt),
%   from the V, Varg, P and Q of the iteration in
%   sct_iteration.X; the branch flows come from the admittance matrix cm_Y of each branch
%   in sct_network, as in the problem;
% - the buses, components and branches that violate a limit at that iteration are selected
%   (drawn in SelectionColor): V, P or Q outside the bounds of the variable, or a branch
%   value over the limit of tab_parameter.operation of the branch (|P|, |Q|, |I|, |S| at
%   an end, |Varg_from - Varg_to|), by more than 1e-6.
%
% The diagram has the color bar "|V| [pu]" and the title "violations: n" of the iteration
% shown (TitleFormat "": set_time does not write the time).
%
% The times of both graphs are the iteration numbers (sct_iteration.Iteration) and they
% are linked (G_chart.link(G_net)). The TimeChangedFcn of G_chart draws the iteration shown
% after every set_time of either graph (G_chart.set_time, G_net.set_time, the playback bar,
% play, animate): the title of the chart "OPF iteration k (i of n)" and the colors, sizes,
% widths, violations and title of the diagram. With two or more iterations, the playback
% bar of G_net (below the diagram; see GraphBase) moves both graphs: its slider shows any
% recorded iteration and its Play button (or G_net.play, G_chart.play) plays them from the
% one shown (from the first when the last is shown) to the last at PlaySpeed iterations
% per second. G_chart has no bar of its own: its time only moves the cursor, and the bar
% of G_net moves it through the link. The graphs are in two panels
% (uipanel) side by side in the container Parent (a uigridlayout gets a panel first).
% "ELD" and "DC OPF" (linprog, quadprog) record no iterations and stop with
% GUILDA:ResultOPF:NoIteration. It reads only the stored result.
%
% <@Examples>
% ```matlab
% res = network.IEEE14bus().calculate_optimal_powerflow(Method="AC OPF");
% fig = figure();
% [G_chart, G_net] = res.plot_iteration(Parent=fig);
% G_chart.set_time(3);                      % iteration 3 in both graphs, the title and the diagram
% G_net.play();                             % play from iteration 3 to the last (playback bar of G_net)
% G_net.pause();
% G_chart.tab_element                       % the lines: Fval, ConstrViolation, generators, buses
% ```
%
% See also ResultOPF.sct_iteration, ResultOPF.plot_lmp, ResultPF.plot_convergence, GraphChart, GraphNetDiagram
    arguments (Input)
        obj
        opt.Parent = []  % Container (figure, uifigure, uipanel, uitab, uigridlayout) to draw in; [] for a new figure.
    end
    arguments (Output)
        G_chart  % The four panels of the iterations (GraphChart).
        G_net    % The network diagram of the iteration shown (GraphNetDiagram).
    end
    sct = obj.sct_iteration;
    if ~isfield(sct, "Iteration") || isempty(sct.Iteration)
        error(msg("GUILDA:ResultOPF:NoIteration", string(obj.options.Method)))
    end
    % the container of the two graphs (a panel in a grid layout)
    fig = opt.Parent;
    if isempty(fig)
        fig = figure("Name", "OPF iterations of " + obj.s_network, "Position", [100 100 1400 650]);
    elseif isa(fig, "matlab.ui.container.GridLayout")
        fig = uipanel(fig, "BorderType", "none");
    end
    rv_k   = sct.Iteration;
    n_it   = numel(rv_k);
    sv_bus = string(obj.tab_bus.Properties.RowNames);
    sv_gen = strings(1, 0);
    for s_var = string(fieldnames(sct.X)).'
        var = obj.OPFprob.Variables.(s_var);
        if ~ismember(s_var, sv_bus) && ismember(s_var, string(obj.tab_cub.Properties.RowNames)) ...
                && var.LowerBound(1) ~= var.UpperBound(1)
            sv_gen(end+1) = s_var; %#ok<AGROW>
        end
    end

    % The chart: four panels of lines against the iteration number, time panels so that the
    % cursor marks the iteration shown
    f_panel = @(s_ylabel, s_yscale) struct("s_xlabel", "iteration", "s_ylabel", s_ylabel, "s_yscale", s_yscale, ...
        "l_time", true, "s_legendLocation", "none");
    f_line  = @(i_panel, rm_y, sv_tag) struct("i_panel", i_panel, "rv_x", rv_k, "rm_y", rm_y, "sv_tag", sv_tag);
    sct_chart = struct("rv_t", rv_k, "s_title", "OPF iterations", "rv_grid", [2 2], ...
        "sct_panel", [f_panel("objective", "linear"), f_panel("largest constraint violation", "log"), ...
                      f_panel("P of the generators [pu]", "linear"), f_panel("|V| of the buses [pu]", "linear")], ...
        "sct_series", [f_line(1, sct.Fval(:), "Fval"), f_line(2, max(sct.ConstrViolation(:), realmin), "ConstrViolation"), ...
                       f_line(3, cell2mat(cellfun(@(s) sct.X.(s)(1,:).', cellstr(sv_gen(:)).', "UniformOutput", false)), sv_gen(:)), ...
                       f_line(4, cell2mat(cellfun(@(s) sct.X.(s)(2,:).', cellstr(sv_bus(:)).', "UniformOutput", false)), sv_bus(:))]);
    G_chart = GraphChart(sct_chart, Parent=uipanel(fig, "Units", "normalized", "Position", [0 0 0.64 1], "BorderType", "none"));

    % The network of every iteration: bus voltages and component powers of X (rows [Varg; V]
    % and [P; Q]; a missing variable is NaN), bounds of the variables, and the branch flows
    % S = V.*conj(cm_Y*V) at the two ends from the end voltages
    prob  = obj.OPFprob;
    cm_V  = nan(numel(sv_bus), n_it);
    for i = 1:numel(sv_bus)
        cm_V(i,:) = sct.X.(sv_bus(i))(2,:) .* exp(1j*sct.X.(sv_bus(i))(1,:));
    end
    sv_cub = string(obj.tab_cub.Properties.RowNames);
    cm_S   = zeros(numel(sv_cub), n_it);
    lv_x   = isfield(sct.X, sv_cub);
    cm_S(lv_x,:) = cell2mat(cellfun(@(s) sct.X.(s)(1,:) + 1j*sct.X.(s)(2,:), cellstr(sv_cub(lv_x)), "UniformOutput", false));
    [sct_state, sv_netBus, sv_comp] = diagram_state(obj, cm_V, cm_S);
    sct_state.rv_t = rv_k;                                   % the times of the chart
    r_tol = 1e-6;
    out   = @(rm_x, var, r) rm_x < var.LowerBound(r) - r_tol | rm_x > var.UpperBound(r) + r_tol;
    rm_Vabs = abs(sct_state.cm_Vbus);
    lm_bus  = false(numel(sv_netBus), n_it);
    rr_lim  = [Inf, -Inf];
    for i = 1:numel(sv_netBus)
        var = prob.Variables.(sv_netBus(i));
        lm_bus(i,:) = out(sct.X.(sv_netBus(i))(2,:), var, 2);
        rr_lim = [min(rr_lim(1), var.LowerBound(2)), max(rr_lim(2), var.UpperBound(2))];
    end
    if ~all(isfinite(rr_lim))
        rr_lim = [min(rm_Vabs(:)), max(rm_Vabs(:))] + [-1, 1]*1e-3;
    end
    rm_Pcomp = nan(numel(sv_comp), n_it);
    lm_comp  = false(numel(sv_comp), n_it);
    for i = reshape(find(isfield(sct.X, sv_comp)), 1, [])
        var = prob.Variables.(sv_comp(i));
        rm_Pcomp(i,:) = abs(sct.X.(sv_comp(i))(1,:));
        lm_comp(i,:)  = any(out(sct.X.(sv_comp(i)), var, 1:2), 1);
    end
    a_br   = obj.sct_network.a_Branch;
    sv_br  = reshape(string(cellfun(@(b) b.s_tag, a_br, "UniformOutput", false)), [], 1);
    im_end = branch_ends(obj.sct_network);
    rm_Pbr = zeros(numel(a_br), n_it);
    lm_br  = false(numel(a_br), n_it);
    for b = 1:numel(a_br)
        cm_Vend = sct_state.cm_Vbus(im_end(b,:), :);
        cm_Iend = a_br{b}.cm_Y * cm_Vend;
        cm_Send = cm_Vend .* conj(cm_Iend);
        ope = a_br{b}.tab_parameter.operation;
        rm_Pbr(b,:) = mean(abs(real(cm_Send)), 1);
        lm_br(b,:)  = any(abs(real(cm_Send)) > ope.Pmax + r_tol | abs(imag(cm_Send)) > ope.Qmax + r_tol ...
                        | abs(cm_Iend) > ope.Imax + r_tol | abs(cm_Send) > ope.Smax + r_tol, 1) ...
                      | abs(diff(angle(cm_Vend), 1, 1)) > ope.Vargmax + r_tol;
    end
    sv_tag = [sv_netBus; sv_comp; sv_br];
    lm_out = [lm_bus; lm_comp; lm_br];
    G_net = GraphNetDiagram(obj.sct_network, sct_state, Parent=uipanel(fig, "Units", "normalized", "Position", [0.64 0 0.36 1], "BorderType", "none"), ColorMode="user", ...
        ColorLimits=rr_lim, BranchColorData=nan(numel(a_br), 1), LinkColorData=nan(numel(sv_comp), 1), ...
        ColorbarLabel="|V| [pu]", TitleFormat="");     % the title is the number of violations (show)
    G_net.ax.Tag = "Network";
    G_chart.link(G_net);
    rm_size  = mean(G_net.MarkerSizeRange) * (0.5 + rm_Pcomp / max([rm_Pcomp(:); eps]));   % [pt]
    rm_width = 1 + 4 * rm_Pbr / max([rm_Pbr(:); eps]);     % from 1 (no flow) to 5 (the largest |P|)

    % the playback bar of the diagram calls set_time only; the TimeChanged callback of the
    % chart (also when the diagram moves it through the link) draws the iteration in the
    % title and the diagram. The callback reaches the diagram through a weak reference, so
    % that saving the figure does not save the graphs with it.
    wr_net   = matlab.lang.WeakReference(G_net);
    sct_draw = struct("rv_k", rv_k, "rm_Vabs", rm_Vabs, "rm_size", rm_size, ...
        "rm_width", rm_width, "lm_out", lm_out, "sv_tag", sv_tag);
    G_chart.TimeChangedFcn = @(G, data) show_iteration(G, wr_net, sct_draw, data.Index);
    G_chart.set_time(rv_k(end));
end


function show_iteration(G_chart, wr_net, sct_draw, k)
% Draw iteration k (index into sct_iteration) after set_time of the chart G_chart: the
% title of the chart, and the colors, sizes, widths, violations and title of the diagram
% held by the weak reference wr_net (only the chart once it is deleted).
    arguments (Input)
        G_chart              % The chart whose time moved. <@Type> GraphChart
        wr_net               % Weak reference to the diagram. <@Type> matlab.lang.WeakReference
        sct_draw (1,1) struct  % Iteration numbers and the per-iteration columns to draw.
        k (1,1) double       % Index of the iteration shown.
    end
    n_it = numel(sct_draw.rv_k);
    title(G_chart.ax(1).Parent, sprintf("OPF iteration %d (%d of %d)", sct_draw.rv_k(k), k, n_it));
    G_net = wr_net.Handle;
    if isempty(G_net) || ~isvalid(G_net)
        return
    end
    G_net.BusColorData = sct_draw.rm_Vabs(:,k);
    G_net.ComponentMarkerSize = sct_draw.rm_size(:,k);
    G_net.BranchLineWidth = sct_draw.rm_width(:,k);
    G_net.clear_selection();
    if any(sct_draw.lm_out(:,k))
        G_net.select(sct_draw.sv_tag(sct_draw.lm_out(:,k)));
    end
    title(G_net.ax, sprintf("violations: %d", nnz(sct_draw.lm_out(:,k))));
end
