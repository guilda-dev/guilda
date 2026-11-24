function G = plot_iteration(obj, opt)
% Draw the iterations of the AC optimal power flow as a chart of four panels.
%
% Draws sct_iteration (recorded by fmincon at every "AC OPF" run) as one GraphChart with
% four panels in a 2-by-2 grid against the iteration number, in rows: the objective (line
% tag "Fval"), the largest constraint violation on a log scale (tag "ConstrViolation"),
% P of each generator (a component whose P bounds differ; tags of the generators) and |V|
% of each bus (tags of the buses). The four panels are time panels whose times are the
% iteration numbers (sct_iteration.Iteration): set_time(k) moves the cursor of every
% panel to iteration k, and the TimeChangedFcn of the chart writes the title "OPF
% iteration k (i of n)" of the iteration shown (the last one at first). The chart has no
% playback bar, as its time only moves the cursor (see GraphChart). A line is found by
% its tag in G.tab_element, and the first row of the data tip of a line is its name (the
% tag, e.g. the generator or bus). The chart is drawn in the container Parent. "ELD" and
% "DC OPF" (linprog, quadprog) record no iterations and stop with
% GUILDA:ResultOPF:NoIteration. It reads only the stored result.
%
% <@Examples>
% ```matlab
% res = network.IEEE14bus().calculate_optimal_powerflow(Method="AC OPF");
% G = res.plot_iteration();
% G.set_time(3);                      % cursor and title at iteration 3
% G.tab_element                       % the lines: Fval, ConstrViolation, generators, buses
% G.set_style("B001", LineWidth=3);   % pick out the |V| of bus B001
% ```
%
% See also ResultOPF.sct_iteration, ResultOPF.plot_lmp, ResultPF.plot_convergence, GraphChart
    arguments (Input)
        obj
        opt.Parent = []  % Container (figure, uifigure, uipanel, uitab, uigridlayout) to draw in; [] for a new figure.
    end
    arguments (Output)
        G  % The four panels of the iterations (GraphChart).
    end
    sct = obj.sct_iteration;
    if ~isfield(sct, "Iteration") || isempty(sct.Iteration)
        error(msg("GUILDA:ResultOPF:NoIteration", string(obj.options.Method)))
    end
    if isempty(opt.Parent)
        opt.Parent = figure("Name", "OPF iterations of " + obj.s_network);
    end
    rv_k   = sct.Iteration;
    sv_bus = string(obj.tab_bus.Properties.RowNames);
    sv_gen = strings(1, 0);
    for s_var = string(fieldnames(sct.X)).'
        var = obj.OPFprob.Variables.(s_var);
        if ~ismember(s_var, sv_bus) && ismember(s_var, string(obj.tab_cub.Properties.RowNames)) ...
                && var.LowerBound(1) ~= var.UpperBound(1)
            sv_gen(end+1) = s_var; %#ok<AGROW>
        end
    end

    % four time panels of lines against the iteration number, so that the cursor marks
    % the iteration shown
    f_panel = @(s_ylabel, s_yscale) struct("s_xlabel", "iteration", "s_ylabel", s_ylabel, "s_yscale", s_yscale, ...
        "l_time", true, "s_legendLocation", "none");
    f_line  = @(i_panel, rm_y, sv_tag) struct("i_panel", i_panel, "rv_x", rv_k, "rm_y", rm_y, "sv_tag", sv_tag);
    sct_chart = struct("rv_t", rv_k, "s_title", "OPF iterations", "rv_grid", [2 2], ...
        "sct_panel", [f_panel("objective", "linear"), f_panel("largest constraint violation", "log"), ...
                      f_panel("P of the generators [pu]", "linear"), f_panel("|V| of the buses [pu]", "linear")], ...
        "sct_series", [f_line(1, sct.Fval(:), "Fval"), f_line(2, max(sct.ConstrViolation(:), realmin), "ConstrViolation"), ...
                       f_line(3, cell2mat(cellfun(@(s) sct.X.(s)(1,:).', cellstr(sv_gen(:)).', "UniformOutput", false)), sv_gen(:)), ...
                       f_line(4, cell2mat(cellfun(@(s) sct.X.(s)(2,:).', cellstr(sv_bus(:)).', "UniformOutput", false)), sv_bus(:))]);
    G = GraphChart(sct_chart, Parent=opt.Parent);
    G.TimeChangedFcn = @(G, data) title(G.ax(1).Parent, ...
        sprintf("OPF iteration %d (%d of %d)", rv_k(data.Index), data.Index, numel(rv_k)));
    G.set_time(rv_k(end));
end
