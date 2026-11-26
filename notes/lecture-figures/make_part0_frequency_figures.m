function make_part0_frequency_figures(opt)
% Make the frequency figures and network diagrams of Parts 0 and 1 of the lecture
% (_GUILDAdocPages/lecture/part0-introduction.html and part1-network-components.html).
%
% Part 0, section "Supply must match demand": network.Tutorial6bus (four classical
% generators with M = 10, 8, 6, 6 and D = 5 each, lossless lines, no governor or AVR;
% G3 and G4 run as synchronous motors) gets a constant-power load (load-power, P = Q = 0
% at the operating point) at bus 6. From t = 1 s the load draws 0.1 pu (add_input
% "Pload"). The figure shows the speed deviation omega of the four machines and the
% frequency deviation of each bus, (1/(2 pi f0)) d(Vangle)/dt, in pu. The dashed line is
% omega_s = -0.1/(D1 + D2 + D3 + D4) = -0.005 pu: the lines are lossless, so the
% electrical outputs of the machines add up to the load, and the sum of the swing
% equations has this value as its only synchronized steady state.
%
% Writes (into OutDir/part0 and OutDir/part1):
%   part0/frequency-sync.en.png, frequency-sync.ja.png   omega and bus frequencies
%   part0/tutorial6-diagram.png  net.plot_single_line_diagram of the network with the load
%   part0/ieee9-diagram.png      net.plot_single_line_diagram of network.IEEE9bus
%   part1/ieee9-diagram.png      the same diagram for Part 1
% The diagrams are drawn in a white figure of 6 cm x 5.4 cm (smaller than the 8.5 cm of
% plot_single_line_diagram, so that the 6 pt labels stay legible on the page).
% Run from the repository root with R2026a:
%   matlab -batch "GUILDA.addpath; addpath('notes/lecture-figures'); make_part0_frequency_figures();"
    arguments (Input)
        opt.OutDir (1,1) string = ""                        % Folder that holds part0/ and part1/; "" for _GUILDAdocPages/images/lecture.
        opt.Resolution (1,1) double {mustBePositive} = 192   % [dpi] Resolution of the plot PNGs (the diagrams get three times this).
    end
    s_out = opt.OutDir;
    if s_out == ""
        s_root = fileparts(fileparts(fileparts(mfilename("fullpath"))));   % notes/lecture-figures -> notes -> root
        s_out = fullfile(s_root, "_GUILDAdocPages", "images", "lecture");
    end

    % diagram of the IEEE 9-bus system as bundled
    net9 = network.IEEE9bus();
    G = net9.plot_single_line_diagram(Parent=diagram_figure(6.0, 5.4));
    drawnow;
    for s_part = ["part0", "part1"]
        exportgraphics(G.ax(1), fullfile(s_out, s_part, "ieee9-diagram.png"), Resolution=3*opt.Resolution, BackgroundColor="white");
    end
    delete(ancestor(G.ax(1), "figure"));

    % Tutorial6bus with a load at bus 6 that draws 0.1 pu from t = 1 s
    net = network.Tutorial6bus();
    ld = net.a_Bus{6}.add_component("load-power", P=0, Q=0, DX=0.1, DY=-0.1);   % off the line B005-B006
    net.initialize();
    G = net.plot_single_line_diagram(Parent=diagram_figure(6.0, 5.4));
    drawnow;
    exportgraphics(G.ax(1), fullfile(s_out, "part0", "tutorial6-diagram.png"), Resolution=3*opt.Resolution, BackgroundColor="white");
    delete(ancestor(G.ax(1), "figure"));

    r_step = 0.1;
    r_tEnd = 15;
    sc = net.add_scenario("step", Time=[0, r_tEnd]);
    sc.add_input(ld.s_tag, "Pload", -r_step, [1, r_tEnd]);
    res = net.simulate("step", Progress="none", SampleTime=0.005);

    tab_w = res.get_trajectory("omega");
    tab_a = res.get_trajectory("Vangle");
    r_f0 = net.tab_parameter.base.Hz;
    n_gen = width(tab_w) - 1;
    % bus frequency from the angle, separately before and after the step (the angle jumps at t = 1 s)
    rv_t = tab_a.t;
    rm_a = unwrap(tab_a{:, 2:end});
    rm_f = NaN(size(rm_a));
    iv_edge = [0; find(diff(rv_t) == 0); numel(rv_t)];
    for k = 1:numel(iv_edge) - 1
        iv = iv_edge(k) + 1:iv_edge(k + 1);
        if numel(iv) > 2
            [~, rm_d] = gradient(rm_a(iv, :), 1, rv_t(iv));
            rm_f(iv, :) = rm_d / (2*pi*r_f0);
        end
    end
    r_D = 0;
    for i = 1:n_gen
        r_D = r_D + net.a_Bus{i}.a_Component{1}.tab_parameter.dynamics.D;
    end
    r_ws = -r_step / r_D;
    fprintf("omega_s = %.5f pu; simulated at t = %g s: omega %s, bus %s\n", r_ws, r_tEnd, ...
        mat2str(tab_w{end, 2:end}, 4), mat2str(rm_f(end, :), 4));

    sct_txt.en = struct(t="Time (s)", y="Frequency deviation (pu)", gen="machine ", bus="buses 1-6", ws="\omega_s");
    sct_txt.ja = struct(t="時間 (s)", y="周波数のずれ (pu)", gen="同期機 ", bus="母線 1〜6", ws="\omega_s");
    for s_lang = ["en", "ja"]
        txt = sct_txt.(s_lang);
        fig = figure(Units="pixels", Position=[100, 100, 760, 400], Color="w");
        ax = axes(fig);
        hold(ax, "on");
        h_gen = plot(ax, tab_w.t, tab_w{:, 2:end}, LineWidth=1.6);
        h_bus = plot(ax, rv_t, rm_f, Color=[0.2 0.2 0.2 0.7], LineWidth=0.6);   % on top: thin dark lines
        h_ws = yline(ax, r_ws, "--k", LineWidth=1);
        hold(ax, "off");
        xlim(ax, [0, r_tEnd]);
        ylim(ax, [-0.007, 0.001]);
        grid(ax, "on");
        box(ax, "on");
        xlabel(ax, txt.t);
        ylabel(ax, txt.y);
        sv_leg = [txt.gen + string(1:n_gen), txt.bus, txt.ws];
        lg = legend(ax, [h_gen; h_bus(1); h_ws], sv_leg, Location="northeast", NumColumns=2);
        if s_lang == "ja"
            set(ax, FontName="Hiragino Sans");
            lg.FontName = "Hiragino Sans";
        end
        drawnow;
        exportgraphics(fig, fullfile(s_out, "part0", "frequency-sync." + s_lang + ".png"), Resolution=opt.Resolution, BackgroundColor="white");
        delete(fig);
    end
end

function fig = diagram_figure(r_width, r_height)
% White figure of the given size [cm] for a single-line diagram.
    arguments (Input)
        r_width (1,1) double {mustBePositive}   % [cm] Width.
        r_height (1,1) double {mustBePositive}  % [cm] Height.
    end
    arguments (Output)
        fig  % Figure.
    end
    fig = figure(Color="w", Units="centimeters", Position=[2, 2, r_width, r_height]);
end
