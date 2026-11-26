function make_part7_single_line(opt)
% Make the single-line diagram of the IEEE 9-bus system in Part 7 of the lecture
% (_GUILDAdocPages/lecture/part7-continuation-power-flow.html, section "The PV curves of
% the IEEE 9-bus system"), the system of the continuation power flow on that page.
%
% network.IEEE9bus drawn by PowerNetwork.plot_single_line_diagram as GUILDA makes it.
% Writes _GUILDAdocPages/images/lecture/part7/ieee9-single-line.png (or into OutDir). Run
% from the repository root with R2026a, e.g.
%   matlab -batch "GUILDA.addpath; addpath('notes/lecture-figures'); make_part7_single_line();"
    arguments (Input)
        opt.OutDir (1,1) string = ""                        % Output folder; "" for _GUILDAdocPages/images/lecture/part7.
        opt.Resolution (1,1) double {mustBePositive} = 300   % [dpi] Resolution of the PNG.
    end
    s_out = opt.OutDir;
    if s_out == ""
        s_root = fileparts(fileparts(fileparts(mfilename("fullpath"))));   % notes/lecture-figures -> notes -> root
        s_out = fullfile(s_root, "_GUILDAdocPages", "images", "lecture", "part7");
    end
    G = network.IEEE9bus().plot_single_line_diagram();
    drawnow;
    exportgraphics(G.ax, fullfile(s_out, "ieee9-single-line.png"), Resolution=opt.Resolution, BackgroundColor="white");
    delete(ancestor(G.ax(1), "figure"));
end
