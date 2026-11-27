function make_about_analysis(opt)
% Make the videos of the carousel of analysis features in the About tab of the docs site.
%
% Each video is a MATLAB session: the code of the slide (sv_code of each item below, the
% "code" of images/about/analysis/manifest.md) is typed line by line into a drawn Command
% Window, each line is run as it is (evalc in the base workspace, so its variables net, res,
% ... are overwritten there) and its printed output is shown under it, and the figures that
% the code draws are shown as GUILDA draws them, one at a time in the frame. Nothing is
% drawn on the figures and no other code changes them: the frames are taken with getframe
% and only scaled to fit 1280 x 640. The output text is the captured text with the hyperlink
% markup of -batch removed (the Command Window of the desktop shows it as plain words).
% Items (file names in OutDir):
%
%   01-fault-simulation.mp4   IEEE 14-bus: a fault at bus B008 simulated and drawn with
%                             ResultODE.plot_diagram(Trajectory="omega"), then played
%                             with G.animate()
%   03-controller-pss.mp4     IEEE 68-bus with AVRs only, then a PSS added to one generator
%                             after another in a for loop: the eigenvalue map of get_sys and
%                             the omega of a fault simulation are drawn again at each pass
%                             (the figure above, the printed lines below)
%   06-stability-opf.mp4      IEEE 14-bus: the stability-constrained OPF (MinDampingRatio),
%                             its outer iterations, plot_dispatch, then the network
%                             initialized at the solution, its modes and plot_eigenvalue
%   07-cpf-eigenvalue.mp4     IEEE 14-bus: the continuation power flow linearized at each
%                             step (get_sys({cpf, steps})): eigenvalue map linked with the PV
%                             curve, played with G.animate()
%
% A line G.animate(...) of the code is run with two more options, Speed=Inf and
% UpdateFcn (which takes a frame of the video; it draws nothing), so that every frame of
% animate is one frame of the video; the video (20 frames/s) then plays at the speed of
% the shown call. A for loop is run one pass at a time (the shown body with i set to each
% value of the loop in turn), so that the figure of each pass is recorded. In matlab
% -batch the progress dialogs of the analyses show nothing (ProgressGUILDA), as Progress
% "dialog" (the default) needs a window.
%
% Each video has a PNG poster of the same name. Encoding: ffmpeg, H.264, yuv420p,
% faststart, 1280 x 640, 20 fps, under 3 MB; the last frames fade into the first, so that
% the video loops.
%
% Run with R2026a and ffmpeg installed (matlab -batch works):
%   GUILDA.addpath(); addpath("notes/about-anim"); make_about_analysis(OutDir="/tmp/analysis");
%   make_about_analysis(Item="opf", OutDir="/tmp/analysis");   % one item only
    arguments (Input)
        opt.OutDir (1,1) string = ""     % Output folder; "" for _GUILDAdocPages/images/about/analysis.
        opt.Item (1,:) string {mustBeMember(opt.Item, ["fault", "controller", "opf", "cpf"])} ...
            = ["fault", "controller", "opf", "cpf"]  % Items to make.
    end
    s_out = opt.OutDir;
    if s_out == ""
        s_root = fileparts(fileparts(fileparts(mfilename("fullpath"))));   % notes/about-anim -> notes -> root
        s_out = fullfile(s_root, "_GUILDAdocPages", "images", "about", "analysis");
    end
    if ~isfolder(s_out)
        mkdir(s_out);
    end
    for s_item = opt.Item
        fprintf("== %s\n", s_item);
        close all force
        switch s_item
            case "fault"
                make_fault(fullfile(s_out, "01-fault-simulation"));
            case "controller"
                make_controller(fullfile(s_out, "03-controller-pss"));
            case "opf"
                make_stability_opf(fullfile(s_out, "06-stability-opf"));
            case "cpf"
                make_cpf_eigenvalue(fullfile(s_out, "07-cpf-eigenvalue"));
        end
        close all force
    end
