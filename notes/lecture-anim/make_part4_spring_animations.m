function make_part4_spring_animations(opt)
% Make the spring-mass animations of the Part 4 lecture notes (part4-spring-mass-model.html).
%
% All cases use network.Tutorial6bus (four classical generators, G3 and G4 run as motors,
% 50 Hz) and only GUILDA itself: Scenario events, net.simulate, plot_spring_model and
% plot_trajectory of the result. They are the scenarios of the spring-mass presentation
% at IEEJ 2026.
%
% Writes into _GUILDAdocPages/images/lecture/part4/ (or OutDir), each with a -poster.png
% (the last frame):
%   swing-no-governor.mp4   (1) at t = 1 s G3 and G4 take 0.1 pu more, no governor:
%                               the frequency deviation stays
%   swing-governor.mp4      (2) the same with governors (gov-LPT3) and an integral
%                               (agc-PI) on G1 and G2: the frequency comes back
%   swing-out-of-step.mp4   (3) at t = 1 s G3 and G4 take 0.3 pu more, governors without
%                               integral, no damping on the motors: G3 and G4 fall out of
%                               step; each is tripped when it has stopped (speed 0); the
%                               result and the video end at t = 8 s, shortly after both
%                               have stopped
%   swing-voltage-collapse.mp4  (4) G4 replaced by a load L4 at bus 4; from t = 1 s G3 and
%                               L4 take more and more (ramp to 0.3 pu at 20 s), governors and
%                               integral on G1 and G2. With L4 as a constant-power load
%                               the solver stops at the collapse (t = 7.29 s). The video
%                               shows a second run in which L4 is an impedance load
%                               (load-impedance) whose R and X are given by add_input: up to
%                               3 samples before that stop the impedance of L4 in the first
%                               run, then an admittance that keeps growing at its last
%                               relative rate (exponentially, same angle).
%                               It ends when |V| of bus 4 is 0.07 pu; the last frame is held
%                               for 3 s. Left: the phasor plane and, below it,
%                               plot_trajectory of |V| of the buses and of P of bus 4 (the
%                               power L4 receives); right: the surface z = log|V|.
%
% Cases 1-3 are the default drawing [G, G_chart] = result.plot_spring_model(): the picture
% on the left and the side chart of the omega of the generators on the right, in the
% figure of 1400 x 600 px that GUILDA makes. Styling: labels G1-G4 with the colors of the
% generators (in the chart as well), thin springs, no tick text on the polar grid
% (ShowTickLabel), no legend of the arrows, P arrows only (ArrowScaleQ = 0; the voltage
% collapse keeps the Iq arrows). The time is the title of the picture (GUILDA's own title;
% in case 4 the title of the phasor plane, with |V| of bus 4). The playback bar of the picture
% is interactive: it is hidden (the picture takes its strip, as in export_video) and the
% axes toolbars are hidden. Each frame is taken with getframe, and the video is encoded by
% ffmpeg (H.264, yuv420p, faststart, scaled to the figure size in pixels).
%
% Run after GUILDA (the path) with R2026a, with ffmpeg installed:
%   addpath("notes/lecture-anim"); make_part4_spring_animations();
%   make_part4_spring_animations(Case="governor");   % one case only
    arguments (Input)
        opt.OutDir (1,1) string = ""          % Output folder; "" for _GUILDAdocPages/images/lecture/part4.
        opt.Case (1,:) string {mustBeMember(opt.Case, ["no-governor", "governor", "out-of-step", "voltage-collapse"])} ...
            = ["no-governor", "governor", "out-of-step", "voltage-collapse"]  % Cases to make.
    end
    s_out = opt.OutDir;
    if s_out == ""
        s_root = fileparts(fileparts(fileparts(mfilename("fullpath"))));   % notes/lecture-anim -> notes -> root
        s_out = fullfile(s_root, "_GUILDAdocPages", "images", "lecture", "part4");
    end
    rm_color = [0.85 0.15 0.10; 0 0 0.85; 0.15 0.60 0.10; 0 0 0];   % G1 red, G2 blue, G3 green, G4 black
    for s_case = opt.Case
        [res, sct] = simulate_case(s_case);
        n_gen = numel(sct.sv_gen);
        if s_case == "voltage-collapse"
            % left: the phasor plane above two charts of plot_trajectory; right: the funnel
            fig = figure(Color="w", Position=[100 100 1400 800]);
            f_panel = @(rv_pos) uipanel(fig, Units="normalized", Position=rv_pos, BorderType="none", BackgroundColor="w");
            G = res.plot_spring_model(Trajectory="none", Parent=f_panel([0 0.34 0.5 0.66]));
            G3 = res.plot_spring_model(Dimension=3, Trajectory="none", Parent=f_panel([0.5 0 0.5 1]));
            c_chart = {res.plot_trajectory(Quantity="Vabs", Parent=f_panel([0 0 0.25 0.34])), ...
                       res.plot_trajectory(Quantity="P", Bus="B004", Parent=f_panel([0.25 0 0.25 0.34]))};
            c_G = {G, G3};
            sv_chartTitle = ["|V| of the buses", "P of bus 4 (L4)"];
            for k = 1:2
                title(c_chart{k}.ax, sv_chartTitle(k));
            end
            sv_bus = "B00" + (1:6)';
            rm_busColor = [rm_color; 0.55 0.55 0.55; 0.55 0.55 0.55];   % buses 5 and 6 grey
            for i = 1:6
                c_chart{1}.set_style(sv_bus(i), Color=rm_busColor(i, :));
            end
            c_chart{2}.set_style("B004", Color=[0 0 0]);
            legend(c_chart{2}.ax, "off");
            G.link(G3);
            for k = 1:2
                G.link(c_chart{k});
            end
            tab_V = res.get_trajectory("Vabs");
            [rv_tV, iv_u] = unique(tab_V.t, "last");     % the times of the events appear twice
            f_title = @(t) sprintf("t = %.2f s     |V_4| = %.2f pu", t, interp1(rv_tV, tab_V.B004(iv_u), t));
            r_hold = 3;
        else
            [G, G_chart] = res.plot_spring_model();     % the default drawing: picture and side chart
            c_G = {G};
            for i = 1:n_gen
                G_chart.set_style(sct.sv_gen(i), Label=sct.sv_label(i), Color=rm_color(i, :));
            end
            fig = ancestor(G.ax(1), "figure");
            f_title = [];               % the title of the picture: t = ... s
            r_hold = 1.5;
        end
        for k = 1:numel(c_G)
            style_spring(c_G{k}, sct, rm_color);
        end
        % the playback bar (interactive) and the axes toolbars are not part of the frames
        set(findall(fig, "Tag", "GUILDA:GraphBase:PlaybackBar"), Visible="off");
        for ax = findall(fig, "Type", "axes")'
            ax.Toolbar.Visible = "off";
        end
        rv_frame = 0:0.05:res.rv_t(end);       % real time at 20 frames/s
        if rv_frame(end) < res.rv_t(end) - 1e-9
            rv_frame(end+1) = res.rv_t(end); %#ok<AGROW>
        end
        write_animation(fig, c_G, rv_frame, 20, r_hold, f_title, fullfile(s_out, "swing-" + s_case));
    end
