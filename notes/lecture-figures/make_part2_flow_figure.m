function make_part2_flow_figure(opt)
% Make the figures and the bus table of the IEEE 9-bus power flow in Part 2 of the lecture
% (_GUILDAdocPages/lecture/part2-power-flow.html, sections "Newton's method" and
% "Reading the result").
%
% The power flow of network.IEEE9bus drawn by ResultPF.plot_diagram with the buses colored
% by |V| and the branches without color, as in the code example of the page, and the
% single-line diagram of the same result (ResultPF.plot_single_line_diagram).
%
% Writes into _GUILDAdocPages/images/lecture/part2 (or into OutDir):
%   ieee9-flow.png         plot_diagram(BusColorMode="V", ColorMode="none")
%   ieee9-single-line.png  plot_single_line_diagram
% and prints the rows of the bus table of the page (HTML <tr> rows: bus, type, angle in
% degrees, |V|, P and Q injected in pu, 2 decimal places) from result.tab_bus and the
% types of net.get_pf_condition.
%
% Run from the repository root with R2026a, e.g.
%   matlab -batch "GUILDA.addpath; addpath('notes/lecture-figures'); make_part2_flow_figure();"
    arguments (Input)
        opt.OutDir (1,1) string = ""                        % Output folder; "" for _GUILDAdocPages/images/lecture/part2.
        opt.Size (1,2) double {mustBePositive} = [570, 400]  % [px] Size of the figure of plot_diagram.
        opt.Resolution (1,1) double {mustBePositive} = 192   % [dpi] Resolution of the PNG of plot_diagram.
        opt.ResolutionSingleLine (1,1) double {mustBePositive} = 400  % [dpi] Resolution of the single-line diagram (8.5 cm wide).
    end
    s_out = opt.OutDir;
    if s_out == ""
        s_root = fileparts(fileparts(fileparts(mfilename("fullpath"))));   % notes/lecture-figures -> notes -> root
        s_out = fullfile(s_root, "_GUILDAdocPages", "images", "lecture", "part2");
    end

    net = network.IEEE9bus();
    result = net.calculate_powerflow();
    fig = figure(Units="pixels", Position=[100, 100, opt.Size], Color="w");
    result.plot_diagram(BusColorMode="V", ColorMode="none", Parent=fig);
    drawnow;
    exportgraphics(fig, fullfile(s_out, "ieee9-flow.png"), Resolution=opt.Resolution, BackgroundColor="white");
    delete(fig);

    G = result.plot_single_line_diagram();
    drawnow;
    exportgraphics(G.ax(1), fullfile(s_out, "ieee9-single-line.png"), Resolution=opt.ResolutionSingleLine, BackgroundColor="white");
    delete(ancestor(G.ax(1), "figure"));

    % Rows of the bus table: the values are rounded half away from zero to 2 decimal places
    % (first to 6, so that a fixed 1.025 gives 1.03 whatever its last binary digit), and
    % -0.00 is written 0.00.
    sct_cond = net.get_pf_condition(Display=false);
    tab = result.tab_bus;
    fmt = @(r) strrep(sprintf("%.2f", round(round(r*1e6)/1e4)/100), "-", "−");
    for i = 1:height(tab)
        sv = [fmt(rad2deg(tab.Varg(i))), fmt(tab.V(i)), fmt(tab.P(i)), fmt(tab.Q(i))];
        sv(sv == "−0.00") = "0.00";
        fprintf('<tr><td>%s</td><td>%s</td><td class="lec2-num">%s</td><td class="lec2-num">%s</td><td class="lec2-num">%s</td><td class="lec2-num">%s</td></tr>\n', ...
            tab.Properties.RowNames{i}, sct_cond.Bus.Type(i), sv);
    end
end
