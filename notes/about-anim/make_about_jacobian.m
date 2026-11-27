function make_about_jacobian(opt)
% Make the About carousel video of the linear model taken apart by element (Jacobian).
%
% The video shows GUILDA used from the command line, in one figure of 1280 x 640 px (each
% frame taken with getframe at the scale of the screen and resized to 1280 x 640):
%   1. A command window: IEEE 9-bus with an AVR and a PSS on each generator, get_sys, and
%      ResultLIN.plot_matrix(Matrix="J"), the Jacobian of the whole DAE by element.
%   2. The figure of that line (the last command kept in a strip above it).
%   3. The command window again: get_contribution of generator 1 with its AVR and PSS, and
%      plot_matrix(Matrix="J") of that part; then its figure.
%   4. The command window: the part compared with the whole Jacobian (its state rows are
%      the same entries, and it sums with the part of all the other elements to J), with
%      the printed output of MATLAB.
%   5. A cross-fade back to the first frame, so that the video loops.
% Every line shown is run as it is (evalc; the printed text is its output), except that the
% two plot_matrix lines get Parent (the panel below the strip). The axes toolbars are hidden.
% The code of the manifest is these lines.
%
% Writes into OutDir (default _GUILDAdocPages/images/about/analysis/):
%   02-jacobian-structure.mp4  H.264, yuv420p, faststart, 1280 x 640, 20 fps
%   02-jacobian-structure.png  poster: the Jacobian of the whole network
%
% Run with R2026a and ffmpeg installed (matlab -batch works):
%   GUILDA.addpath(); addpath("notes/about-anim"); make_about_jacobian();
%   make_about_jacobian(OutDir="/tmp/about-jacobian");
    arguments (Input)
        opt.OutDir (1,1) string = ""   % Output folder; "" for _GUILDAdocPages/images/about/analysis.
    end
    s_out__ = opt.OutDir;
    if s_out__ == ""
        s_root__ = fileparts(fileparts(fileparts(mfilename("fullpath"))));   % notes/about-anim -> notes -> root
        s_out__ = fullfile(s_root__, "_GUILDAdocPages", "images", "about", "analysis");
    end
    if ~isfolder(s_out__)
        mkdir(s_out__);
    end
    s_base__ = fullfile(s_out__, "02-jacobian-structure");

    % The lines of the three steps (the variables of this function end in "__", so that the
    % lines run here with evalc do not overwrite them)
    c_step__ = { ...
        ["net = network.IEEE9bus(LocalController=true);    % AVR and PSS on each generator"
         "res = net.get_sys();"
         "res.plot_matrix(Matrix=""J"");                     % the Jacobian of the network"], ...
        ["sv_gen = [""B001SG1"", ""B001SG1CA1"", ""B001SG1CP2""];   % generator 1, its AVR, PSS"
         "res_g = res.get_contribution(sv_gen);"
         "res_g.plot_matrix(Matrix=""J"");                   % the part of those three"], ...
        ["J = res.get_ss(""DAE"", Format=""struct"").A;        % the whole Jacobian"
         "lv_gen = contains(res_g.StateName, ""B001SG1"");   % the rows of their states"
         "max(abs(res_g.A(lv_gen,:) - J(lv_gen,:)), [], ""all"")"
         "sv_all = [unique(res.tab_variable.Owner)', ""Branch""];   % every element"
         "res_o = res.get_contribution(setdiff(sv_all, sv_gen));   % all the others"
         "max(abs(res_g.A + res_o.A - J), [], ""all"")"]};

    fig__ = figure(Color="w", Position=[60 60 1280 640], MenuBar="none", ToolBar="none");
    ax_code__ = axes(fig__, Units="normalized", Position=[0 0 1 1], XLim=[0 1], YLim=[0 1], ...
        XTick=[], YTick=[], Box="on", Color=[0.97 0.975 0.98], XColor=[0.82 0.84 0.86], YColor=[0.82 0.84 0.86]);
    ax_code__.Toolbar.Visible = "off";
    disableDefaultInteractivity(ax_code__);
    con__ = make_console(ax_code__);
    h_main__ = [];
    rec__ = make_recorder(fig__);
    con__.prompt();
    rec__.hold(12);

    for k_step__ = 1:numel(c_step__)
        sv_line__ = c_step__{k_step__};
        for i_line__ = 1:numel(sv_line__)
            s_line__ = sv_line__(i_line__);
            type_line(rec__, con__, s_line__);
            rec__.hold(4);
            if startsWith(s_line__, ["res.plot_matrix", "res_g.plot_matrix"])
                % The figure of the line, drawn into the panel below the strip
                s_run__ = replace(extractBefore(s_line__, ";"), "Matrix=""J"")", "Matrix=""J"", Parent=h_main__)");
                r_strip__ = 0.085;
                con__.strip(s_line__, r_strip__);
                h_main__ = uipanel(fig__, Units="normalized", Position=[0 0 1 1 - r_strip__], ...
                    BorderType="none", BackgroundColor="w");
                eval(s_run__ + ";");
                drawnow;
                for ax__ = findall(h_main__, "Type", "axes")'
                    ax__.Toolbar.Visible = "off";
                end
                rec__.hold(70);
                if k_step__ == 1
                    rec__.poster();
                end
                delete(h_main__);
                con__.full();
                con__.prompt();
                rec__.hold(8);
            else
                s_text__ = evalc(s_line__);
                con__.output(s_text__);
                con__.prompt();
                rec__.hold(4 + 22*(strtrim(s_text__) ~= ""));
            end
        end
    end
    rec__.hold(50);
    rec__.finish(s_base__, 12);
    close(fig__);
