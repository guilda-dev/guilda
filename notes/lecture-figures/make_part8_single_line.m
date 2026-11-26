function make_part8_single_line(opt)
% Make the single-line diagrams of the systems in Part 8 of the lecture
% (_GUILDAdocPages/lecture/part8-controller-design.html): IEEE 9-bus (PSS, frequency
% control and retrofit control) and IEEE 68-bus (local LQR).
%
% network.IEEE9bus and network.IEEE68bus drawn by PowerNetwork.plot_single_line_diagram
% as GUILDA makes them. Writes ieee9-single-line.png and ieee68-single-line.png into
% _GUILDAdocPages/images/lecture/part8 (or into OutDir). Run from the repository root
% with R2026a, e.g.
%   matlab -batch "GUILDA.addpath; addpath('notes/lecture-figures'); make_part8_single_line();"
    arguments (Input)
        opt.OutDir (1,1) string = ""                        % Output folder; "" for _GUILDAdocPages/images/lecture/part8.
        opt.Resolution (1,2) double {mustBePositive} = [300, 200]   % [dpi] Resolution of the PNGs of IEEE 9-bus and IEEE 68-bus.
        opt.Size68 (1,2) double {mustBePositive} = [20, 13]         % [cm] Size of the figure of IEEE 68-bus.
    end
    s_out = opt.OutDir;
    if s_out == ""
        s_root = fileparts(fileparts(fileparts(mfilename("fullpath"))));   % notes/lecture-figures -> notes -> root
        s_out = fullfile(s_root, "_GUILDAdocPages", "images", "lecture", "part8");
    end
    % IEEE 68-bus is drawn in a wider figure than the default 8.5 cm, so that its labels
    % (4 pt, fixed by GUILDA beyond 30 buses) overlap less
    c_net = {network.IEEE9bus(), "ieee9-single-line.png", []; ...
             network.IEEE68bus(), "ieee68-single-line.png", opt.Size68};
    for k = 1:size(c_net, 1)
        h_fig = [];
        if ~isempty(c_net{k, 3})
            h_fig = figure(Color="w", Units="centimeters", Position=[2 2 c_net{k, 3}]);
        end
        G = c_net{k, 1}.plot_single_line_diagram(Parent=h_fig);
        drawnow;
        exportgraphics(G.ax, fullfile(s_out, c_net{k, 2}), Resolution=opt.Resolution(k), BackgroundColor="white");
        delete(ancestor(G.ax(1), "figure"));
    end
end