end

function [res, sct] = simulate_case(s_case)
% Build the network of a case, simulate it and return the result and the drawing data.
    arguments (Input)
        s_case (1,1) string  % Case name (see the help of the main function).
    end
    arguments (Output)
        res  % ResultODE.
        sct (1,1) struct  % Drawing data: sv_gen, sv_label, sv_load.
    end
    net = network.Tutorial6bus();
    sct.sv_gen = "B00" + (1:4)' + "SG1";
    sct.sv_load = strings(0, 1);
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
            % second run: the stopped motors are tripped; it ends at t = 8 s, shortly after
            % both have stopped (7.6 s), so that the chart spans the video
            res = net.simulate("scenario", Time=[0, 8], Progress="none", StopOnOutOfStep=false, MaxStep=0.005, SampleTime=0.01);

        case "voltage-collapse"
            net.a_Bus{4}.remove_component("B004SG1");
            ld = net.a_Bus{4}.add_component("load-power", P=-0.8, Q=-0.2);
            add_governors(net, sct_gov, true);
            sc = net.add_scenario("scenario", Time=[0, 20]);
            rm_ramp = [0, 0; 19, -0.3];          % [s from t = 1, pu]: 0.3 pu more at t = 20 s
            sc.add_input("B003SG1", "Pmech", rm_ramp, [1, 20]);
            sc.add_input(ld.s_tag, "Pload", rm_ramp, [1, 20]);
            sct_warn = warning("off");           % the solver stops at the collapse
            res1 = net.simulate("scenario", Progress="none", SampleTime=0.01);
            warning(sct_warn);

            % the admittance at which L4 took its power: Y = -conj(S)/|V|^2
            tab_P = res1.get_trajectory("Pload");
            tab_Q = res1.get_trajectory("Qload");
            tab_V = res1.get_trajectory("Vabs");
            [rv_t, iv_u] = unique(tab_P.t);
            rv_Y = -(tab_P{iv_u, 2} - 1j*tab_Q{iv_u, 2}) ./ tab_V.B004(iv_u).^2;
            k_end = numel(rv_t) - 3;             % 3 samples before the stop (t = 7.26 s)
            r_rate = log(abs(rv_Y(k_end)) / abs(rv_Y(k_end - 3))) / (rv_t(k_end) - rv_t(k_end - 3));   % [1/s] relative rate
            rv_tIn = (0:0.01:19)';               % [s from t = 1] the points of the input
            rv_YIn = interp1(rv_t(1:k_end), rv_Y(1:k_end), 1 + rv_tIn);
            iv_next = 1 + rv_tIn > rv_t(k_end);
            rv_YIn(iv_next) = rv_Y(k_end) * exp(r_rate*(1 + rv_tIn(iv_next) - rv_t(k_end)));
            rv_dZ = 1 ./ rv_YIn - 1 / rv_Y(1);  % added to the impedance of the equilibrium

            % second run: L4 an impedance load driven by R and X; the same Pmech ramp of G3
            net.a_Bus{4}.remove_component(ld.s_tag);
            ld = net.a_Bus{4}.add_component("load-impedance", P=-0.8, Q=-0.2);
            net.initialize();
            sc = net.add_scenario("impedance", Time=[0, 20]);
            sc.add_input("B003SG1", "Pmech", rm_ramp, [1, 20]);
            sc.add_input(ld.s_tag, ["R"; "X"], [rv_tIn, real(rv_dZ), imag(rv_dZ)], [1, 20]);
            res = net.simulate("impedance", Progress="none", SampleTime=0.01);
            tab_V = res.get_trajectory("Vabs");
            k = find(tab_V.B004 <= 0.07, 1);     % end when bus 4 is at 0.07 pu
            r_tEnd = round(interp1(tab_V.B004(k-1:k), tab_V.t(k-1:k), 0.07), 2);
            fprintf("voltage-collapse: first run stops at t = %.3f s; impedance from t = %.2f s; |V4| = %.2f pu at 7.75 s; end at %.2f s\n", ...
                tab_P.t(end), rv_t(k_end), tab_V.B004(find(tab_V.t >= 7.75, 1)), r_tEnd);
            res = net.simulate("impedance", Time=[0, r_tEnd], Progress="none", SampleTime=0.01);
            sct.sv_gen = sct.sv_gen(1:3);
            sct.sv_load = string(ld.s_tag);
    end
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

