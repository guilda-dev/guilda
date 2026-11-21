function make_part4_spring_animations(opt)
% Make the spring-mass animations of the Part 4 lecture notes (part4-spring-mass-model.html).
%
% All cases use network.Tutorial6bus (four classical generators, G3 and G4 run as motors,
% 50 Hz) and only GUILDA itself: Scenario events, net.simulate and plot_spring_model of the
% result, with plot_trajectory-style charts below that follow the time (link). They are
% the scenarios of the spring-mass presentation at IEEJ 2026.
%
% Writes into _GUILDAdocPages/images/lecture/part4/ (or OutDir), each with a -poster.png:
%   swing-no-governor.mp4   (1) at t = 1 s G3 and G4 take 0.1 pu more, no governor:
%                               the frequency deviation stays
%   swing-governor.mp4      (2) the same with governors (gov-LPT3) and an integral
%                               (agc-PI) on G1 and G2: the frequency comes back
%   swing-out-of-step.mp4   (3) at t = 1 s G3 and G4 take 0.3 pu more, governors without
%                               integral, no damping on the motors: G3 and G4 fall out of
%                               step; each is tripped when it has stopped (speed 0); the
%                               video ends at t = 8 s, shortly after both have stopped
%   voltage-collapse.mp4    (4) G4 replaced by a constant-power load L4; from t = 1 s G3 and
%                               L4 take more and more (ramp to 0.3 pu at 20 s), governors and
%                               integral on G1 and G2: the voltage at bus 4 collapses; the
%                               phasor plane (left) and the surface z = log|V| (right)
%   swing-voltage-collapse-3d.gif  the same case on the surface z = log|V| only, as a small
%                               GIF at 10 frames/s for the About tab of index.html (no poster)
%
% The node labels are G1-G4 (and L4), the springs are thin, the tick text of the polar grid
% (ShowTickLabel) and the legend of the arrows are hidden, the Iq arrows are shown only in
% the voltage collapse (ArrowScaleQ = 0 in the others), and the time is in the title. Each
% frame is printed at a fixed size, all frames are cropped to one box, and the video is
% encoded by ffmpeg (H.264, yuv420p, faststart) when it is installed, otherwise by
% VideoWriter (MPEG-4).
%
% Run after GUILDA (the path) with R2026a:
%   addpath("notes/lecture-anim"); make_part4_spring_animations();
%   make_part4_spring_animations(Case="governor");   % one case only
    arguments (Input)
        opt.OutDir (1,1) string = ""          % Output folder; "" for _GUILDAdocPages/images/lecture/part4.
        opt.Case (1,:) string {mustBeMember(opt.Case, ["no-governor", "governor", "out-of-step", "voltage-collapse", "voltage-collapse-3d"])} ...
            = ["no-governor", "governor", "out-of-step", "voltage-collapse", "voltage-collapse-3d"]  % Cases to make.
        opt.Resolution (1,1) double {mustBePositive} = 160     % [dpi] Resolution of the frames.
    end
    s_out = opt.OutDir;
    if s_out == ""
        s_root = fileparts(fileparts(fileparts(mfilename("fullpath"))));   % notes/lecture-anim -> notes -> root
        s_out = fullfile(s_root, "_GUILDAdocPages", "images", "lecture", "part4");
    end
    for s_case = opt.Case
        [res, sct] = simulate_case(s_case);
        if s_case == "voltage-collapse-3d"
            % the funnel only, small, for the About tab
            fig = new_figure([11, 10.5]);
            tl = tiledlayout(fig, 1, 1, Padding="tight");
            G3 = res.plot_spring_model(Dimension=3, Parent=nexttile(tl));
            style_spring(G3, sct);
            G3.RMin = 0.3;                  % a shallow funnel: the nodes fill more of the picture
            rv_frame = 0:0.1:res.rv_t(end); % real time at 10 frames/s
            opt_gif = opt;
            opt_gif.Resolution = 110;       % about 470 pixels wide, the slot of the About tab
            write_animation(fig, {G3}, rv_frame, 10, @(t) sprintf("t = %.1f s", t), fullfile(s_out, "swing-" + s_case), "gif", opt_gif);
            continue
        end
        if s_case == "voltage-collapse"
            fig = new_figure([24, 13]);
            tl = tiledlayout(fig, 6, 5, TileSpacing="compact", Padding="compact");
            ax = nexttile(tl, 1, [4 2]);
            ax3 = nexttile(tl, 3, [6 3]);
            c_ax = {nexttile(tl, 21, [1 2]), nexttile(tl, 26, [1 2])};
        else
            fig = new_figure([11, 13]);
            tl = tiledlayout(fig, 6, 1, TileSpacing="compact", Padding="compact");
            ax = nexttile(tl, [4 1]);
            c_ax = {nexttile(tl), nexttile(tl)};
        end
        G = res.plot_spring_model(Parent=ax);
        style_spring(G, sct);
        c_G = {G};
        if s_case == "voltage-collapse"
            G3 = res.plot_spring_model(Dimension=3, Parent=ax3);
            style_spring(G3, sct);
            G.link(G3);
            c_G{end+1} = G3; %#ok<AGROW>
        end
        add_charts(G, res, sct, c_ax);
        rv_frame = 0:0.05:min(res.rv_t(end), sct.r_tEnd);    % real time at 20 frames/s
        write_animation(fig, c_G, rv_frame, 20, sct.f_title, fullfile(s_out, "swing-" + s_case), "mp4", opt);
    end
