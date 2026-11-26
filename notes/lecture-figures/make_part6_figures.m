function make_part6_figures(opt)
% Make the single-line diagram of Part 6 of the lecture
% (_GUILDAdocPages/lecture/part6-optimal-power-flow.html).
%
% Every OPF of the page runs on network.IEEE9bus(LocalController=true). The script draws
% its single-line diagram with PowerNetwork.plot_single_line_diagram, adds the names
% G1-G3 of the generators next to their buses, and writes ieee9-single-line.png.
%
% Writes into _GUILDAdocPages/images/lecture/part6/ (or OutDir). Run from the repository
% root with R2026a, e.g.
%   matlab -batch "GUILDA.addpath; addpath('notes/lecture-figures'); make_part6_figures();"
    arguments (Input)
        opt.OutDir (1,1) string = ""                        % Output folder; "" for _GUILDAdocPages/images/lecture/part6.
        opt.Resolution (1,1) double {mustBePositive} = 300   % [dpi] Resolution of the PNG.
    end
    s_out = opt.OutDir;
    if s_out == ""
        s_root = fileparts(fileparts(fileparts(mfilename("fullpath"))));   % notes/lecture-figures -> notes -> root
        s_out = fullfile(s_root, "_GUILDAdocPages", "images", "lecture", "part6");
    end

    net = network.IEEE9bus(LocalController=true);
    G = net.plot_single_line_diagram();
    ax = G.ax(1);
    h_fig = ancestor(ax, "figure");
    sct = G.get_layout();
    for k = 1:3
        s_bus = "B00" + k;
        rv_bus = sct.tab_bus{sct.tab_bus.Tag == s_bus, ["X","Y"]};
        rv_d = sct.tab_component{startsWith(sct.tab_component.Tag, s_bus), ["DX","DY"]};
        rv_xy = rv_bus + 2.5*rv_d(1, :);                   % beyond the generator symbol
        text(ax, rv_xy(1), rv_xy(2), "G" + k, FontSize=6.5, FontWeight="bold", ...
            HorizontalAlignment="center", VerticalAlignment="middle");
    end
    r_pad = 0.04*diff(ax.XLim);                            % room for the names at the sides
    ax.XLim = ax.XLim + [-r_pad, r_pad];
    ax.YLim = ax.YLim + [-r_pad, 0];
    drawnow;
    exportgraphics(ax, fullfile(s_out, "ieee9-single-line.png"), Resolution=opt.Resolution, BackgroundColor="white");
    delete(h_fig);
end