function style_spring(G, sct, rm_color)
% Node labels G1-G4 (L4), colors of the generators on their nodes and buses, node sizes
% from the inertia, thin springs and no tick text on the polar grid.
    arguments (Input)
        G  % GraphSpring2D or GraphSpring3D.
        sct (1,1) struct  % Drawing data of simulate_case.
        rm_color (:,3) double  % Colors of G1-G4.
    end
    tab = G.tab_element;
    sv_node = tab.Tag(tab.Kind == "node");
    G.NodeLabel = repmat("", numel(sv_node), 1);
    rv_M = [10, 8, 6, 6];
    for i = 1:numel(sct.sv_gen)
        s_bus = extractBefore(sct.sv_gen(i), "SG");
        G.set_style(sct.sv_gen(i), Label=sct.sv_label(i), Color=rm_color(i, :), MarkerSize=1.2*rv_M(i));
        G.set_style(s_bus, Color=rm_color(i, :));
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

function write_animation(fig, c_G, rv_frame, r_fps, r_hold, f_title, s_base)
% Take every frame with getframe and write the video (ffmpeg, H.264) and the poster PNG
% (the last frame), both cropped to one box around the drawing of all frames (with a
% white margin) and scaled from the screen pixels of getframe to the pixels of the figure.
    arguments (Input)
        fig (1,1) matlab.ui.Figure  % Figure of the graphs.
        c_G cell                    % Spring pictures, linked to each other and to the charts; the first is moved.
        rv_frame (1,:) double       % [s] Time of each frame.
        r_fps (1,1) double          % [1/s] Frames per second.
        r_hold (1,1) double         % [s] Time the last frame is held.
        f_title                     % Title of the first picture at time t (the others none); [] for the titles of GUILDA. <@Type> function_handle
        s_base (1,1) string         % Output path without extension.
    end
    s_ffmpeg = "";
    for s_try = ["/opt/homebrew/bin/ffmpeg", "/usr/local/bin/ffmpeg", "/usr/bin/ffmpeg"]
        if isfile(s_try)
            s_ffmpeg = s_try;
            break
        end
    end
    if s_ffmpeg == ""
        error("ffmpeg is not installed.");
    end
    s_dir = string(tempname);
    mkdir(s_dir);
    c_dir = onCleanup(@() rmdir(s_dir, "s"));
    n_frame = numel(rv_frame);
    n_hold = round(r_hold * r_fps);
    iv_size = [];
    lm_ink = [];
    i_out = 0;
    for i_frame = 1:n_frame
        c_G{1}.set_time(rv_frame(i_frame));       % the linked pictures and charts follow
        if ~isempty(f_title)
            title(c_G{1}.ax, f_title(rv_frame(i_frame)), FontWeight="bold", FontSize=16);
            for k = 2:numel(c_G)
                title(c_G{k}.ax, "");
            end
        end
        drawnow;
        pause(0.02);        % getframe in matlab -batch otherwise returns the frame before
        drawnow;
        m_img = frame2im(getframe(fig));
        if isempty(iv_size)
            iv_size = 2 * floor([size(m_img, 1), size(m_img, 2)] / 2);
        end
        m_out = 255 * ones(iv_size(1), iv_size(2), 3, "uint8");     % one size for all frames
        n_h = min(iv_size(1), size(m_img, 1));
        n_w = min(iv_size(2), size(m_img, 2));
        m_out(1:n_h, 1:n_w, :) = m_img(1:n_h, 1:n_w, :);
        if isempty(lm_ink)
            lm_ink = false(iv_size);
        end
        lm_ink = lm_ink | any(m_out < 245, 3);
        for r = 1:(1 + (i_frame == n_frame) * n_hold)
            i_out = i_out + 1;
            imwrite(m_out, fullfile(s_dir, sprintf("f%05d.png", i_out)));
        end
    end
    r_scale = fig.Position(3) / iv_size(2);      % getframe takes the screen scale of the display
    close(fig);
    n_pad = round(12 / r_scale);
    iv_r = find(any(lm_ink, 2));
    iv_c = find(any(lm_ink, 1));
    r1 = max(1, iv_r(1) - n_pad);  r2 = min(iv_size(1), iv_r(end) + n_pad);
    c1 = max(1, iv_c(1) - n_pad);  c2 = min(iv_size(2), iv_c(end) + n_pad);
    s_scale = sprintf("crop=%d:%d:%d:%d,scale=%d:%d:flags=lanczos", c2 - c1 + 1, r2 - r1 + 1, c1 - 1, r1 - 1, ...
        2*round(r_scale*(c2 - c1 + 1)/2), 2*round(r_scale*(r2 - r1 + 1)/2));
    c_cmd = { ...
        sprintf('"%s" -v error -y -framerate %g -i "%s" -vf %s -c:v libx264 -preset slow -crf 26 -pix_fmt yuv420p -movflags +faststart "%s"', ...
            s_ffmpeg, r_fps, fullfile(s_dir, "f%05d.png"), s_scale, s_base + ".mp4"), ...
        sprintf('"%s" -v error -y -i "%s" -vf %s "%s"', ...
            s_ffmpeg, fullfile(s_dir, sprintf("f%05d.png", i_out)), s_scale, s_base + "-poster.png")};
    for i = 1:numel(c_cmd)
        [i_status, s_msg] = system(c_cmd{i});
        if i_status ~= 0
            error("ffmpeg failed: %s", s_msg);
        end
    end
end
