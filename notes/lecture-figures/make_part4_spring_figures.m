function make_part4_spring_figures(opt)
% Make the still figures of Part 4 of the lecture (_GUILDAdocPages/lecture/part4-spring-mass-model.html).
%
% Writes into _GUILDAdocPages/images/lecture/part4/ (or OutDir):
%   tutorial6bus-single-line.png  ResultPF.plot_single_line_diagram of network.Tutorial6bus
%   power-flow-tutorial6.png      net.plot_spring_model() of network.Tutorial6bus after
%                                 net.initialize(), as in the code example of the page,
%                                 with the labels G1-G4 and the colours of the animations,
%                                 no bus labels, tick text or legend, enlarged around the points
%
% Run from the repository root with R2026a, e.g.
%   matlab -batch "GUILDA.addpath; addpath('notes/lecture-figures'); make_part4_spring_figures();"
    arguments (Input)
        opt.OutDir (1,1) string = ""                        % Output folder; "" for _GUILDAdocPages/images/lecture/part4.
        opt.Resolution (1,1) double {mustBePositive} = 192   % [dpi] Resolution of the PNGs.
    end
    s_out = opt.OutDir;
    if s_out == ""
        s_root = fileparts(fileparts(fileparts(mfilename("fullpath"))));   % notes/lecture-figures -> notes -> root
        s_out = fullfile(s_root, "_GUILDAdocPages", "images", "lecture", "part4");
    end

    net = network.Tutorial6bus();
    res = net.calculate_powerflow();
    G = res.plot_single_line_diagram();
    exportgraphics(G.ax(1), fullfile(s_out, "tutorial6bus-single-line.png"), Resolution=2*opt.Resolution, BackgroundColor="white");
    delete(ancestor(G.ax(1), "figure"));

    % the labels G1-G4 and the colours of the animations (make_part4_spring_animations), no
    % bus labels, enlarged around the points
    net.initialize();
    G = net.plot_spring_model();
    tab = G.tab_element;
    G.NodeLabel = repmat("", nnz(tab.Kind == "node"), 1);
    rm_color = [0.85 0.15 0.10; 0 0 0.85; 0.15 0.60 0.10; 0 0 0];   % G1 red, G2 blue, G3 green, G4 black
    for i = 1:4
        G.set_style("B00" + i + "SG1", Label="G" + i, Color=rm_color(i, :));
        G.set_style("B00" + i, Color=rm_color(i, :));
    end
    G.ShowTickLabel = false;     % the tick text outside the enlarged part is not clipped
    G.ShowLegend = false;        % the caption explains the arrows
    set(G.ax, XLim=[0.25, 1.75], YLim=[-1.0, 0.95]);
    fig = ancestor(G.ax(1), "figure");
    for ax = findall(fig, "Type", "axes")'
        ax.Toolbar.Visible = "off";
    end
    set(findall(fig, "Tag", "GUILDA:GraphBase:PlaybackBar"), Visible="off");
    drawnow;
    exportgraphics(G.ax(1), fullfile(s_out, "power-flow-tutorial6.png"), Resolution=opt.Resolution, BackgroundColor="white");
    delete(fig);
end
