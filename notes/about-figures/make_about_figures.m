function make_about_figures(opt)
% Make the figures of "Output of GUILDA" in the About tab of _GUILDAdocPages/index.html.
%
% All come from the IEEE 14-bus example of the About tab: a fault at bus B008 from 1 s to
% 1.05 s, simulated for 10 s, and the linear model at the operating point.
%
% Writes into _GUILDAdocPages/images/about/ (or OutDir):
%   output-frequency.png        frequency deviation omega of the generators
%   output-voltage.png          voltage magnitudes of the buses
%   output-network-diagram.png  network diagram at t = 1.02 s, during the fault
%   output-eigenvalues.png      eigenvalues of the linear model
%   output-model-gui.png        model GUI of the network (net.launch_gui)
%
% The playback bar of the graphs (a UI component) is not in the PNG files. The model GUI
% is a uifigure, so run it with a display (not matlab -batch), with R2026a:
%   addpath("notes/about-figures"); make_about_figures();
%   make_about_figures(Figure="eigenvalues");   % one figure only
    arguments (Input)
        opt.OutDir (1,1) string = ""     % Output folder; "" for _GUILDAdocPages/images/about.
        opt.Figure (1,:) string {mustBeMember(opt.Figure, ["frequency", "voltage", "network-diagram", "eigenvalues", "model-gui"])} ...
            = ["frequency", "voltage", "network-diagram", "eigenvalues", "model-gui"]  % Figures to make.
        opt.Size (1,2) double {mustBePositive} = [720, 460]   % [px] Size of each figure (the network diagram: about square).
        opt.Resolution (1,1) double {mustBePositive} = 144    % [dpi] Resolution of the plots (the model GUI: screen pixels).
    end
    s_out = opt.OutDir;
    if s_out == ""
        s_root = fileparts(fileparts(fileparts(mfilename("fullpath"))));   % notes/about-figures -> notes -> root
        s_out = fullfile(s_root, "_GUILDAdocPages", "images", "about");
    end

    net = network.IEEE14bus;
    sc = net.add_scenario("fault", Time=[0, 10]);
    sc.add_fault("B008", [1, 1.05]);
    if any(ismember(["frequency", "voltage", "network-diagram"], opt.Figure))
        res = net.simulate("fault");
    end

    for s_fig = opt.Figure
        s_file = fullfile(s_out, "output-" + s_fig + ".png");
        if s_fig == "model-gui"
            fig = uifigure(Position=[100, 100, opt.Size]);
            net.launch_gui(fig);
            drawnow;
            pause(3);                    % the overlay scroll bars fade out
            exportapp(fig, s_file);
            delete(fig);
            continue
        end
        rv_size = opt.Size;
        if s_fig == "network-diagram"
            rv_size = [opt.Size(1), round(0.85*opt.Size(1))];   % the diagram is about square
        end
        fig = figure(Units="pixels", Position=[100, 100, rv_size], Color="w");
        switch s_fig
            case "frequency"
                res.plot_trajectory(Quantity="omega", Parent=fig);
            case "voltage"
                res.plot_trajectory(Parent=fig);
            case "network-diagram"
                G = res.plot_diagram(Parent=fig);
                G.set_time(1.02);
            case "eigenvalues"
                sys = net.get_sys();
                sys.plot_eigenvalue(Parent=fig);
        end
        drawnow;
        exportgraphics(fig, s_file, Resolution=opt.Resolution, BackgroundColor="white");
        delete(fig);
    end
end