end

function [res, sct] = simulate_case(s_case)
% Build the network of a case, simulate it and return the result and the drawing data.
    arguments (Input)
        s_case (1,1) string  % Case name (see the help of the main function).
    end
    arguments (Output)
        res  % ResultODE.
        sct (1,1) struct  % Drawing data: sv_gen, sv_label, rm_color, f_title, sv_load, r_tEnd, s_legend.
    end
    net = network.Tutorial6bus();
    sct.sv_gen = "B00" + (1:4)' + "SG1";
    sct.sv_load = strings(0, 1);
    sct.f_title = @(t) sprintf("t = %.2f s", t);
    sct.r_tEnd = 20;        % [s] end of the video and of the time axes
    sct.s_legend = "northeast";   % location of the legend of the frequency chart
    % droop 5 %, first-order lag 3 s, no rate or position limit: Pm = (Pref - 20 omega)/(1 + 3s)
    sct_gov = struct(Prate=1, PLM=1000, droop=5, Tg=0, Ts=3, ...
        rate_max=Inf, rate_min=-Inf, pos_max=Inf, pos_min=-Inf);
    switch s_case
        case "no-governor"
            sc = net.add_scenario("scenario", Time=[0, 20]);
            sc.add_input("B003SG1", "Pmech", -0.1, [1, 20]);
            sc.add_input("B004SG1", "Pmech", -0.1, [1, 20]);
            res = net.simulate("scenario", Progress="none", SampleTime=0.01);

        case "governor"
            add_governors(net, sct_gov, true);
            sc = net.add_scenario("scenario", Time=[0, 20]);
            sc.add_input("B003SG1", "Pmech", -0.1, [1, 20]);
            sc.add_input("B004SG1", "Pmech", -0.1, [1, 20]);
            res = net.simulate("scenario", Progress="none", SampleTime=0.01);

        case "out-of-step"
            add_governors(net, sct_gov, false);
            for i = 3:4
                net.a_Bus{i}.a_Component{1}.tab_parameter.dynamics.D = 0;   % no damping on the motors
            end
            net.initialize();
            sc = net.add_scenario("scenario", Time=[0, 20]);
            sc.add_input("B003SG1", "Pmech", -0.3, [1, 20]);
            sc.add_input("B004SG1", "Pmech", -0.3, [1, 20]);
            % first run: the time at which each motor has stopped (omega = -1 pu)
            res = net.simulate("scenario", Time=[0, 10], Progress="none", StopOnOutOfStep=false, MaxStep=0.005);
            tab = res.get_trajectory("omega");
            for i = 3:4
                rv_w = tab.(sct.sv_gen(i));
                k = find(rv_w <= -1, 1);
                sc.add_trip(sct.sv_gen(i), interp1(rv_w(k-1:k), tab.t(k-1:k), -1));
            end
            % second run: the stopped motors are tripped
            res = net.simulate("scenario", Progress="none", StopOnOutOfStep=false, MaxStep=0.005, SampleTime=0.01);
            sct.r_tEnd = 8;     % shortly after both motors have stopped (7.6 s)
            sct.s_legend = "none";   % no free corner (the lines have the colors of the nodes)

        case {"voltage-collapse", "voltage-collapse-3d"}
            net.a_Bus{4}.remove_component("B004SG1");
            ld = net.a_Bus{4}.add_component("load-power", P=-0.8, Q=-0.2);
            add_governors(net, sct_gov, true);
            sc = net.add_scenario("scenario", Time=[0, 20]);
            rm_ramp = [0, 0; 19, -0.3];          % [s from t = 1, pu]: 0.3 pu more at t = 20 s
            sc.add_input("B003SG1", "Pmech", rm_ramp, [1, 20]);
            sc.add_input(ld.s_tag, "Pload", rm_ramp, [1, 20]);
            sct_warn = warning("off");           % the solver stops at the collapse
            res = net.simulate("scenario", Progress="none", SampleTime=0.01);
            warning(sct_warn);
            sct.sv_gen = sct.sv_gen(1:3);
            sct.sv_load = string(ld.s_tag);
            sct.f_title = @(t) sprintf("t = %.2f s   \\DeltaP = %.3f pu", t, 0.3*min(max((t - 1)/19, 0), 1));
    end
    sct.rm_color = [0.85 0.15 0.10; 0 0 0.85; 0.15 0.60 0.10; 0 0 0];   % G1 red, G2 blue, G3 green, G4 black
    sct.sv_label = "G" + (1:numel(sct.sv_gen))';