end


function type_line(rec, con, s_code)
% Type s_code into the last line of the console, four characters per frame, with a cursor.
    n = strlength(s_code);
    for k = 4:4:n + 3
        con.edit(extractBefore(s_code, min(k, n) + 1), true);
        rec.shot();
    end
    con.edit(s_code, false);
    con.newline();
    rec.shot();
end


function con = make_console(ax)
% Command window drawn in the axes ax: rows of code (">> " and syntax colors) and of output
% (plain text), the last n_row rows shown (the older ones scroll off at the top).
%
% con.prompt()          a new row with the prompt and a cursor
% con.edit(s, l_cur)    the code of the last row (with a cursor when l_cur)
% con.newline()         end the row of code
% con.output(s)         the printed text s (its first and last empty lines dropped)
% con.strip(s, r)       only the line s, in a strip of height r at the top (for a figure)
% con.full()            the whole command window again
    n_row = 15;
    r_dy = 0.94/n_row;
    r_font = 16;
    h_head = text(ax, 0.025, 0.965, "Command Window", FontName="Helvetica", ...
        FontSize=13, FontWeight="bold", Color=[0.35 0.38 0.42], Interpreter="none", VerticalAlignment="middle");
    h_row = gobjects(n_row, 1);
    for i = 1:n_row
        h_row(i) = text(ax, 0.025, 0.93 - (i - 0.5)*r_dy, "", FontName="Menlo", FontSize=r_font, ...
            Interpreter="tex", VerticalAlignment="middle");
    end
    h_strip = text(ax, 0.015, 0.5, "", FontName="Menlo", FontSize=r_font, Interpreter="tex", ...
        VerticalAlignment="middle", Visible="off");
    sv_row = strings(0, 1);       % TeX strings of the rows
    s_code = "";

    con.prompt = @prompt;
    con.edit = @edit;
    con.newline = @newline;
    con.output = @output;
    con.strip = @strip;
    con.full = @full;

    function prompt()
        sv_row(end + 1, 1) = code_tex("", true);
        s_code = "";
        render();
    end

    function edit(s, l_cur)
        s_code = s;
        sv_row(end) = code_tex(s, l_cur);
        render();
    end

    function newline()
        sv_row(end) = code_tex(s_code, false);
        render();
    end

    function output(s)
        sv = splitlines(string(s));
        while ~isempty(sv) && strtrim(sv(1)) == ""
            sv(1) = [];
        end
        while ~isempty(sv) && strtrim(sv(end)) == ""
            sv(end) = [];
        end
        sv_row = [sv_row; "\color[rgb]{0.13,0.13,0.13}" + escape_tex(sv)];
        render();
    end

    function strip(s, r)
        ax.Position = [0 1 - r 1 r];
        set([h_head; h_row], Visible="off");
        set(h_strip, Visible="on", String=code_tex(s, false));
    end

    function full()
        ax.Position = [0 0 1 1];
        set([h_head; h_row], Visible="on");
        h_strip.Visible = "off";
    end

    function render()
        sv = sv_row(max(1, end - n_row + 1):end);
        for k = 1:n_row
            if k <= numel(sv)
                h_row(k).String = sv(k);
            else
                h_row(k).String = "";
            end
        end
    end
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
% Frame recorder of a figure (as in make_home_demo): shots with getframe, resized to
% 1280 x 640 px and written as PNG files, then the MP4 (with a cross-fade into the first
% frame) and the poster PNG.
%
% rec.shot()               one frame
% rec.hold(n)              n frames
% rec.poster()             the last frame is the poster (default: the last frame)
% rec.finish(s_base, n)    write s_base.mp4 and s_base.png; the last n frames fade into the first
    r_fps = 20;
    s_dir = string(tempname);
    mkdir(s_dir);
    n_out = 0;
    i_poster = 0;
    iv_size = [640 1280];        % [px] rows, columns of the frames

    rec.shot = @shot;
    rec.hold = @hold_frames;
    rec.poster = @mark_poster;
    rec.finish = @finish;

    function mark_poster()
        i_poster = n_out;
    end

    function shot()
        drawnow;
        pause(0.02);            % getframe in matlab -batch otherwise returns the frame before
        drawnow;
        m_img = frame2im(getframe(fig));     % 1.5x or 2x of the figure, by its content
        if ~isequal(size(m_img, [1 2]), iv_size)
            m_img = imresize(m_img, iv_size, "lanczos3");
        end
        n_out = n_out + 1;
        imwrite(m_img, frame_file(n_out));
    end

    function s = frame_file(k)
        s = fullfile(s_dir, sprintf("f%05d.png", k));
    end

    function hold_frames(n)
        % One frame, repeated (nothing moves while holding)
        shot();
        for i = 2:n
            copyfile(frame_file(n_out), frame_file(n_out + 1));
            n_out = n_out + 1;
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
