function make_part2_flow_figure(opt)
% Make the figure of the IEEE 9-bus power flow in Part 2 of the lecture
% (_GUILDAdocPages/lecture/part2-power-flow.html, section "Reading the result").
%
% The power flow of network.IEEE9bus drawn by ResultPF.plot_diagram with the buses colored
% by |V| and the branches without color, as in the code example of the page.
%
% Writes _GUILDAdocPages/images/lecture/part2/ieee9-flow.png (or into OutDir). Run from the
% repository root with R2026a, e.g.
%   matlab -batch "GUILDA.addpath; addpath('notes/lecture-figures'); make_part2_flow_figure();"
    arguments (Input)
        opt.OutDir (1,1) string = ""                        % Output folder; "" for _GUILDAdocPages/images/lecture/part2.
        opt.Size (1,2) double {mustBePositive} = [570, 400]  % [px] Size of the figure.
        opt.Resolution (1,1) double {mustBePositive} = 192   % [dpi] Resolution of the PNG.
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
end