end

function add_governors(net, sct_gov, l_integral)
% Governors on G1 and G2 and, with l_integral, an integral of the speed on each (agc-PI).
    arguments (Input)
        net                     % Tutorial6bus network.
        sct_gov (1,1) struct    % Parameters of gov-LPT3.
        l_integral (1,1) logical % Add agc-PI (kP = 0, kI = 4) to each of G1 and G2.
    end
    for i = 1:2
        gen = net.a_Bus{i}.a_Component{1};
        gen.set_governor("gov-LPT3", parameter=sct_gov);
        if l_integral
            evalc("net.add_global_controller(""agc-PI"", {gen}, parameter=struct(kP=0, kI=4));");
        end
    end
    net.initialize();
end

function style_spring(G, sct)
% Node labels G1-G4 (L4), colors of the generators on their nodes and buses, node sizes
% from the inertia, thin springs and no tick text on the polar grid.
    arguments (Input)
        G  % GraphSpring2D or GraphSpring3D.
        sct (1,1) struct  % Drawing data of simulate_case.
    end
    tab = G.tab_element;
    sv_node = tab.Tag(tab.Kind == "node");
    G.NodeLabel = repmat("", numel(sv_node), 1);
    rv_M = [10, 8, 6, 6];
    for i = 1:numel(sct.sv_gen)
        s_bus = extractBefore(sct.sv_gen(i), "SG");
        G.set_style(sct.sv_gen(i), Label=sct.sv_label(i), Color=sct.rm_color(i, :), MarkerSize=1.2*rv_M(i));
        G.set_style(s_bus, Color=sct.rm_color(i, :));
    end
    for s_load = sct.sv_load'
        G.set_style(extractBefore(s_load, "L"), Label="L4", MarkerSize=8);   % the bus of the load
    end
    G.EdgeLineWidth = repmat(0.6, numel(G.EdgeLineWidth), 1);
    G.ShowLegend = false;        % the nodes turn through the whole plane; the captions explain the arrows
    if isempty(sct.sv_load)
        G.ArrowScaleQ = 0;       % P arrows only, as on the slides (the collapse keeps Iq: the inward force)
    end
    if isa(G, "GraphSpring2D")
        G.ShowTickLabel = false;   % no angle or radius numbers
        set(G.ax, XLim=[-1.65, 1.65], YLim=[-1.65, 1.65]);
    end
end

