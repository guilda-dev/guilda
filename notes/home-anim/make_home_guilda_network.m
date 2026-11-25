function net = make_home_guilda_network(opt)
% Make the animated network diagram of the Home tab: a power network that spells GUILDA.
%
% The buses are the ends and corners of the strokes and the branches are the strokes
% (curves are bend points of the branch Path). Each letter is a tree of lossless lines
% (R = 0, C = 0) with its own generators and loads, balanced in itself, so the active
% power of every branch is a whole multiple of 0.1 pu and the flows are exact. D has two
% parallel lines of the same X (its straight stroke and its bow), which take half each.
% The crossbar of A ends at a bus of its own on the right leg (the leg is one branch), so
% A stays a tree. The letters are joined by white tie lines with no active power flow
% (they carry no dots); the slack generator is at the upper end of G.
%
% Flow of each stroke [0.1 pu]: G 5 4 3 3, U 4 3 2, I 2 2 4 2 2, L 4 3, D 3 3, A 5 4 4 1.
% The dots of a stroke move 4*FlowSpeed*|q|/q_max dot spacings per second (GraphNetDiagram
% step_flow), with q_max = 0.6 pu (the generator and the load of D). The frames are taken
% every T/n seconds with 4*FlowSpeed*T = 6, so over the loop every stroke moves by a whole
% number of spacings (|q|/0.1 pu of them) and the last frame runs into the first.
%
% Writes into _GUILDAdocPages/images/home/ (or OutDir):
%   guilda-network.gif  looping animation of the flow dots (FlowMode "P")
%   guilda-network.png  still of the first frame
%
% Only the graph is kept: no title, axes, labels, colorbar (fixed colors, ColorMode
% "none"), control panel or playback bar (one sample, axes given as Parent). The dots are
% moved with G.step_flow (the flow timer is not made in matlab -batch). Run with R2026a:
%   addpath("notes/home-anim"); make_home_guilda_network();
    arguments (Input)
        opt.OutDir (1,1) string = ""                    % Output folder; "" for _GUILDAdocPages/images/home.
        opt.Size (1,2) double {mustBePositive} = [1200, 400]  % [px] Size of the frames.
        opt.Frames (1,1) double {mustBeInteger, mustBePositive} = 36  % Frames of one loop.
        opt.Delay (1,1) double {mustBePositive} = 0.05  % [s] Time of each frame of the GIF.
    end
    s_out = opt.OutDir;
    if s_out == ""
        s_root = fileparts(fileparts(fileparts(mfilename("fullpath"))));   % notes/home-anim -> notes -> root
        s_out = fullfile(s_root, "_GUILDAdocPages", "images", "home");
    end
    if ~isfolder(s_out)
        mkdir(s_out);
    end

    %% Network
    H   = 5;                               % letter height
    arc = @(cx, cy, rx, ry, th) [cx + rx*cosd(th(:)), cy + ry*sind(th(:))];
    % Buses: tag, x, y, letter, P [0.1 pu] (+: generator, -: load, 0: none)
    c_bus = {
        % G: arc from 45 deg round the left to -30 deg, up, and the bar inward
        "G1", 1.3 + 1.3*cosd(45),  2.5 + 2.5*sind(45),  1,  5   % slack
        "G2", 0,                   2.5,                 1, -1
        "G3", 1.3 + 1.3*cosd(-30), 2.5 + 2.5*sind(-30), 1, -1
        "G4", 1.3 + 1.3*cosd(-30), 2.3,                 1,  0
        "G5", 1.4,                 2.3,                 1, -3
        % U
        "U1", 3.3, H,   2,  4
        "U2", 3.3, 1.6, 2, -1
        "U3", 5.5, 1.6, 2, -1
        "U4", 5.5, H,   2, -2
        % I with serifs
        "I1", 6.8, H, 3,  0
        "I2", 6.8, 0, 3,  0
        "I3", 6.2, H, 3,  2
        "I4", 7.4, H, 3,  2
        "I5", 6.2, 0, 3, -2
        "I6", 7.4, 0, 3, -2
        % L
        "L1", 8.1, H, 4,  4
        "L2", 8.1, 0, 4, -1
        "L3", 9.9, 0, 4, -3
        % D
        "D1", 10.6, H, 5,  6
        "D2", 10.6, 0, 5, -6
        % A: the crossbar ends at A5 on the right leg A1-A3
        "A1", 14.8,                  H,   6,  0
        "A2", 13.5,                  0,   6,  5
        "A3", 16.1,                  0,   6, -4
        "A4", 13.5 + 1.3*1.7/H,      1.7, 6,  0
        "A5", 16.1 - 1.3*1.7/H,      1.7, 6, -1
        };
    % Branches: from, to, letter (0: tie), path
    c_branch = {
        % ties (no active power), white, first so that the letters are drawn over them;
        % the D-A tie runs below the letters
        "G4", "U2", 0, []
        "U3", "I5", 0, []
        "I6", "L2", 0, []
        "L3", "D2", 0, []
        "D2", "A2", 0, [10.6, -0.8; 13.5, -0.8]
        "G1", "G2", 1, arc(1.3, 2.5, 1.3, 2.5, 55:10:175)
        "G2", "G3", 1, arc(1.3, 2.5, 1.3, 2.5, 190:10:325)
        "G3", "G4", 1, []
        "G4", "G5", 1, []
        "U1", "U2", 2, []
        "U2", "U3", 2, arc(4.4, 1.6, 1.1, 1.6, 190:10:350)
        "U3", "U4", 2, []
        "I3", "I1", 3, []
        "I4", "I1", 3, []
        "I1", "I2", 3, []
        "I2", "I5", 3, []
        "I2", "I6", 3, []
        "L1", "L2", 4, []
        "L2", "L3", 4, []
        "D1", "D2", 5, []
        "D1", "D2", 5, [11.4, H; arc(11.4, 2.5, 1.4, 2.5, 80:-10:-80); 11.4, 0]
        "A2", "A4", 6, []
        "A4", "A1", 6, []
        "A1", "A3", 6, []
        "A4", "A5", 6, []
        };

    net = PowerNetwork();
    for i = 1:height(c_bus)
        net.add_bus(FullTag=c_bus{i, 1}, X=c_bus{i, 2}, Y=c_bus{i, 3}, Shape="circle");
    end
    for k = 1:height(c_branch)
        rm_path = c_branch{k, 4};
        if isempty(rm_path)
            rm_path = "";
        end
        net.add_branch("pi", [c_branch{k, 1}, c_branch{k, 2}], R=0, X=0.05, C=0, Path=rm_path);
    end
    for i = 1:height(c_bus)
        r_p = c_bus{i, 5}/10;
        if r_p > 0
            net.a_Bus{i}.add_component("gen-classical", P=r_p, DX=0, DY=0, Shape="none");
        elseif r_p < 0
            net.a_Bus{i}.add_component("load-power", P=r_p, Q=0, DX=0, DY=0, Shape="none");
        end
    end
    evalc("net.a_Bus{1}.l_isSlack = true;");   % the slack bus (GUILDA never selects one)
    [res, flag] = net.calculate_powerflow(Progress="none");
    assert(flag == 1, "The power flow of the GUILDA network did not converge.");

    %% Drawing: only the graph, in axes that fill a white figure
    rm_color = hex2rgb(["#1171BE", "#DD5400", "#EDB120", "#8516D1", "#3BAA32", "#2FBEEF"]);
    fig = figure(Visible="off", Color="w", Units="pixels", Position=[100, 100, opt.Size]);
    ax  = axes(fig, Units="normalized", Position=[0, 0, 1, 1]);
    G = res.plot_diagram(Parent=ax, ColorMode="none", LabelMode="none", TitleFormat="", ...
        BranchWidthMode="none", BranchWidthRange=[11 11], FlowMode="P", FlowSpeed=1, ...
        FlowAnimation=false);
    iv_letter = [c_branch{:, 3}];
    for j = 1:6
        G.set_style(string(c_bus([c_bus{:, 4}] == j, 1)), Color=rm_color(j, :), MarkerSize=11);
        G.set_style(G.tab_element.Tag(G.tab_element.Kind == "branch" & ismember(G.tab_element.Index, find(iv_letter == j))), ...
            Color=rm_color(j, :));
    end
    G.set_style(G.tab_element.Tag(G.tab_element.Kind == "branch" & ismember(G.tab_element.Index, find(iv_letter == 0))), ...
        Color=[1 1 1], LineWidth=0.5);
    axis(ax, "off");
    r_pad = 0.25;                             % frame of 3:1 around the letters (x 0..16.1, y 0..5)
    r_w = 16.1 + 2*r_pad;
    r_h = r_w*opt.Size(2)/opt.Size(1);
    xlim(ax, [-r_pad, 16.1 + r_pad]);
    ylim(ax, 2.5 + [-0.5, 0.5]*r_h);

    %% Frames: one loop of 4*FlowSpeed*T = 6
    r_T = 6/(4*G.FlowSpeed);
    n   = opt.Frames;
    c_frame = cell(n, 1);
    for i = 1:n
        G.step_flow(r_T/n * (i > 1));
        drawnow;
        rgb = frame2im(getframe(fig));
        if ~isequal(size(rgb, [1 2]), opt.Size([2 1]))
            rgb = imresize(rgb, opt.Size([2 1]));
        end
        c_frame{i} = rgb;
    end
    close(fig);

    imwrite(c_frame{1}, fullfile(s_out, "guilda-network.png"));
    [~, cmap] = rgb2ind(cat(1, c_frame{:}), 64, "nodither");
    [~, i_white] = min(sum((1 - cmap).^2, 2));
    cmap(i_white, :) = 1;                      % the background stays pure white
    s_gif = fullfile(s_out, "guilda-network.gif");
    for i = 1:n
        X = rgb2ind(c_frame{i}, cmap, "nodither");
        if i == 1
            imwrite(X, cmap, s_gif, "gif", LoopCount=Inf, DelayTime=opt.Delay);
        else
            imwrite(X, cmap, s_gif, "gif", WriteMode="append", DelayTime=opt.Delay);
        end
    end
    fprintf("%s (%d frames, %.0f kB)\n%s\n", s_gif, n, dir(s_gif).bytes/1024, fullfile(s_out, "guilda-network.png"));
end
