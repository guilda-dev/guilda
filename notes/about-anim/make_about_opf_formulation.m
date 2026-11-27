function make_about_opf_formulation(opt)
% Make the video of the About carousel card on the OPF: the problem printed and inspected in
% the Command Window, then solved.
%
% The video shows, in one figure of 1280 x 640 px (each frame taken with getframe and
% resized to 1280 x 640):
%   1. A command window where these lines are typed one after another, each followed by the
%      text it prints (the real output, captured with evalc while the line runs); the window
%      scrolls when the output is longer than the window:
%        net = network.IEEE14bus();
%        prob = net.build_opf_problem(Method="AC OPF");
%        net.solver_OPF.disp_formulation(Method="AC OPF", Problem=prob)
%        show(prob.Objective.GenCost)
%        showbounds(prob.Variables.B002SG1)
%        show(prob.Constraints.VargMax1_EL001)
%        res = net.calculate_optimal_powerflow(Method="AC OPF", Problem=prob);
%        res.disp_summary()
%        res.plot_dispatch();
%   2. A cross-fade into the figure of the last line, drawn by plot_dispatch in its own
%      figure as it comes (only the figure window is sized to 1280 x 640).
%   3. A cross-fade back to the first frame, so that the video loops.
% The lines are run as they are, in the base workspace (calculate_optimal_powerflow with
% its default Progress; in the desktop it may open its progress dialog, not recorded).
%
% Writes into OutDir (default _GUILDAdocPages/images/about/analysis/):
%   05-opf-formulation.mp4  H.264, yuv420p, faststart, 1280 x 640, 20 fps
%   05-opf-formulation.png  poster: the formulation and the cost in the window
%
% Run with R2026a, Optimization Toolbox and ffmpeg installed (matlab -batch works):
%   GUILDA.addpath(); addpath("notes/about-anim"); make_about_opf_formulation();
%   make_about_opf_formulation(OutDir="/tmp/about-opf");
    arguments (Input)
        opt.OutDir (1,1) string = ""   % Output folder; "" for _GUILDAdocPages/images/about/analysis.
    end
    s_out = opt.OutDir;
    if s_out == ""
        s_root = fileparts(fileparts(fileparts(mfilename("fullpath"))));   % notes/about-anim -> notes -> root
        s_out = fullfile(s_root, "_GUILDAdocPages", "images", "about", "analysis");
    end
    if ~isfolder(s_out)
        mkdir(s_out);
    end
    s_base = fullfile(s_out, "05-opf-formulation");

    sv_code = [ ...
        "net = network.IEEE14bus();"
        "prob = net.build_opf_problem(Method=""AC OPF"");"
        "net.solver_OPF.disp_formulation(Method=""AC OPF"", Problem=prob)"
        "show(prob.Objective.GenCost)"
        "showbounds(prob.Variables.B002SG1)"
        "show(prob.Constraints.VargMax1_EL001)"
        "res = net.calculate_optimal_powerflow(Method=""AC OPF"", Problem=prob);"
        "res.disp_summary()"
        "res.plot_dispatch();"];
    iv_hold = [4 4 95 45 35 35 12 80 0];    % frames held after the output of each line

    % command window: one text object per row, coordinates in pixels
    fig = figure(Color="w", Position=[60 60 1280 640], MenuBar="none", ToolBar="none");
    ax = axes(fig, Units="normalized", Position=[0 0 1 1], XLim=[0 1280], YLim=[0 640], ...
        XTick=[], YTick=[], Box="on", Color=[0.97 0.975 0.98], XColor=[0.82 0.84 0.86], YColor=[0.82 0.84 0.86]);
    ax.Toolbar.Visible = "off";
    disableDefaultInteractivity(ax);
    text(ax, 26, 616, "Command Window", FontName="Helvetica", FontUnits="pixels", FontSize=17, ...
        FontWeight="bold", Color=[0.35 0.38 0.42], Interpreter="none");
    r_dy = 23.5;                         % [px] row height
    n_row = 25;
    h_row = gobjects(n_row, 1);
    for i = 1:n_row
        h_row(i) = text(ax, 26, 586 - (i - 1)*r_dy, "", FontName="Menlo", FontUnits="pixels", ...
            FontSize=18, VerticalAlignment="middle", Color=[0.13 0.13 0.13], Interpreter="none");
    end

    % lines of the window: text and whether it is a command line (prompt, colored)
    c_line = {};
    lv_cmd = false(0, 1);
    function render()
        n_line = numel(c_line);
        i_top = max(0, n_line - n_row);
        for r = 1:n_row
            j = i_top + r;
            if j <= n_line && lv_cmd(j)
                set(h_row(r), Interpreter="tex", String=c_line{j});
            elseif j <= n_line
                set(h_row(r), Interpreter="none", String=c_line{j});
            else
                set(h_row(r), Interpreter="none", String="");
            end
        end
    end
    function set_last(s, l_cmd)
        c_line{end} = s;
        lv_cmd(end) = l_cmd;
        render();
    end
    function add_line(s, l_cmd)
        c_line{end+1} = s;
        lv_cmd(end+1) = l_cmd;
        render();
    end

    rec = make_recorder(fig);
    add_line(code_tex("", true), true);
    rec.hold(14);
    for i = 1:numel(sv_code)
        % type the line, four characters per frame, with a cursor
        n = strlength(sv_code(i));
        for k = 4:4:n + 3
            set_last(code_tex(extractBefore(sv_code(i), min(k, n) + 1), true), true);
            rec.shot();
        end
        set_last(code_tex(sv_code(i), false), true);
        rec.hold(5);
        if i == numel(sv_code)
            break
        end
        % run it in the base workspace and print what it printed
        assignin("base", "s_lineAboutOPF", sv_code(i));
        s_print = string(evalin("base", "evalc(s_lineAboutOPF)"));
        evalin("base", "clear s_lineAboutOPF");
        sv_print = split(s_print, newline);
        if ~isempty(sv_print) && sv_print(end) == ""
            sv_print(end) = [];
        end
        for k = 1:numel(sv_print)        % two rows per frame: the window scrolls
            add_line(char(sv_print(k)), false);
            if mod(k, 2) == 0 || k == numel(sv_print)
                rec.shot();
            end
        end
        add_line(code_tex("", true), true);
        if sv_code(i) == "show(prob.Objective.GenCost)"
            rec.poster();
        end
        rec.hold(iv_hold(i));
    end

    % the last line: the figure of plot_dispatch, as it comes
    evalin("base", sv_code(end));
    fig_plot = gcf;
    fig_plot.Position = [60 60 1280 640];
    drawnow;
    rec.fade_to(fig_plot, 10);
    rec.hold(70);
    rec.finish(s_base, 14);
    close(fig_plot);
    close(fig);
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
% Frame recorder (as in make_home_demo): shots of the current figure with getframe, resized
% to 1280 x 640 px and written as PNG files, then the MP4 (with a cross-fade into the first
% frame) and the poster PNG.
%
% rec.shot()               one frame of the current figure
% rec.hold(n)              n frames
% rec.fade_to(fig2, n)     n frames fading from the last frame into fig2, then record fig2
% rec.poster()             the next frame is the poster (default: the last frame)
% rec.finish(s_base, n)    write s_base.mp4 and s_base.png; the last n frames fade into the first
    r_fps = 20;
    s_dir = string(tempname);
    mkdir(s_dir);
    n_out = 0;
    i_poster = 0;
    iv_size = [640 1280];        % [px] rows, columns of the frames

    rec.shot = @shot;
    rec.hold = @hold_frames;
    rec.fade_to = @fade_to;
    rec.poster = @mark_poster;
    rec.finish = @finish;

    function mark_poster()
        i_poster = n_out + 1;
    end

    function m_img = grab()
        drawnow;
        pause(0.02);            % getframe in matlab -batch otherwise returns the frame before
        drawnow;
        m_img = frame2im(getframe(fig));     % 1.5x or 2x of the figure, by its content
        if ~isequal(size(m_img, [1 2]), iv_size)
            m_img = imresize(m_img, iv_size, "lanczos3");
        end
    end

    function shot()
        n_out = n_out + 1;
        imwrite(grab(), frame_file(n_out));
    end

    function fade_to(fig2, n)
        m_last = double(imread(frame_file(n_out)));
        fig = fig2;
        m_next = double(grab());
        for i = 1:n
            r_w = (1 - cos(pi*i/(n + 1)))/2;
            n_out = n_out + 1;
            imwrite(uint8((1 - r_w)*m_last + r_w*m_next), frame_file(n_out));
        end
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