function add_charts(G, res, sct, c_ax)
% Frequency deviation [Hz] and mechanical power below the picture, with a cursor at the time.
    arguments (Input)
        G  % GraphSpring2D of the case.
        res  % ResultODE.
        sct (1,1) struct  % Drawing data of simulate_case.
        c_ax (1,2) cell  % Axes of the two charts.
    end
    r_Hz = 50;
    tab_w = res.get_trajectory("omega");
    tab_P = res.get_trajectory("Pmech");
    rv_t = tab_w.t';
    n_gen = numel(sct.sv_gen);
    sct_f.rv_t = rv_t;
    sct_f.sct_panel = struct("s_title", "Frequency deviation", "s_xlabel", "", "s_ylabel", "\Deltaf [Hz]", ...
        "rv_xlim", [0, sct.r_tEnd], "l_time", true, "s_legendLocation", sct.s_legend);
    sct_f.sct_series = struct("rv_x", rv_t, "rm_y", r_Hz*tab_w{:, sct.sv_gen}, "sv_tag", sct.sv_label, ...
        "rm_color", sct.rm_color(1:n_gen, :), "r_lineWidth", 1.2);
    C1 = GraphChart(sct_f, Parent=c_ax{1});

    sct_p = sct_f;
    sct_p.sct_panel.s_title = "Mechanical power";
    sct_p.sct_panel.s_xlabel = "t [s]";
    sct_p.sct_panel.s_ylabel = "P_m [pu]";
    sct_p.sct_panel.s_legendLocation = "none";
    sct_p.sct_series.rm_y = tab_P{:, sct.sv_gen};
    if ~isempty(sct.sv_load)
        sct_p.sct_panel.s_title = "Mechanical power and load";
        sct_p.sct_panel.s_ylabel = "P [pu]";
        tab_L = res.get_trajectory("Pload");
        sct_p.sct_series(2) = struct("rv_x", rv_t, "rm_y", tab_L{:, sct.sv_load}, "sv_tag", "L4", ...
            "rm_color", [0 0 0], "r_lineWidth", 1.2);
        sct_p.sct_series(2).s_lineStyle = "--";
    end
    C2 = GraphChart(sct_p, Parent=c_ax{2});
    G.link(C1);
    G.link(C2);
end

function fig = new_figure(rr_cm)
% White figure of the given size [cm] in the font of the lecture graphs.
    arguments (Input)
        rr_cm (1,2) double  % [cm] Width and height.
    end
    arguments (Output)
        fig (1,1) matlab.ui.Figure  % Hidden figure.
    end
    sr_font = ["Arial Unicode MS", "Arial", "Helvetica"];
    s_font = sr_font(find(ismember(sr_font, string(listfonts)), 1));
    fig = figure(Visible="off", Color="w", Units="centimeters", Position=[2, 2, rr_cm], ...
        PaperPositionMode="auto", DefaultAxesFontName=s_font, DefaultTextFontName=s_font, ...
        DefaultAxesFontSize=8, DefaultTextFontSize=8, DefaultAxesTitleFontSizeMultiplier=1);
    try
        theme(fig, "light");
    catch
    end
end

