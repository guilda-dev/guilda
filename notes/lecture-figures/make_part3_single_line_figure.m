function make_part3_single_line_figure(opt)
% Make the single-line diagram of the IEEE 9-bus system in Part 3 of the lecture
% (_GUILDAdocPages/lecture/part3-time-simulation.html, section "Transient stability and the
% critical clearing time"), the system of the fault and governor simulations of that page.
%
% Draws network.IEEE9bus(LocalController=true) with PowerNetwork.plot_single_line_diagram
% (the topology; the controllers do not appear in the drawing).
%
% Writes _GUILDAdocPages/images/lecture/part3/ieee9-single-line.png (or into OutDir). Run
% from the repository root with R2026a, e.g.
%   matlab -batch "GUILDA.addpath; addpath('notes/lecture-figures'); make_part3_single_line_figure();"
    arguments (Input)
        opt.OutDir (1,1) string = ""                        % Output folder; "" for _GUILDAdocPages/images/lecture/part3.
        opt.Resolution (1,1) double {mustBePositive} = 400   % [dpi] Resolution of the PNG (the figure is 8.5 cm wide).
    end
    s_out = opt.OutDir;
    if s_out == ""
        s_root = fileparts(fileparts(fileparts(mfilename("fullpath"))));   % notes/lecture-figures -> notes -> root
        s_out = fullfile(s_root, "_GUILDAdocPages", "images", "lecture", "part3");
    end

    net = network.IEEE9bus(LocalController=true);
    G = net.plot_single_line_diagram();
    drawnow;
    exportgraphics(G.ax(1), fullfile(s_out, "ieee9-single-line.png"), Resolution=opt.Resolution, BackgroundColor="white");
    delete(ancestor(G.ax(1), "figure"));
end