end


%% Items

function make_fault(s_base)
% A fault at bus B008 of IEEE 14-bus from 1 s to 1.05 s: five lines typed, then the figure
% of plot_diagram played by animate (TimeStep 0.05 s at PlaySpeed 1: real time at 20 fps).
    sv_code = [ ...
        "net = network.IEEE14bus();"
        "sc = net.add_scenario(""fault"", Time=[0, 5]);"
        "sc.add_fault(""B008"", [1, 1.05]);   % fault at bus B008"
        "res = net.simulate(""fault"");"
        "G = res.plot_diagram(Trajectory=""omega"");"
        "G.animate();"];
    ses = make_session(FontSize=21, LineHeight=62);
    ses.hold(12);
    for i = 1:5
        ses.type(sv_code(i));
        ses.run(sv_code(i));
        ses.hold(6);
    end
    fig = ses.last_figure();
    ses.show(fig);
    ses.hold(16);
    ses.type(sv_code(6));          % typed in the Command Window, then the figure plays
    ses.hold(4);
    ses.show(fig);
    ses.poster_at(28);
    ses.animate(sv_code(6));
    ses.hold(30);
    ses.finish(s_base, 12);
end


function make_controller(s_base)
% IEEE 68-bus with the AVRs (avr-ST1) of LocalController=true and no PSS; a PSS (pss-PSS1)
% is added to one generator after another in a for loop that initializes, linearizes,
% simulates a fault and draws both results in one figure at each pass.
    sv_setup = [ ...
        "net = network.IEEE68bus(LocalController=true);"
        "for i = 1:16                                   % AVRs only: remove the PSSs"
        "    gen = net.a_Bus{i}.a_Component{1};"
        "    gen.remove_local_controller(gen.pss.s_tag);"
        "end"
        "sc = net.add_scenario(""fault"", Time=[0, 15]);"
        "sc.add_fault(""B001"", [1, 1.05]);"
        "prm = struct(kpss=25, tWS=10, tn1=0.07, td1=0.02, tn2=0.07, td2=0.02);"
        "fig = figure(Position=[100 100 1280 500]);"];
    sv_loop = [ ...
        "for i = 0:16"
        "    if i > 0"
        "        net.a_Bus{i}.a_Component{1}.add_local_controller(""pss-PSS1"", parameter=prm);"
        "    end"
        "    net.initialize();"
        "    lin = net.get_sys();"
        "    sim = net.simulate(""fault"");"
        "    clf(fig);"
        "    lin.plot_eigenvalue(Parent=uipanel(fig, Position=[0 0 0.5 1]));"
        "    sim.plot_trajectory(Quantity=""omega"", Parent=uipanel(fig, Position=[0.5 0 0.5 1]));"
        "    fprintf(""%2d PSSs: %2d unstable eigenvalues\n"", i, sum(real(lin.get_eigenvalue()) > 1e-6));"
        "end"];
    ses = make_session(FontSize=15, LineHeight=25);
    ses.hold(8);
    ses.type_block(sv_setup(1), 4);
    ses.run(sv_setup(1));
    ses.type_block(sv_setup(2:5), 6);
    ses.run(strjoin(sv_setup(2:5), newline));
    for i = 6:numel(sv_setup)
        ses.type_block(sv_setup(i), 5);
        ses.run(sv_setup(i));
    end
    fig = evalin("base", "fig");
    ses.type_block(sv_loop, 7);
    ses.hold(10);
    ses.split(fig, 140);
    iv_pass = 0:16;
    for i = iv_pass
        ses.run_pass(sv_loop, "i", i);
        if i == 0
            ses.hold(40);
        elseif i == 16
            ses.prompt();
            ses.poster_at(1);
            ses.hold(60);
        else
            ses.hold(12);
        end
    end
    ses.finish(s_base, 12);
end