function write_animation(fig, c_G, rv_frame, r_fps, f_title, s_base, s_format, opt)
% Print every frame at a fixed size, crop all frames to the same box around the drawing,
% and write the video and the poster PNG (the last frame).
    arguments (Input)
        fig (1,1) matlab.ui.Figure  % Figure of the graphs.
        c_G cell                    % Spring pictures, linked to each other and to the charts; the first is moved.
        rv_frame (1,:) double       % [s] Time of each frame.
        r_fps (1,1) double          % [1/s] Frames per second.
        f_title (1,1) function_handle  % Title of the figure (the tiled layout) at time t.
        s_base (1,1) string         % Output path without extension.
        s_format (1,1) string {mustBeMember(s_format, ["mp4", "gif"])}  % "mp4" (with a poster PNG) or "gif" (no poster).
        opt (1,1) struct            % Options of the main function.
    end
    s_png = string(tempname) + ".png";
    c_tmp = onCleanup(@() delete_if(s_png));
    n_frame = numel(rv_frame);
    c_img = cell(1, n_frame);
    for i_frame = 1:n_frame
        c_G{1}.set_time(rv_frame(i_frame));       % the linked pictures and charts follow
        for k = 1:numel(c_G)
            title(c_G{k}.ax, "");
        end
        title(c_G{1}.ax.Parent, f_title(rv_frame(i_frame)), FontWeight="bold", FontSize=11);   % on the tiled layout
        drawnow;
        print(fig, s_png, "-dpng", "-r" + opt.Resolution);
        c_img{i_frame} = imread(s_png);
    end
    close(fig);
    % the printed size can differ by a pixel between frames: pad all to the largest
    rm_size = cell2mat(cellfun(@(m) [size(m, 1), size(m, 2)], c_img(:), "UniformOutput", false));
    rv_max = max(rm_size, [], 1);
    lm_ink = false(rv_max);
    for i_frame = 1:n_frame
        m = c_img{i_frame};
        c_img{i_frame} = uint8(255) * ones([rv_max, 3], "uint8");
        c_img{i_frame}(1:size(m, 1), 1:size(m, 2), :) = m;
        lm_ink = lm_ink | any(c_img{i_frame} < 245, 3);
    end

    % one crop box for all frames: the drawn area with a white margin, 16-pixel multiples
    % (VideoWriter on macOS writes broken frames for other widths)
    n_pad = 10;
    iv_r = find(any(lm_ink, 2));
    iv_c = find(any(lm_ink, 1));
    r1 = max(1, iv_r(1) - n_pad);  r2 = min(size(lm_ink, 1), iv_r(end) + n_pad);
    c1 = max(1, iv_c(1) - n_pad);  c2 = min(size(lm_ink, 2), iv_c(end) + n_pad);
    n_h = 16*ceil((r2 - r1 + 1)/16);
    n_w = 16*ceil((c2 - c1 + 1)/16);
    f_crop = @(m) pad_white(m(r1:r2, c1:c2, :), n_h, n_w);
    n_hold = round(1.5 * r_fps);    % hold the last frame for 1.5 s
    if s_format == "gif"
        for i_frame = 1:n_frame
            [m_ind, m_map] = rgb2ind(f_crop(c_img{i_frame}), 64, "nodither");
            r_delay = (1 + (i_frame == n_frame) * n_hold) / r_fps;
            if i_frame == 1
                imwrite(m_ind, m_map, s_base + ".gif", "gif", LoopCount=Inf, DelayTime=r_delay);
            else
                imwrite(m_ind, m_map, s_base + ".gif", "gif", WriteMode="append", DelayTime=r_delay);
            end
        end
        return
    end
    imwrite(f_crop(c_img{end}), s_base + "-poster.png");
    s_ffmpeg = find_ffmpeg();
    if s_ffmpeg ~= ""
        % H.264 (libx264, yuv420p) with the index at the start, for playing in browsers
        s_dir = string(tempname);
        mkdir(s_dir);
        c_dir = onCleanup(@() rmdir(s_dir, "s"));
        i_out = 0;
        for i_frame = 1:n_frame
            m_img = f_crop(c_img{i_frame});
            for r = 1:(1 + (i_frame == n_frame) * n_hold)
                i_out = i_out + 1;
                imwrite(m_img, fullfile(s_dir, sprintf("f%05d.png", i_out)));
            end
        end
        s_cmd = sprintf('"%s" -v error -y -framerate %g -i "%s" -c:v libx264 -preset slow -crf 26 -pix_fmt yuv420p -movflags +faststart "%s"', ...
            s_ffmpeg, r_fps, fullfile(s_dir, "f%05d.png"), s_base + ".mp4");
        [i_status, s_msg] = system(s_cmd);
        if i_status ~= 0
            error("ffmpeg failed: %s", s_msg);
        end
    else
        vw = VideoWriter(s_base + ".mp4", "MPEG-4");
        vw.FrameRate = r_fps;
        vw.Quality = 75;
        open(vw);
        for i_frame = 1:n_frame
            m_img = f_crop(c_img{i_frame});
            for r = 1:(1 + (i_frame == n_frame) * n_hold)
                writeVideo(vw, m_img);
            end
        end
        close(vw);
    end
end

function m_out = pad_white(m_img, n_h, n_w)
% Put an image on a white canvas of n_h x n_w pixels (centred).
    arguments (Input)
        m_img (:,:,3) uint8  % RGB image.
        n_h (1,1) double     % Height of the canvas.
        n_w (1,1) double     % Width of the canvas.
    end
    arguments (Output)
        m_out (:,:,3) uint8  % Image on the canvas.
    end
    m_out = uint8(255) * ones(n_h, n_w, 3, "uint8");
    i_r = floor((n_h - size(m_img, 1))/2);
    i_c = floor((n_w - size(m_img, 2))/2);
    m_out(i_r + (1:size(m_img, 1)), i_c + (1:size(m_img, 2)), :) = m_img;
end

function s_ffmpeg = find_ffmpeg()
% Path of ffmpeg ("" when it is not installed).
    arguments (Output)
        s_ffmpeg (1,1) string  % Full path or "".
    end
    s_ffmpeg = "";
    for s_try = ["/opt/homebrew/bin/ffmpeg", "/usr/local/bin/ffmpeg", "/usr/bin/ffmpeg"]
        if isfile(s_try)
            s_ffmpeg = s_try;
            return
        end
    end
end

function delete_if(s_file)
% Delete a temporary file if it exists.
    arguments (Input)
        s_file (1,1) string  % Path of the file.
    end
    if isfile(s_file)
        delete(s_file);
    end
end
