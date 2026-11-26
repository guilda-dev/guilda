function make_home_demo(opt)
% Make the demo video of the Home tab: GUILDA used for one simple analysis.
%
% The video needs no text on the page. It shows, in one figure of 1280 x 640 px (each
% frame taken with getframe at the scale of the screen and resized to 1280 x 640):
%   1. A command window: five lines of MATLAB typed one after another (IEEE 14-bus, a
%      scenario with a fault at bus B008 from 1 s to 1.05 s, simulate, plot_diagram).
%   2. The figure of the last line: ResultODE.plot_diagram(Trajectory="omega") drawn by
%      GUILDA, the network diagram with the omega chart, played from 0 s to 5 s (the
%      fault in slow motion, 5 ms of the result per frame), with the last command kept in a
%      strip above it.
%   3. A cross-fade back to the first frame, so that the video loops.
% The lines shown are run as they are, except that simulate gets Progress="none" (no
% progress dialog in matlab -batch). The playback bar and the axes toolbars are hidden.
%
% Writes into OutDir (default _GUILDAdocPages/images/home/):
%   home-demo.mp4  H.264, yuv420p, faststart, 1280 x 640, 20 fps
%   home-demo.png  poster: a frame just after the fault
%
% Run with R2026a and ffmpeg installed (matlab -batch works):
%   GUILDA.addpath(); addpath("notes/home-anim"); make_home_demo();
%   make_home_demo(OutDir="/tmp/home-demo");
    arguments (Input)
        opt.OutDir (1,1) string = ""   % Output folder; "" for _GUILDAdocPages/images/home.
    end
    s_out = opt.OutDir;
    if s_out == ""
        s_root = fileparts(fileparts(fileparts(mfilename("fullpath"))));   % notes/home-anim -> notes -> root
        s_out = fullfile(s_root, "_GUILDAdocPages", "images", "home");
    end
    if ~isfolder(s_out)
        mkdir(s_out);
    end
    s_base = fullfile(s_out, "home-demo");

    sv_code = [ ...
        "net = network.IEEE14bus();"
        "sc = net.add_scenario(""fault"", Time=[0, 5]);"
        "sc.add_fault(""B008"", [1, 1.05]);   % fault at bus B008"
        "res = net.simulate(""fault"");"
        "res.plot_diagram(Trajectory=""omega"");"];

    fig = figure(Color="w", Position=[60 60 1280 640], MenuBar="none", ToolBar="none");
    ax_code = axes(fig, Units="normalized", Position=[0 0 1 1], XLim=[0 1], YLim=[0 1], ...
        XTick=[], YTick=[], Box="on", Color=[0.97 0.975 0.98], XColor=[0.82 0.84 0.86], YColor=[0.82 0.84 0.86]);
    ax_code.Toolbar.Visible = "off";
    disableDefaultInteractivity(ax_code);
    n_line = numel(sv_code);
    r_dy = 0.11;
    r_y0 = 0.5 + r_dy*(n_line - 1)/2 + 0.04;
    h_head = text(ax_code, 0.04, r_y0 + 0.13, "Command Window", FontName="Helvetica", ...
        FontSize=17, FontWeight="bold", Color=[0.35 0.38 0.42], Interpreter="none");
    h_line = gobjects(n_line, 1);
    for i = 1:n_line
        h_line(i) = text(ax_code, 0.04, r_y0 - (i - 1)*r_dy, "", FontName="Menlo", FontSize=21, ...
            Interpreter="tex", VerticalAlignment="middle");
    end
    h_line(1).String = code_tex("", true);

    rec = make_recorder(fig);
    rec.hold(12);
    for i = 1:n_line
        type_line(rec, h_line(i), sv_code(i));
        if i < n_line
            h_line(i + 1).String = code_tex("", true);
            rec.hold(6);
        end
    end
    rec.hold(10);

    % The lines run (the figure of the last line is drawn into the panel below the strip).
    net = network.IEEE14bus();
    sc = net.add_scenario("fault", Time=[0, 5]);
    sc.add_fault("B008", [1, 1.05]);
    res = net.simulate("fault", Progress="none");

    r_strip = 0.085;
    ax_code.Position = [0 1 - r_strip 1 r_strip];
    delete(h_head);
    delete(h_line(1:end-1));
    set(h_line(end), Position=[0.015 0.5 0], FontSize=17, String=code_tex(sv_code(end), false));
    h_main = uipanel(fig, Units="normalized", Position=[0 0 1 1 - r_strip], BorderType="none", BackgroundColor="w");
    G = res.plot_diagram(Trajectory="omega", LabelFontSize=12, Parent=h_main);
    G.set_time(0);
    set(findall(fig, "Tag", "GUILDA:GraphBase:PlaybackBar"), "Visible", "off");
    drawnow;
    for ax = findall(h_main, "Type", "axes")'
        ax.Toolbar.Visible = "off";
        ax.FontSize = 14;              % readable at 900 px (a MATLAB axes property)
    end
    set(findall(h_main, "Type", "legend"), FontSize=13);
    rec.set_tick(@() G.step_flow(1/rec.r_fps));
    rv_t = [0:0.05:0.95, 0.96:0.005:1.15, 1.2:0.05:5];
    for t = rv_t
        G.set_time(t);
        rec.shot();
        if abs(t - 1.02) < 1e-6
            rec.poster();
        end
    end
    rec.hold(24);
    rec.finish(s_base, 12);
    close(fig);
