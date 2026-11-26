function make_about_custom_controller(opt)
% Make the About carousel video "制御器もネットワークの一部": a user-written controller class.
%
% The video (1280 x 640 px) shows, as a user would do it in MATLAB:
%   1. An editor pane where the class file
%      _GUILDAobject/+controller/+governor/Droop.m is typed: a governor
%      with a proportional frequency feedback, Pmech = Pmech_ref - K*omega (key "gov-droop",
%      a LocalController with the role "governor", no state), then saved.
%   2. A command window where the commands of sv_cmd below are typed: GUILDA.update_keymap
%      registers the new key, the IEEE 9-bus system loses 0.1 pu of mechanical power at 1 s
%      and is simulated with the default governors (gov-static) and again with gov-droop on
%      its three generators; the text under each command is its real output (evalc).
%   3. The two figures drawn by the last two commands (ResultODE.plot_trajectory of omega),
%      as GUILDA draws them, side by side under the command lines that drew them.
%   4. A cross-fade back to the first frame, so that the video loops.
% The class file typed is the file used: the script writes sv_class to
% _GUILDAobject/+controller/+governor/Droop.m (it stops if a different file is there), runs
% the commands exactly as shown, and deletes the file again at the end (the key is then
% removed with GUILDA.update_keymap).
%
% Writes into OutDir (default _GUILDAdocPages/images/about/analysis/):
%   04-custom-controller.mp4   H.264, yuv420p, faststart, 1280 x 640, 20 fps
%   04-custom-controller.png   poster: the two figures
%   04-custom-controller-fig1.png, -fig2.png   the two GUILDA figures as recorded (getframe)
%   04-custom-controller-output.txt            the command lines and their output
%
% Run with R2026a and ffmpeg installed (matlab -batch works), from the root of GUILDA:
%   GUILDA.addpath(); addpath("notes/about-anim");
%   make_about_custom_controller(OutDir="/tmp/custom-controller");
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
    s_base = fullfile(s_out, "04-custom-controller");

    s_dir = "_GUILDAobject/+controller/+governor/";
    s_name = "Droop.m";
    sv_class = [ ...
        "classdef Droop < LocalController"
        "% Governor with a proportional frequency feedback: Pmech = Pmech_ref - K*omega"
        "    properties (Constant, Hidden)"
        "        key    = ""gov-droop"""
        "        s_role = ""governor"""
        "    end"
        "    properties (SetAccess=protected, Hidden)"
        "        sv_x    = strings(0,1)             % no state"
        "        sv_u    = [""omega""; ""Pmech_ref""]   % omega is read from the generator"
        "        sv_y    = ""Pmech""                  % drives Pmech of the generator"
        "        sv_para = ""K"""
        "    end"
        "    methods (Access={?Component})"
        "        function obj = Droop(tag, param)"
        "            arguments"
        "                tag (1,1) string"
        "                param.K (1,1) double = 20"
        "            end"
        "            obj@LocalController(""CG"" + tag);"
        "            obj.a_Parameter{1} = Parameter(obj, ""dynamics"", struct(K=param.K));"
        "        end"
        "    end"
        "    methods"
        "        function [x, u] = get_equilibrium(obj, V, u_gen)"
        "            x = zeros(0,1);"
        "            u = [0; u_gen(obj.a_Component.sv_u == ""Pmech"")];"
        "        end"
        "    end"
        "    methods (Static)"
        "        function dx = fcn_dx(t, x, V, u, p, w0), dx = zeros(0,1); end"
        "        function y = fcn_y(t, x, V, u, p, w0), y = u(2) - p(1)*u(1); end"
        "        function M = fcn_Mass(t, x, V, u, p, w0), M = zeros(0,0); end"
        "        function [A, Bv, Bu] = Jacobi_dx(t, x, V, u, p, w0)"
        "            A = zeros(0,0);  Bv = zeros(0,2);  Bu = zeros(0,2);"
        "        end"
        "        function [C, Dv, Du] = Jacobi_Y(t, x, V, u, p, w0)"
        "            C = zeros(1,0);  Dv = zeros(1,2);  Du = [-p(1), 1];"
        "        end"
        "    end"
        "end"];
    sv_cmd = [ ...
        "GUILDA.update_keymap;   % registers the key of the new class"
        "net = network.IEEE9bus();"
        "sc = net.add_scenario(""loss"", Time=[0, 30]);"
        "sc.add_input(""B002SG1"", ""Pmech"", -0.1, [1, 30]);   % 0.1 pu less Pmech from 1 s"
        "res0 = net.simulate(""loss"");   % default governors (gov-static)"
        "gens = [""B001SG1"", ""B002SG1"", ""B003SG1""];"
        "for s = gens, net.get_element(s).add_local_controller(""gov-droop""); end"
        "net.initialize();"
        "res1 = net.simulate(""loss"");   % gov-droop on the three generators"
        "res0.plot_trajectory(Quantity=""omega"");"
        "res1.plot_trajectory(Quantity=""omega"");"];

    % The class file, as the user saves it
    s_file = fullfile(GUILDA.pwd, s_dir, s_name);
    s_text = strjoin(sv_class, newline) + newline;
    if isfile(s_file) && string(fileread(s_file)) ~= s_text
        error("%s exists with other content; move it away first.", s_file);
    end
    obj_clean = onCleanup(@() remove_class(s_file));
    fid = fopen(s_file, "w");
    fprintf(fid, "%s", s_text);
    fclose(fid);
    rehash;

    % Run the commands as shown: the output of each, and the figures of the last two
    c_out = cell(numel(sv_cmd), 1);
    a_fig = gobjects(0, 1);
    for i = 1:numel(sv_cmd)
        a_old = findall(groot, "Type", "figure");
        c_out{i} = run_command(sv_cmd(i));
        a_new = setdiff(findall(groot, "Type", "figure"), a_old);
        a_fig = [a_fig; a_new(:)]; %#ok<AGROW>
    end
    if numel(a_fig) ~= 2
        error("The commands drew %d figures (2 expected).", numel(a_fig));
    end
    c_img = cell(1, 2);
    for k = 1:2
        figure(a_fig(k));
        drawnow;
        pause(0.2);
        c_img{k} = frame2im(getframe(a_fig(k)));
        imwrite(c_img{k}, sprintf("%s-fig%d.png", s_base, k));
    end
    fid = fopen(s_base + "-output.txt", "w");
    for i = 1:numel(sv_cmd)
        fprintf(fid, ">> %s\n%s", sv_cmd(i), c_out{i});
    end
    fclose(fid);
    close(a_fig);

    %% Scene: editor (left) and command window (right)
    fig = figure(Color="w", Units="pixels", Position=[40 40 1280 640], MenuBar="none", ToolBar="none");
    r_wEd = 620;
    ax_ed = pane_axes(fig, [0 0 r_wEd 640], [0.985 0.985 0.985]);
    ax_cw = pane_axes(fig, [r_wEd 0 1280 - r_wEd 640], [1 1 1]);
    line(ax_ed, [r_wEd r_wEd] - 0.5, [0 640], Color=[0.78 0.8 0.83], LineWidth=1);

    r_head = 30;
    patch(ax_ed, [0 r_wEd r_wEd 0], [640 - r_head 640 - r_head 640 640], [0.92 0.93 0.95], EdgeColor="none");
    h_tab = text(ax_ed, 12, 640 - r_head/2, "", FontName="Helvetica", FontUnits="pixels", ...
        FontSize=13, Interpreter="tex", VerticalAlignment="middle");
    set_tab(h_tab, s_dir, s_name, true);
    patch(ax_cw, [0 1 1 0]*(1280 - r_wEd), [640 - r_head 640 - r_head 640 640], [0.92 0.93 0.95], EdgeColor="none");
    text(ax_cw, 14, 640 - r_head/2, "Command Window", FontName="Helvetica", FontUnits="pixels", ...
        FontSize=13, FontWeight="bold", Color=[0.3 0.33 0.37], VerticalAlignment="middle");

    n_cls = numel(sv_class);
    r_dyEd = 14.6;
    r_y0Ed = 640 - r_head - 12;
    h_num = gobjects(n_cls, 1);
    h_cls = gobjects(n_cls, 1);
    for i = 1:n_cls
        r_y = r_y0Ed - (i - 1)*r_dyEd;
        h_num(i) = text(ax_ed, 30, r_y, string(i), FontName="Menlo", FontUnits="pixels", FontSize=11, ...
            Color=[0.62 0.64 0.67], HorizontalAlignment="right", VerticalAlignment="middle", Visible="off");
        h_cls(i) = text(ax_ed, 40, r_y, "", FontName="Menlo", FontUnits="pixels", FontSize=11.6, ...
            Interpreter="tex", VerticalAlignment="middle");
    end

    cw = make_console(ax_cw, 1280 - r_wEd, 640 - r_head - 12, 16.5);

    rec = make_recorder(fig);
    h_num(1).Visible = "on";
    h_cls(1).String = code_tex("", true, false);
    rec.hold(14);
    for i = 1:n_cls
        h_num(i).Visible = "on";
        type_editor_line(rec, h_cls(i), sv_class(i), 10);
        if i < n_cls
            h_num(i + 1).Visible = "on";
            h_cls(i + 1).String = code_tex(leading(sv_class(i + 1)), true, false);
        end
    end
    rec.hold(16);
    set_tab(h_tab, s_dir, s_name, false);       % saved
    rec.hold(30);

    for i = 1:numel(sv_cmd)
        cw.type(rec, sv_cmd(i), 4);
        cw.output(c_out{i});
        if i == 1
            rec.hold(24);
        elseif i < numel(sv_cmd) - 1
            rec.hold(6);
        end
    end
    cw.prompt();
    rec.hold(8);

    %% Scene: the two figures, under the commands that drew them
    delete(ax_ed);
    r_hFig = 405;                          % [px] height of the figure area at the bottom
    r_hStrip = 30;
    ax_cw.Position = [0 r_hFig + r_hStrip 1280 640 - r_hFig - r_hStrip];
    ax_cw.XLim = [0 1280];
    ax_cw.YLim = [0 640 - r_hFig - r_hStrip];
    delete(ax_cw.Children);
    cw = make_console(ax_cw, 1280, 640 - r_hFig - r_hStrip - 10, 16.5);
    cw.show_tail(sv_cmd(1:end - 2), c_out(1:end - 2));
    for k = 1:2
        ax_s = pane_axes(fig, [(k - 1)*640 r_hFig 640 r_hStrip], [0.97 0.975 0.98]);
        text(ax_s, 12, r_hStrip/2, code_tex(sv_cmd(end - 2 + k), false), FontName="Menlo", FontUnits="pixels", ...
            FontSize=13, Interpreter="tex", VerticalAlignment="middle");
        [r_h, r_w] = deal(size(c_img{k}, 1), size(c_img{k}, 2));
        r_wImg = 630;
        r_hImg = r_wImg*r_h/r_w;
        ax_i = axes(fig, Units="pixels", Position=[(k - 1)*640 + 5, (r_hFig - r_hImg)/2, r_wImg, r_hImg], Visible="off");
        image(ax_i, c_img{k});
        axis(ax_i, "off");
        ax_i.Toolbar.Visible = "off";
        disableDefaultInteractivity(ax_i);
    end
    line(ax_cw, [0 1280], [0.5 0.5], Color=[0.78 0.8 0.83]);
    rec.hold(4);
    rec.poster();
    rec.hold(90);
    rec.finish(s_base, 12);
    close(fig);
