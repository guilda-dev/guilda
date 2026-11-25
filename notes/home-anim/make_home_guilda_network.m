function net = make_home_guilda_network(opt)
% Make the animated network diagram of the Home tab: the power flow of network.GUILDAlogo.
%
% network.GUILDAlogo is one meshed network laid out so that its diagram reads as GUILDA,
% with its generators and loads inside the letters. Its power flow solution is drawn by ResultPF.plot_diagram
% with the branches and links colored and sized by their current (ColorMode and
% BranchWidthMode "I", default colormap) and the flow dots of FlowMode "P".
%
% The dots of an element move FlowSpeed*d0*|q|/q_max per second and are 0.25*d0 apart
% (GraphNetDiagram step_flow), so the speeds of the elements have no common period. The
% loop is made seamless by a cross-fade: the frames F(t) are taken for t in [0, 2T), and
% the GIF shows, for t in [T, 2T), (1 - w)*F(t) + w*F(t - T) with w rising from 0 to 1
% over the last Fade part of the loop. The last frame then runs into F(T), the first.
% The GIF stores, after the first frame, only the pixels that change (the others are
% transparent), so that it stays small.
%
% Writes into _GUILDAdocPages/images/home/ (or OutDir):
%   guilda-network.gif  looping animation of the flow dots
%   guilda-network.png  still of the first frame
%
% Only the graph is kept: no title, axes, labels, colorbar, control panel or playback bar
% (one sample, axes given as Parent; the colorbar is deleted). The image is the hero of
% the Home page: it is Width wide, cropped around the letters (x 0-25.4, y 0-6 in the
% diagram) with an even Margin, on the page background (--surface of style.css, white).
% The dots are moved with G.step_flow (the flow timer is not made in matlab -batch).
% Run with R2026a:
%   addpath("notes/home-anim"); make_home_guilda_network();
    arguments (Input)
        opt.OutDir (1,1) string = ""                    % Output folder; "" for _GUILDAdocPages/images/home.
        opt.Width (1,1) double {mustBeInteger, mustBePositive} = 1200  % [px] Width of the frames (the height follows the letters).
        opt.Margin (1,1) double {mustBeNonnegative} = 0.4  % Margin around the letters, in units of the diagram.
        opt.Frames (1,1) double {mustBeInteger, mustBePositive} = 60  % Frames of one loop.
        opt.Delay (1,1) double {mustBePositive} = 0.05  % [s] Time of each frame of the GIF.
        opt.Period (1,1) double {mustBePositive} = 3    % [s] Time T of the flow of one loop.
        opt.Fade (1,1) double {mustBeInRange(opt.Fade, 0, 1)} = 0.3  % Part of the loop over which the cross-fade runs.
        opt.Colors (1,1) double {mustBeInteger, mustBeInRange(opt.Colors, 2, 256)} = 128  % Colors of the GIF palette.
    end
    s_out = opt.OutDir;
    if s_out == ""
        s_root = fileparts(fileparts(fileparts(mfilename("fullpath"))));   % notes/home-anim -> notes -> root
        s_out = fullfile(s_root, "_GUILDAdocPages", "images", "home");
    end
    if ~isfolder(s_out)
        mkdir(s_out);
    end

    %% Network and power flow
    net = network.GUILDAlogo();
    [res, flag] = net.calculate_powerflow(Progress="none");
    assert(flag == 1, "The power flow of network.GUILDAlogo did not converge.");

    %% Drawing: only the graph, in axes that fill a white figure
    rv_x = [0, 25.4] + [-1, 1]*opt.Margin;          % the letters and the margin
    rv_y = [0, 6] + [-1, 1]*opt.Margin;
    rv_size = [opt.Width, round(opt.Width*diff(rv_y)/diff(rv_x))];
    fig = figure(Visible="off", Color="w", Units="pixels", Position=[100, 100, rv_size]);
    ax  = axes(fig, Units="normalized", Position=[0, 0, 1, 1]);
    G = res.plot_diagram(Parent=ax, ColorMode="I", BranchWidthMode="I", BranchWidthRange=[2.5 7], ...
        LinkWidth=1.5, MarkerSizeRange=[9 9], LabelMode="none", TitleFormat="", ...
        FlowMode="P", FlowSpeed=1, FlowAnimation=false);
    delete(findobj(fig, "Type", "colorbar"));
    axis(ax, "off");
    xlim(ax, rv_x);
    ylim(ax, rv_y);

    %% Frames F(t), t = 0, T/n, ..., 2T - T/n
    n = opt.Frames;
    c_raw = cell(2*n, 1);
    for i = 1:2*n
        G.step_flow(opt.Period/n * (i > 1));
        drawnow;
        rgb = frame2im(getframe(fig));
        if ~isequal(size(rgb, [1 2]), rv_size([2 1]))
            rgb = imresize(rgb, rv_size([2 1]));
        end
        c_raw{i} = rgb;
    end
    close(fig);

    % loop frame i (t = T + (i-1)*T/n): (1 - w)*F(t) + w*F(t - T)
    c_frame = cell(n, 1);
    for i = 1:n
        r_s = (i - 1)/n;                               % position in the loop, 0 .. 1 - 1/n
        w = min(max((r_s - (1 - opt.Fade))/opt.Fade, 0), 1);
        w = w^2*(3 - 2*w);                             % smoothstep
        c_frame{i} = uint8((1 - w)*double(c_raw{n + i}) + w*double(c_raw{i}));
    end

    imwrite(c_frame{1}, fullfile(s_out, "guilda-network.png"));
    [~, cmap] = rgb2ind(cat(1, c_frame{:}), opt.Colors - 1, "nodither");
    [~, i_white] = min(sum((1 - cmap).^2, 2));
    cmap(i_white, :) = 1;                      % the background stays pure white
    % After the first frame, the pixels that keep their color are written with the last
    % index of the palette, which is transparent: the frame before stays (leaveInPlace)
    i_keep = size(cmap, 1);                    % 0-based index of the extra color
    cmap(end + 1, :) = [1 0 1];
    s_gif = fullfile(s_out, "guilda-network.gif");
    X_prev = [];
    for i = 1:n
        X = rgb2ind(c_frame{i}, cmap(1:end-1, :), "nodither");
        if i == 1
            imwrite(X, cmap, s_gif, "gif", LoopCount=Inf, DelayTime=opt.Delay, DisposalMethod="leaveInPlace");
        else
            X_out = X;
            X_out(X == X_prev) = i_keep;
            imwrite(X_out, cmap, s_gif, "gif", WriteMode="append", DelayTime=opt.Delay, ...
                DisposalMethod="leaveInPlace", TransparentColor=i_keep);
        end
        X_prev = X;
    end
    fprintf("%s (%d x %d px, %d frames, %.0f kB)\n%s\n", s_gif, rv_size, n, dir(s_gif).bytes/1024, ...
        fullfile(s_out, "guilda-network.png"));
end