end


function type_line(rec, h, s_code)
% Type s_code into the line h, three characters per frame, with a cursor.
    n = strlength(s_code);
    for k = 3:3:n + 2
        h.String = code_tex(extractBefore(s_code, min(k, n) + 1), true);
        rec.shot();
    end
    h.String = code_tex(s_code, false);
    rec.shot();
end


function s = code_tex(s_code, l_cursor)
% TeX string of a command line: the prompt in gray, strings in purple, a comment in green
% and, with l_cursor, a cursor at the end.
    s_dark = "\color[rgb]{0.13,0.13,0.13}";
    s_str = "\color[rgb]{0.65,0.04,0.96}";
    s_com = "\color[rgb]{0.01,0.50,0.04}";
    s = "\color[rgb]{0.55,0.57,0.60}>> " + s_dark;
    c = char(s_code);
    l_in = false;
    for k = 1:numel(c)
        ch = c(k);
        if ~l_in && ch == '%'
            s = s + s_com + escape_tex(string(c(k:end)));
            break
        end
        if ch == '"'
            if ~l_in
                s = s + s_str + """";
            else
                s = s + """" + s_dark;
            end
            l_in = ~l_in;
        else
            s = s + escape_tex(string(ch));
        end
    end
    if l_cursor
        s = s + "\color[rgb]{0.07,0.44,0.75}|";
    end
end


function s = escape_tex(s)
% Escape the characters of the TeX interpreter.
    s = replace(s, ["\", "_", "^", "{", "}"], ["\\", "\_", "\^", "\{", "\}"]);
end


function rec = make_recorder(fig)
% Frame recorder of a figure (as in make_about_carousel): shots with getframe, resized to
% 1280 x 640 px and written as PNG files, then the MP4 (with a cross-fade into the first frame) and the poster PNG.
%
% rec.shot()               one frame (rec.set_tick(f) calls f() before each frame)
% rec.hold(n)              n frames
% rec.poster()             the next frame is the poster (default: the last frame)
% rec.finish(s_base, n)    write s_base.mp4 and s_base.png; the last n frames fade into the first
    r_fps = 20;
    s_dir = string(tempname);
    mkdir(s_dir);
    n_out = 0;
    i_poster = 0;
    fcn_tick = [];
    iv_size = [640 1280];        % [px] rows, columns of the frames

    rec.r_fps = r_fps;
    rec.shot = @shot;
    rec.hold = @hold_frames;
    rec.poster = @mark_poster;
    rec.set_tick = @set_tick;
    rec.finish = @finish;

    function set_tick(f)
        fcn_tick = f;
    end

    function mark_poster()
        i_poster = n_out + 1;
    end

    function shot()
        if ~isempty(fcn_tick)
            fcn_tick();
        end
        drawnow;
        pause(0.02);            % getframe in matlab -batch otherwise returns the frame before
        drawnow;
        m_img = frame2im(getframe(fig));     % 1.5x or 2x of the figure, by its content
        if ~isequal(size(m_img, [1 2]), iv_size)
            m_img = imresize(m_img, iv_size, "lanczos3");
        end
        m_out = m_img;
        n_out = n_out + 1;
        imwrite(m_out, frame_file(n_out));
    end

    function s = frame_file(k)
        s = fullfile(s_dir, sprintf("f%05d.png", k));
    end

    function hold_frames(n)
        for i = 1:n
            shot();
        end
    end

    function finish(s_base, n_fade)
        if i_poster == 0 || i_poster > n_out
            i_poster = n_out;
        end
        m_first = double(imread(frame_file(1)));
        m_last = double(imread(frame_file(n_out)));
        for i = 1:n_fade
            r_w = (1 - cos(pi*i/(n_fade + 1)))/2;
            n_out = n_out + 1;
            imwrite(uint8((1 - r_w)*m_last + r_w*m_first), frame_file(n_out));
        end
        s_in = fullfile(s_dir, "f%05d.png");
        for r_crf = [20, 23, 26, 29]
            run_ffmpeg(sprintf(['-framerate %d -i "%s" -c:v libx264 -preset slow ' ...
                '-crf %d -pix_fmt yuv420p -movflags +faststart "%s"'], r_fps, s_in, r_crf, s_base + ".mp4"));
            sct = dir(s_base + ".mp4");
            if sct.bytes < 2.9e6
                break
            end
        end
        copyfile(frame_file(i_poster), s_base + ".png");
        fprintf("%s.mp4: %d frames (%.1f s), %.2f MB, crf %d\n", s_base, n_out, n_out/r_fps, sct.bytes/1e6, r_crf);
        rmdir(s_dir, "s");
    end
end


function run_ffmpeg(s_args)
% Run ffmpeg with the arguments s_args (overwriting the output).
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
    [i_status, s_msg] = system(sprintf('"%s" -v error -y %s', s_ffmpeg, s_args));
    if i_status ~= 0
        error("ffmpeg failed: %s", s_msg);
    end
end