function make_stability_opf(s_base)
% The stability-constrained OPF of IEEE 14-bus (MinDampingRatio 0.048): the outer
% iterations and plot_dispatch, then the network initialized at the solution, linearized,
% its electromechanical modes and the eigenvalue map.
    sv_code = [ ...
        "net = network.IEEE14bus();"
        "res = net.calculate_optimal_powerflow(Method=""AC OPF"", MinDampingRatio=0.048);"
        "res.sct_stability.tab_iteration(:, [""Iteration"", ""Cost"", ""MinDampingRatio""])"
        "res.plot_dispatch();"
        "net.initialize(Method=""OPF"", MinDampingRatio=0.048);   % the solution as the operating point"
        "lin = net.get_sys();"
        "lin.disp_mode(MinFrequency=0.1)"
        "lin.plot_eigenvalue();"];
    ses = make_session(FontSize=16, LineHeight=27);
    ses.hold(8);
    for i = 1:3
        ses.type(sv_code(i));
        ses.run(sv_code(i));
        ses.hold(6);
    end
    ses.hold(50);
    ses.type(sv_code(4));
    ses.run(sv_code(4));
    ses.hold(4);
    ses.show(ses.last_figure());
    ses.hold(60);
    ses.cmd();
    for i = 5:7
        ses.type(sv_code(i));
        ses.run(sv_code(i));
        ses.hold(6);
    end
    ses.poster_at(1);
    ses.hold(50);
    ses.type(sv_code(8));
    ses.run(sv_code(8));
    ses.hold(4);
    ses.show(ses.last_figure());
    ses.hold(60);
    ses.finish(s_base, 12);
end


function make_cpf_eigenvalue(s_base)
% The continuation power flow of IEEE 14-bus (loads at B009 and B014 increased), linearized
% at its steps 1 to 140; the eigenvalue map and the PV curve in one figure, linked, played
% with animate (one step per frame, 20 steps per second).
    sv_code = [ ...
        "net = network.IEEE14bus();"
        "net.initialize();"
        "cpf = net.calculate_continuation_powerflow(LoadBus=[""B009"", ""B014""]);"
        "cpf.r_lambdaMax"
        "lin = net.get_sys({cpf, 1:140});                 % linearize at steps 1 to 140"
        "fig = figure(Position=[100 100 1280 640]);"
        "G = lin.plot_eigenvalue(Parent=uipanel(fig, Position=[0 0 0.5 1]));"
        "G.link(cpf.plot_pvcurve(Parent=uipanel(fig, Position=[0.5 0 0.5 1])));"
        "G.animate(TimeStep=1, Speed=20);"];
    ses = make_session(FontSize=16, LineHeight=30);
    ses.hold(8);
    for i = 1:8
        ses.type(sv_code(i));
        ses.run(sv_code(i));
        ses.hold(5);
    end
    ses.hold(10);
    fig = evalin("base", "fig");
    ses.show(fig);
    ses.hold(16);
    ses.cmd();
    ses.type(sv_code(9));
    ses.hold(4);
    ses.show(fig);
    ses.poster_at(110);
    ses.animate(sv_code(9));
    ses.hold(40);
    ses.finish(s_base, 12);
end


%% Session: a drawn Command Window, the code run in the base workspace, and the frames