end


function s_out = run_command(s_cmd)
% Run one command line as typed (in the caller's workspace) and return what it prints.
    s_out = evalin("caller", "evalc(""" + replace(s_cmd, """", """""") + """)");
end


function remove_class(s_file)
% Delete the class file written for the recording and drop its key again.
    if isfile(s_file)
        delete(s_file);
    end
    rehash;
    evalc("GUILDA.update_keymap;");
end


function ax = pane_axes(fig, rv_pos, rv_color)
% Axes in pixels with data units = pixels, used as a pane background.
    ax = axes(fig, Units="pixels", Position=rv_pos, XLim=[0 rv_pos(3)], YLim=[0 rv_pos(4)], ...
        XTick=[], YTick=[], Color=rv_color, XColor="none", YColor="none", Clipping="on");
    ax.Toolbar.Visible = "off";
    disableDefaultInteractivity(ax);
    hold(ax, "on");
end


function set_tab(h, s_dir, s_name, l_dirty)
% Editor tab: folder in gray, file name in dark (with * while not saved).
    s = "\color[rgb]{0.5,0.52,0.56}" + escape_tex(s_dir) + "\color[rgb]{0.1,0.1,0.1}\bf" + escape_tex(s_name);
    if l_dirty
        s = s + " *";
    end
    h.String = s;
end


function s = leading(s_line)
% The indentation of a line (inserted at once, as an editor does).
    s = string(regexp(char(s_line), "^ *", "match", "once"));
end


function type_editor_line(rec, h, s_line, n_step)
% Type s_line into the editor line h, n_step characters per frame after the indentation.
    n0 = strlength(leading(s_line));
    n = strlength(s_line);
    for k = n0 + n_step:n_step:n + n_step - 1
        h.String = code_tex(extractBefore(s_line, min(k, n) + 1), true, false);
        rec.shot();
    end
    h.String = code_tex(s_line, false, false);
end


function cw = make_console(ax, r_w, r_yTop, r_dy)
% Command window in the axes ax: typed commands, their output, scrolling at the bottom.
%   cw.type(rec, s, n)   type the command s (n characters per frame) after a prompt
%   cw.output(s)         append the printed output s
%   cw.prompt()          an empty prompt with a cursor
%   cw.show_tail(sv, c)  show commands sv with their outputs c (no recording)
    n_row = floor((r_yTop - 6)/r_dy);
    h_row = gobjects(n_row, 1);
    for i = 1:n_row
        h_row(i) = text(ax, 14, r_yTop - (i - 1)*r_dy, "", FontName="Menlo", FontUnits="pixels", ...
            FontSize=12.2, Interpreter="tex", VerticalAlignment="middle", Clipping="on");
    end
    sv_row = strings(0, 1);         % TeX string of each row
    cw.type = @type_cmd;
    cw.output = @add_output;
    cw.prompt = @add_prompt;
    cw.show_tail = @show_tail;

    function draw()
        n = numel(sv_row);
        sv = sv_row(max(1, n - n_row + 1):n);
        for k = 1:n_row
            if k <= numel(sv)
                h_row(k).String = sv(k);
            else
                h_row(k).String = "";
            end
        end
    end

    function type_cmd(rec, s_cmd, n_step)
        sv_row(end + 1, 1) = code_tex("", true);
        draw();
        rec.hold(3);
        n = strlength(s_cmd);
        for k = n_step:n_step:n + n_step - 1
            sv_row(end) = code_tex(extractBefore(s_cmd, min(k, n) + 1), true);
            draw();
            rec.shot();
        end
        sv_row(end) = code_tex(s_cmd, false);
        draw();
        rec.shot();
    end

    function add_output(s_out)
        sv = splitlines(string(s_out));
        if ~isempty(sv) && sv(end) == ""
            sv(end) = [];
        end
        for k = 1:numel(sv)
            sv_row(end + 1, 1) = "\color[rgb]{0.15,0.15,0.15}" + escape_tex(sv(k)); %#ok<AGROW>
        end
        draw();
    end

    function add_prompt()
        sv_row(end + 1, 1) = code_tex("", true);
        draw();
    end

    function show_tail(sv_cmd, c_out)
        for k = 1:numel(sv_cmd)
            sv_row(end + 1, 1) = code_tex(sv_cmd(k), false); %#ok<AGROW>
            add_output(c_out{k});
        end
        draw();
    end
end


function s = code_tex(s_code, l_cursor, l_prompt)
% TeX string of a line of MATLAB code: keywords in blue, strings in purple, a comment in
% green, with the prompt ">> " (l_prompt, default true) and a cursor at the end (l_cursor).
    if nargin < 3
        l_prompt = true;
    end
    s_dark = "\color[rgb]{0.13,0.13,0.13}";
    s_str = "\color[rgb]{0.65,0.04,0.96}";
    s_com = "\color[rgb]{0.01,0.50,0.04}";
    s_key = "\color[rgb]{0.05,0.0,1.0}";
    s = s_dark;
    if l_prompt
        s = "\color[rgb]{0.55,0.57,0.60}>> " + s_dark;
    end
    c = char(s_code);
    k = 1;
    while k <= numel(c)
        ch = c(k);
        if ch == '%'
            s = s + s_com + escape_tex(string(c(k:end)));
            break
        elseif ch == '"'
            k_end = find(c(k + 1:end) == '"', 1) + k;
            if isempty(k_end)
                k_end = numel(c);
            end
            s = s + s_str + escape_tex(string(c(k:k_end))) + s_dark;
            k = k_end + 1;
            continue
        elseif isletter(ch) && (k == 1 || ~(is_word_char(c(k - 1)) || c(k - 1) == '.'))
            k_end = k;
            while k_end < numel(c) && is_word_char(c(k_end + 1))
                k_end = k_end + 1;
            end
            s_word = string(c(k:k_end));
            if ismember(s_word, ["classdef", "properties", "methods", "function", "end", "arguments", "for"])
                s = s + s_key + s_word + s_dark;
            else
                s = s + escape_tex(s_word);
            end
            k = k_end + 1;
            continue
        end
        s = s + escape_tex(string(ch));
        k = k + 1;
    end
    if l_cursor
        s = s + "\color[rgb]{0.07,0.44,0.75}|";
    end
end


function l = is_word_char(ch)
% Whether ch can be part of a MATLAB name (letter, digit or underscore).
    l = isletter(ch) || (ch >= '0' && ch <= '9') || ch == '_';
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
% rec.poster()             the next frame is the poster (default: the last frame)
% rec.finish(s_base, n)    write s_base.mp4 and s_base.png; the last n frames fade into the first
    r_fps = 20;
    s_dir = string(tempname);
    mkdir(s_dir);
    n_out = 0;
    i_poster = 0;
    iv_size = [640 1280];        % [px] rows, columns of the frames

    rec.r_fps = r_fps;
    rec.shot = @shot;
    rec.hold = @hold_frames;
    rec.poster = @mark_poster;
    rec.finish = @finish;

    function mark_poster()
        i_poster = n_out + 1;
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