function ses = make_session(opt)
% A recorded MATLAB session. The Command Window is drawn in a figure of its own (rows of
% code and output); a frame shows it, a figure of the code, or the figure above a strip of
% the Command Window, scaled into 1280 x 640.
%
% ses.type(s)            type the line s after the prompt (with a cursor)
% ses.type_block(sv, k)  type the lines sv (one command over several lines), k characters a frame
% ses.run(s)             run s (evalc in the base workspace) and show its output
% ses.run_pass(sv, s, v) run the body of the for loop sv with its variable s = v
% ses.prompt()           the prompt after the last pass of a loop
% ses.animate(s)         run the line s = "G.animate(...)" with every frame of it recorded
% ses.last_figure()      the newest figure of the code
% ses.cmd() / ses.show(fig) / ses.split(fig, h)   what the next frames show
% ses.hold(n)            n frames
% ses.poster_at(n)       the poster is the n-th frame from now
% ses.finish(s_base, n)  write s_base.mp4 and s_base.png; the last n frames fade into the first
    arguments (Input)
        opt.FontSize (1,1) double = 16      % [pt] Font of the Command Window.
        opt.LineHeight (1,1) double = 27    % [px] Height of a row of the Command Window.
    end
    iv_size = [640 1280];                   % [px] rows, columns of the frames
    r_fps = 20;
    s_dir = string(tempname);
    mkdir(s_dir);
    n_out = 0;
    i_poster = 0;
    s_mode = "cmd";
    fig_show = [];
    r_strip = 0;
    rows = struct("kind", {}, "text", {});  % kind: "cmd", "cont" (a continued command) or "out"
    a_before = findall(groot, "Type", "figure");

    % The Command Window figure (its size is set by the mode of the frame)
    fig_cw = figure(Color="w", Position=[40 40 iv_size(2) iv_size(1)], MenuBar="none", ToolBar="none", ...
        Name="Command Window", NumberTitle="off", HandleVisibility="off");
    ax_cw = axes(fig_cw, Units="normalized", Position=[0 0 1 1], XTick=[], YTick=[], Box="on", ...
        Color=[0.97 0.975 0.98], XColor=[0.82 0.84 0.86], YColor=[0.82 0.84 0.86]);
    ax_cw.Toolbar.Visible = "off";
    disableDefaultInteractivity(ax_cw);
    h_head = text(ax_cw, 0, 0, "Command Window", FontName="Helvetica", FontSize=15, FontWeight="bold", ...
        Color=[0.35 0.38 0.42], Interpreter="none", VerticalAlignment="middle");
    h_row = gobjects(0, 1);

    ses.type = @type_line;
    ses.type_block = @type_block;
    ses.run = @run_code;
    ses.run_pass = @run_pass;
    ses.animate = @run_animate;
    ses.prompt = @add_prompt;
    ses.last_figure = @last_figure;
    ses.cmd = @() set_mode("cmd", [], 0);
    ses.show = @(fig) set_mode("fig", fig, 0);
    ses.split = @(fig, h) set_mode("split", fig, h);
    ses.hold = @hold_frames;
    ses.poster_at = @set_poster;
    ses.finish = @finish;

    function set_poster(n)
        i_poster = n_out + n;
    end

    function set_mode(s, fig, h)
        s_mode = s;
        fig_show = fig;
        r_strip = h;
    end

    function type_line(s_code)
        set_mode("cmd", [], 0);
        type_block(s_code, 3);
    end

    function type_block(sv_code, n_char)
        % Type the lines one after another; the first after the prompt, the others continued.
        if s_mode == "fig"
            set_mode("cmd", [], 0);
        end
        drop_prompt();
        for j = 1:numel(sv_code)
            s_kind = "cmd";
            if j > 1
                s_kind = "cont";
            end
            rows(end+1) = struct("kind", s_kind, "text", ""); %#ok<AGROW>
            n = strlength(sv_code(j));
            for k = n_char:n_char:n + n_char - 1
                rows(end).text = extractBefore(sv_code(j), min(k, n) + 1);
                shot(true);
            end
            rows(end).text = sv_code(j);
        end
        shot(false);
    end

    function drop_prompt()
        % The empty prompt shown after the last output is where the typing goes.
        if ~isempty(rows) && rows(end).kind == "cmd" && rows(end).text == ""
            rows(end) = [];
        end
    end

    function run_code(s_code)
        add_output(eval_base(s_code));
        add_prompt();
    end

    function run_pass(sv_loop, s_var, v)
        % The body of the loop sv_loop (between its first and last line) with s_var = v.
        s_code = sprintf("for %s = %d", s_var, v) + newline + strjoin(sv_loop(2:end-1), newline) + newline + "end";
        drop_prompt();
        add_output(eval_base(s_code));
    end

    function add_prompt()
        rows(end+1) = struct("kind", "cmd", "text", "");
    end

    function run_animate(s_code)
        % s_code is "G.animate(...)": run with Speed=Inf and UpdateFcn taking a frame.
        s_call = regexprep(strip(s_code), "Speed=[^,)]*(, )?", "");
        s_call = regexprep(s_call, ",?\s*\);$", "");             % without ");"
        if endsWith(s_call, "(")
            s_call = s_call + "Speed=Inf, UpdateFcn=f_shot__);";
        else
            s_call = s_call + ", Speed=Inf, UpdateFcn=f_shot__);";
        end
        assignin("base", "f_shot__", @(t) shot(false));
        evalin("base", s_call);
        evalin("base", "clear f_shot__");
        add_prompt();
    end

    function fig = last_figure()
        a_now = findall(groot, "Type", "figure");
        a_new = a_now(~ismember(a_now, [a_before; fig_cw]));
        [~, k] = max(arrayfun(@(f) double(f.Number), a_new));
        fig = a_new(k);                       % the newest: the largest figure number
    end

    function add_output(s_txt)
        s_txt = regexprep(s_txt, "<[^>]*>", "");              % hyperlink markup of -batch
        s_txt = replace(s_txt, char(9), "    ");
        sv = splitlines(string(s_txt));
        while ~isempty(sv) && strtrim(sv(end)) == ""
            sv(end) = [];
        end
        l_blank = false;
        for j = 1:numel(sv)
            l_now = strtrim(sv(j)) == "";
            if l_now && (l_blank || j == 1)
                continue                        % one blank row at most, none first
            end
            rows(end+1) = struct("kind", "out", "text", sv(j)); %#ok<AGROW>
            l_blank = l_now;
        end
    end

    function hold_frames(n)
        for j = 1:n
            shot(false);
        end
    end

    function m = draw_cw(n_h, l_cursor)
        % Image of the Command Window, n_h px high: the last rows that fit.
        fig_cw.Position(3:4) = [iv_size(2), n_h];
        ax_cw.XLim = [0 iv_size(2)];
        ax_cw.YLim = [0 n_h];
        r_dy = opt.LineHeight;
        if n_h >= iv_size(1)
            r_top = n_h - 34;
            h_head.Visible = "on";
            h_head.Position = [40, r_top, 0];
            r_y0 = r_top - 26 - r_dy/2 - 8;
        else
            h_head.Visible = "off";
            r_y0 = n_h - 10 - r_dy/2;
        end
        n_fit = floor((r_y0 + r_dy/2)/r_dy);
        i0 = max(1, numel(rows) - n_fit + 1);
        n_show = numel(rows) - i0 + 1;
        while numel(h_row) < n_show
            h_row(end+1, 1) = text(ax_cw, 0, 0, "", FontName="Menlo", FontSize=opt.FontSize, ...
                Interpreter="tex", VerticalAlignment="middle"); %#ok<AGROW>
        end
        for j = 1:numel(h_row)
            if j <= n_show
                rw = rows(i0 + j - 1);
                l_cur = l_cursor && (i0 + j - 1 == numel(rows));
                h_row(j).String = row_tex(rw.kind, rw.text, l_cur || (rw.kind == "cmd" && rw.text == "" && i0 + j - 1 == numel(rows)));
                h_row(j).Position = [40, r_y0 - (j - 1)*r_dy, 0];
                h_row(j).Visible = "on";
            else
                h_row(j).Visible = "off";
            end
        end
        m = grab(fig_cw, [n_h, iv_size(2)]);
    end

    function shot(l_cursor)
        m_out = 255*ones(iv_size(1), iv_size(2), 3, "uint8");
        switch s_mode
            case "cmd"
                m_out = draw_cw(iv_size(1), l_cursor);
            case "fig"
                m_out = place(m_out, grab(fig_show, []), [1, 1, iv_size(2), iv_size(1)]);
            case "split"
                n_top = iv_size(1) - r_strip;
                m_out = place(m_out, grab(fig_show, []), [1, 1, iv_size(2), n_top]);
                m_out(n_top+1:end, :, :) = draw_cw(r_strip, l_cursor);
        end
        n_out = n_out + 1;
        imwrite(m_out, frame_file(n_out));
    end

    function s = frame_file(k)
        s = fullfile(s_dir, sprintf("f%05d.png", k));
    end

    function finish(s_base, n_fade)
        if i_poster == 0 || i_poster > n_out
            i_poster = n_out;
        end
        m_first = double(imread(frame_file(1)));
        m_last = double(imread(frame_file(n_out)));
        for j = 1:n_fade
            r_w = (1 - cos(pi*j/(n_fade + 1)))/2;
            n_out = n_out + 1;
            imwrite(uint8((1 - r_w)*m_last + r_w*m_first), frame_file(n_out));
        end
        s_in = fullfile(s_dir, "f%05d.png");
        for r_crf = [20, 23, 26, 29, 32]
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
        close(fig_cw);
    end
end


function m = grab(fig, iv_hw)
% Frame of the figure fig (getframe; in matlab -batch after a drawnow and a short pause,
% else it returns the frame before), resized to iv_hw = [rows, columns] when given.
    drawnow;
    pause(0.02);
    drawnow;
    m = frame2im(getframe(fig));
    if ~isempty(iv_hw) && ~isequal(size(m, [1 2]), iv_hw)
        m = imresize(m, iv_hw, "lanczos3");
    end
end


function m = place(m, m_img, rv_box)
% Put m_img into the box [x, y, w, h] (px, from the top left) of m, scaled to fit, centered.
    r_s = min(rv_box(3)/size(m_img, 2), rv_box(4)/size(m_img, 1));
    iv_hw = max(1, round(size(m_img, [1 2])*r_s));
    m_img = imresize(m_img, iv_hw, "lanczos3");
    i_y = rv_box(2) + floor((rv_box(4) - iv_hw(1))/2);
    i_x = rv_box(1) + floor((rv_box(3) - iv_hw(2))/2);
    m(i_y:i_y + iv_hw(1) - 1, i_x:i_x + iv_hw(2) - 1, :) = m_img;
end


function s_txt = eval_base(s_code)
% Run the code s_code (one or more lines) in the base workspace; its printed output.
    assignin("base", "s_code__", s_code);
    s_txt = evalin("base", "evalc(s_code__)");
    evalin("base", "clear s_code__");
    fprintf("%s", s_txt);                 % the output, also in the log of the run
end


function s = row_tex(s_kind, s_text, l_cursor)
% TeX string of a row of the Command Window: a command (prompt in gray, strings in purple,
% a comment in green), a continued command, or output (dark gray); with l_cursor, a cursor.
    switch s_kind
        case "out"
            s = "\color[rgb]{0.20,0.20,0.20}" + escape_tex(s_text);
        otherwise
            if s_kind == "cmd"
                s = "\color[rgb]{0.55,0.57,0.60}>> ";
            else
                s = "   ";
            end
            s = s + code_tex(s_text);
    end
    if l_cursor
        s = s + "\color[rgb]{0.07,0.44,0.75}|";
    end
end


function s = code_tex(s_code)
% TeX string of MATLAB code: strings in purple, a comment in green.
    s_dark = "\color[rgb]{0.13,0.13,0.13}";
    s_str = "\color[rgb]{0.65,0.04,0.96}";
    s_com = "\color[rgb]{0.01,0.50,0.04}";
    s = s_dark;
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
end


function s = escape_tex(s)
% Escape the characters of the TeX interpreter.
    s = replace(s, ["\", "_", "^", "{", "}"], ["\\", "\_", "\^", "\{", "\}"]);
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
