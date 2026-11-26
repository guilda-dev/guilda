function make_about_analysis(opt)
% Make the videos of the carousel of analysis features in the About tab of the docs site.
%
% Each item is an analysis done with GUILDA and drawn by its plot_* methods (GraphBase); the
% script runs the analysis, drives the graphs (clicks, set_time, links) and records the
% figure. Items (file names in OutDir):
%
%   01-contribution.mp4       ResultLIN.plot_contribution of IEEE 68-bus with its AVRs and
%                             PSSs: modes clicked on the eigenvalue map, the diagram colored by
%                             the share of each element in the damping, then a bus clicked
%   02-controller-pss.mp4     IEEE 68-bus with AVRs only, then a PSS added to one generator
%                             after another (add_local_controller): the eigenvalues of get_sys
%                             and the omega of a fault simulation of the same network
%   03-stability-opf.mp4      IEEE 14-bus: the outer iterations of the stability-constrained
%                             OPF (MinDampingRatio), linearized at each solution: eigenvalue
%                             map with the damping-ratio limit, beside plot_dispatch
%   04-cpf-eigenvalue.mp4     IEEE 14-bus: the continuation power flow linearized at each step
%                             (get_sys({cpf, steps})): eigenvalue map, PV curves and
%                             plot_eigenvalue_path, linked, up to the nose
%
% Each video has a poster PNG of the same name. The frames are recorded with getframe (a drawn
% mouse pointer and click rings show the clicks) and encoded by ffmpeg (H.264, yuv420p,
% faststart, 1280 x 640, 20 fps, under 3 MB).
%
% Run with R2026a and ffmpeg installed (matlab -batch works):
%   addpath("notes/about-anim"); make_about_analysis(OutDir="/tmp/analysis");
%   make_about_analysis(Item="opf", OutDir="/tmp/analysis");   % one item only
    arguments (Input)
        opt.OutDir (1,1) string = ""     % Output folder; "" for _GUILDAdocPages/images/about/analysis.
        opt.Item (1,:) string {mustBeMember(opt.Item, ["contribution", "controller", "opf", "cpf"])} ...
            = ["contribution", "controller", "opf", "cpf"]  % Items to make.
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
        switch s_item
            case "contribution"
                make_contribution(fullfile(s_out, "01-contribution"));
            case "controller"
                make_controller(fullfile(s_out, "02-controller-pss"));
            case "opf"
                make_stability_opf(fullfile(s_out, "03-stability-opf"));
            case "cpf"
                make_cpf_eigenvalue(fullfile(s_out, "04-cpf-eigenvalue"));
        end
        close all
    end
end


%% Items

function make_contribution(s_base)
% Interactive: plot_contribution of IEEE 68-bus with its AVRs and PSSs. The least damped
% inter-area mode (0.25 to 0.8 Hz) is clicked, then the least damped local mode (1 to 2 Hz),
% then the inter-area mode again; the diagram shows Re(lambda_e) of each element (with its
% controllers); then bus B016 is clicked and the table lists the elements there.
    net = network.IEEE68bus(LocalController=true);
    res = net.get_sys();
    fig = figure(Color="w", Position=[100 100 1120 560]);
    sct = res.plot_contribution(Parent=fig);
    no_toolbar(fig);
    G_eig = sct.Eigenvalue;
    G = sct.Diagram;
    cv_mode = G_eig.sct_plt.Element;
    cv_lambda = vertcat_points(cv_mode);
    rv_f = imag(cv_lambda)/(2*pi);
    rv_z = -real(cv_lambda)./abs(cv_lambda);
    f_least = @(lv) cv_lambda(find(lv & rv_z == min(rv_z(lv)), 1));
    c_inter = f_least(rv_f > 0.25 & rv_f < 0.8);               % the least damped inter-area mode
    c_local = f_least(rv_f > 1 & rv_f < 2);                    % the least damped local mode
    fprintf("modes: %s (%.3f Hz), %s (%.3f Hz)\n", num2str(c_inter), imag(c_inter)/2/pi, num2str(c_local), imag(c_local)/2/pi);
    G_eig.ax(1).XLim = [-3 0.5];                               % zoom to the electromechanical modes
    G_eig.ax(1).YLim = [-1 13];
    f_eig = @(c) data_to_figure(G_eig.ax(1), real(c), imag(c));
    rec = make_recorder(fig);

    rec.cursor(f_eig(c_inter) + [60, 80]);
    rec.hold(14);
    rec.move(f_eig(c_inter), 16);
    rec.click(@() click_eigenvalue(G_eig, c_inter));
    rec.hold(12);
    rec.poster();
    rec.hold(40);
    rec.move(f_eig(c_local), 18);
    rec.click(@() click_eigenvalue(G_eig, c_local));
    rec.hold(44);
    rec.move(f_eig(c_inter), 18);
    rec.click(@() click_eigenvalue(G_eig, c_inter));
    rec.hold(16);
    rec.move(bus_point(G, "B016"), 18);
    rec.click(@() click_bus(G, "B016"));
    rec.hold(50);
    rec.finish(s_base);
end


function make_controller(s_base)
% Animation: IEEE 68-bus with the AVRs (avr-ST1) of LocalController=true and no PSS; a PSS
% (pss-PSS1, the parameters of the network) is added to one generator after another. After
% each addition the network is initialized, linearized (get_sys) and simulated (a fault at
% bus B001 from 1 s to 1.05 s); the eigenvalue map and the omega of the generators follow.
    net = network.IEEE68bus(LocalController=true);
    a_gen = cell(1, 16);
    for i = 1:16
        a_gen{i} = net.a_Bus{i}.a_Component{1};
        a_gen{i}.remove_local_controller(a_gen{i}.pss.s_tag);
    end
    sct_prm = struct(kpss=25, tWS=10, tn1=0.07, td1=0.02, tn2=0.07, td2=0.02);
    sc = net.add_scenario("fault", Time=[0, 15]);
    sc.add_fault("B001", [1, 1.05]);
    c_lin = cell(1, 17);
    c_sim = cell(1, 17);
    for k = 0:16
        if k > 0
            a_gen{k}.add_local_controller("pss-PSS1", parameter=sct_prm);
        end
        net.initialize();
        c_lin{k+1} = net.get_sys(Type="ODE");
        c_sim{k+1} = net.simulate("fault", Progress="none");
        fprintf("PSS %d: max Re %.4f\n", k, max(real(stable_part(c_lin{k+1}))));
    end
    cv_ghost = stable_part(c_lin{1});

    fig = figure(Color="w", Position=[100 100 1120 560]);
    h_left = uipanel(fig, Units="normalized", Position=[0 0.09 0.46 0.91], BorderType="none", BackgroundColor="w");
    h_right = uipanel(fig, Units="normalized", Position=[0.46 0.09 0.54 0.91], BorderType="none", BackgroundColor="w");
    ax_cmd = axes(fig, Units="normalized", Position=[0 0 1 0.09], Visible="off", XLim=[0 1], YLim=[0 1]);
    h_cmd = text(ax_cmd, 0.015, 0.5, "", FontName="Menlo", FontSize=12, Interpreter="none", Color=[0.15 0.15 0.15]);
    rec = make_recorder(fig);

    for k = 0:16
        draw_stage(k);
        if k == 0
            h_cmd.String = ">> % AVR (avr-ST1) on every generator, no PSS: get_sys and simulate";
            rec.hold(40);
            type_command(rec, h_cmd, ">> gen.add_local_controller(""pss-PSS1"", parameter=prm);  net.initialize();");
            rec.hold(6);
        else
            h_cmd.String = sprintf(">> net.a_Bus{%d}.a_Component{1}.add_local_controller(""pss-PSS1"", parameter=prm);", k);
            rec.hold(9);
        end
        if k == 16
            rec.poster();
            rec.hold(50);
        end
    end
    rec.finish(s_base);

    function draw_stage(k)
        delete(h_left.Children);
        delete(h_right.Children);
        G_eig = c_lin{k+1}.plot_eigenvalue(Parent=h_left);
        ax = G_eig.ax(1);
        hold(ax, "on");
        h_g = plot(ax, real(cv_ghost), imag(cv_ghost), "o", MarkerSize=4, Color=[0.72 0.72 0.72]);
        uistack(h_g, "bottom");
        hold(ax, "off");
        ax.XLim = [-3.6 1];
        ax.YLim = [0 13];
        ax.Subtitle.String = "";
        ax.Title.String = sprintf("Eigenvalues: PSS on %d of 16 generators", k);
        text(ax, -3.5, 12.2, "gray: AVRs only", FontSize=10, Color=[0.45 0.45 0.45]);
        G_w = c_sim{k+1}.plot_trajectory(Quantity="omega", Parent=h_right);
        legend(G_w.ax(1), "off");
        G_w.ax(1).YLim = [-0.016 0.016];
        G_w.ax(1).Title.String = "omega after a fault at B001 (1 s to 1.05 s)";
        no_toolbar(fig);
    end
end


function make_stability_opf(s_base)
% Animation: the stability-constrained OPF of IEEE 14-bus (MinDampingRatio 0.048). The
% solution of each outer iteration k is the result with StabilityMaxIteration = k; the
% network is linearized at each (one section per solution). The eigenvalue map (zoomed to
% the electromechanical modes, with the line of the damping ratio 0.048) steps through the
% sections beside plot_dispatch of each solution.
    r_zeta = 0.048;
    net = network.IEEE14bus();
    net.initialize();
    [res, flag] = net.calculate_optimal_powerflow(Method="AC OPF", MinDampingRatio=r_zeta, Progress="none");
    tab_it = res.sct_stability.tab_iteration;
    n_it = height(tab_it);
    fprintf("stability OPF flag %d, %d outer iterations\n", flag, n_it);
    disp(tab_it)
    % The solution of outer iteration k is the result with StabilityMaxIteration = k (flag 0
    % before the last). Its point is built as the stability-constrained OPF builds it: the P
    % of the generators and the V of their buses as power flow set points, then the power
    % flow and the equilibria (net.initialize); the damping ratios are checked against
    % tab_iteration below.
    c_res = cell(1, n_it);
    sct_w = warning("off", "all");
    for k = 1:n_it
        c_res{k} = net.calculate_optimal_powerflow(Method="AC OPF", MinDampingRatio=r_zeta, ...
            StabilityMaxIteration=k, Progress="none");
    end
    warning(sct_w);
    net = network.IEEE14bus();           % a network of its own for the set points
    rm_point = [];
    for k = 1:n_it
        res_k = c_res{k};
        for i = 1:numel(net.a_Bus)
            bus = net.a_Bus{i};
            for j = 1:numel(bus.a_Component)
                comp = bus.a_Component{j};
                if isa(comp, "component.generator.abstract")
                    comp.tab_parameter.powerflow.P = res_k.tab_cub{comp.s_tag, "P"};
                    bus.tab_parameter.powerflow.V = res_k.tab_bus{bus.s_tag, "V"};
                end
            end
        end
        net.initialize();
        lin = net.get_sys(Type="ODE");
        rm_point = [rm_point, lin.rv_point]; %#ok<AGROW>
    end
    lin = net.get_sys(rm_point, Type="ODE");
    for k = 1:n_it
        lin.Index = k;
        fprintf("section %d: min zeta %.4f (OPF %.4f)\n", k, min_zeta(lin), tab_it.MinDampingRatio(k));
    end

    fig = figure(Color="w", Position=[100 100 1120 560]);
    h_left = uipanel(fig, Units="normalized", Position=[0 0.07 0.46 0.93], BorderType="none", BackgroundColor="w");
    h_right = uipanel(fig, Units="normalized", Position=[0.46 0 0.54 1], BorderType="none", BackgroundColor="w");
    G_eig = lin.plot_eigenvalue(Parent=h_left, Index=1);
    hide_bar(fig);
    ax = G_eig.ax(1);
    rv_xl = [-0.65 0.02];
    rv_yl = [5.5 10.5];
    hold(ax, "on");
    r_im = rv_yl(2);
    plot(ax, [0, -r_zeta/sqrt(1 - r_zeta^2)*r_im], [0, r_im], "--", Color=[0.85 0.33 0.1], LineWidth=1.3);
    text(ax, -0.47, 10.25, "\zeta = 0.048", Color=[0.85 0.33 0.1], FontSize=12, HorizontalAlignment="left");
    lin.Index = 1;
    e = stable_part(lin);
    h_ghost = plot(ax, real(e), imag(e), "o", MarkerSize=6, Color=[0.6 0.6 0.6]);
    uistack(h_ghost, "bottom");
    text(ax, -0.63, 5.75, "gray: iteration 1 (the OPF without the limit)", FontSize=10, Color=[0.45 0.45 0.45]);
    hold(ax, "off");
    h_info = annotation(fig, "textbox", [0.01 0.0 0.45 0.07], String="", EdgeColor="none", ...
        FontSize=12, Color=[0.15 0.15 0.15], VerticalAlignment="middle", HorizontalAlignment="center");
    rec = make_recorder(fig);
    for k = 1:n_it
        G_eig.set_time(k);
        ax.XLim = rv_xl;
        ax.YLim = rv_yl;
        ax.Title.String = sprintf("Eigenvalues at the solution of outer iteration %d", k);
        ax.Subtitle.String = "";
        delete(h_right.Children);
        c_res{k}.plot_dispatch(Parent=h_right);
        % an outer iteration before the last has flag 0 (the limit not met yet), for which
        % plot_dispatch writes "not solved"; its OPF was solved (tab_iteration.Flag 1)
        a_h = findall(h_right, "-property", "String");
        for h_t = reshape(findall(h_right, "-property", "Title"), 1, [])
            if isgraphics(h_t.Title)
                a_h(end+1) = h_t.Title; %#ok<AGROW>
            end
        end
        for h = reshape(a_h, 1, [])
            if contains(strjoin(string(h.String)), "not solved")
                h.String = sprintf("Dispatch at outer iteration %d, cost = %.1f", k, tab_it.Cost(k));
            end
        end
        no_toolbar(fig);
        h_info.String = sprintf("Iteration %d:  cost %.1f,  smallest damping ratio %.4f", ...
            k, tab_it.Cost(k), tab_it.MinDampingRatio(k));
        rec.hold(46);
        if k == n_it
            rec.poster();
            rec.hold(34);
        end
    end
    rec.finish(s_base);
end


function make_cpf_eigenvalue(s_base)
% Animation: the continuation power flow of IEEE 14-bus (loads at B009 and B014 increased),
% linearized at every step up to the nose (get_sys({cpf, steps})): the eigenvalue map, the PV
% curves and plot_eigenvalue_path, linked, stepped up to the nose.
    net = network.IEEE14bus();
    net.initialize();
    cpf = net.calculate_continuation_powerflow(LoadBus=["B009", "B014"]);
    iv_step = 1:cpf.r_noseStep;
    lin = net.get_sys({cpf, iv_step}, Type="ODE");

    fig = figure(Color="w", Position=[100 100 1120 560]);
    h_left = uipanel(fig, Units="normalized", Position=[0 0 0.46 1], BorderType="none", BackgroundColor="w");
    h_rt = uipanel(fig, Units="normalized", Position=[0.46 0.5 0.54 0.5], BorderType="none", BackgroundColor="w");
    h_rb = uipanel(fig, Units="normalized", Position=[0.46 0 0.54 0.5], BorderType="none", BackgroundColor="w");
    G_eig = lin.plot_eigenvalue(Parent=h_left);
    G_pv = cpf.plot_pvcurve(Parent=h_rt);
    G_path = lin.plot_eigenvalue_path(Parent=h_rb);
    G_eig.link(G_pv);
    G_eig.link(G_path);
    hide_bar(fig);
    ax = G_eig.ax(1);
    G_path.ax(1).YLim = [-0.4 1.5];
    % The sections are the steps: the x labels say so (plot_eigenvalue_path writes "t [s]"
    % for finite nondecreasing rv_t), and the marker of the first unstable section is
    % labelled with its step and lambda.
    rv_maxRe = zeros(1, numel(iv_step));
    for k = 1:numel(iv_step)
        lin.Index = k;
        rv_maxRe(k) = max(real(stable_part(lin)));
    end
    k_cross = find(rv_maxRe > 1e-6, 1);
    fprintf("first unstable step %d, lambda %.3f; nose step %d, lambda %.3f\n", k_cross, ...
        cpf.rv_lambda(k_cross), cpf.r_noseStep, cpf.r_lambdaMax);
    for i = 1:numel(G_path.ax)
        G_path.ax(i).XLabel.String = "Step of the continuation power flow";
        G_path.ax(i).XLim = [0 numel(iv_step) + 1];
        for h = reshape(findall(G_path.ax(i), "Type", "constantline", "InterceptAxis", "x"), 1, [])
            if strlength(string(h.Label)) > 0
                h.Label = sprintf("step %d (\\lambda = %.2f)", k_cross, cpf.rv_lambda(k_cross));
                h.LabelOrientation = "horizontal";
                h.LabelHorizontalAlignment = "left";
            end
        end
    end
    rec = make_recorder(fig);
    iv_show = unique([1:2:90, 91:130, 131:2:numel(iv_step), numel(iv_step)]);
    for k = iv_show
        G_eig.set_time(k);
        ax.XLim = [-1.2 1.2];
        ax.YLim = [-1 13];
        ax.Title.String = sprintf("Eigenvalues at step %d (\\lambda = %.2f)", k, cpf.rv_lambda(k));
        ax.Subtitle.String = "red: Re \lambda > 0";
        rec.shot();
        if k == 1
            rec.hold(10);
        end
        if k == k_cross
            rec.hold(20);
        end
        if k == 121
            rec.poster();
        end
    end
    rec.hold(30);
    rec.finish(s_base);
end


%% Helpers of the items

function e = stable_part(lin)
% Finite eigenvalues of (A, E) of the section shown, without the zero eigenvalue of the common angle.
    e = eig(lin.A, lin.E);
    e = e(isfinite(e) & abs(e) > 1e-5);
end


function z = min_zeta(lin)
% Smallest damping ratio of the oscillatory modes of the section shown.
    e = stable_part(lin);
    e = e(abs(imag(e)) > 1e-6);
    z = min(-real(e)./abs(e));
end


function cv = vertcat_points(a_h)
% Complex points of the marker sets a_h of an eigenvalue map.
    cv = [];
    for h = reshape(a_h, 1, [])
        cv = [cv; reshape(complex(h.XData, h.YData), [], 1)]; %#ok<AGROW>
    end
    cv = cv(isfinite(cv));
end


function no_toolbar(fig)
% Hide the axes toolbars.
    for ax = findall(fig, "Type", "axes")'
        ax.Toolbar.Visible = "off";
    end
end


function hide_bar(fig)
% Hide the playback bars (the axes take their strip) and the axes toolbars.
    h_bar = findall(fig, "Tag", "GUILDA:GraphBase:PlaybackBar");
    set(h_bar, "Visible", "off");
    drawnow;
    no_toolbar(fig);
end


function rv_xy = bus_point(G, s_tag)
% [px] Point of the figure on the bar of the bus s_tag of a 2D diagram (a little right of its center).
    tab = G.tab_element;
    i_bus = tab.Index(tab.Tag == s_tag & tab.Kind == "bus");
    h = findobj(G.ax(1), "-function", @(h) isprop(h, "UserData") && isstruct(h.UserData) ...
        && isfield(h.UserData, "Type") && h.UserData.Type == "Bus" && h.UserData.Index == i_bus);
    h = h(1);
    x = mean(h.XData(isfinite(h.XData)));
    y = mean(h.YData(isfinite(h.YData)));
    rv_xy = data_to_figure(G.ax(1), x + 0.25*(max(h.XData) - x), y);
end


function click_bus(G, s_tag)
% Click the bus s_tag of a diagram: its ButtonDownFcn, as a mouse click calls it.
    tab = G.tab_element;
    i_bus = tab.Index(tab.Tag == s_tag & tab.Kind == "bus");
    h = findobj(G.ax(1), "-function", @(h) isprop(h, "UserData") && isstruct(h.UserData) ...
        && isfield(h.UserData, "Type") && h.UserData.Type == "Bus" && h.UserData.Index == i_bus);
    h(1).ButtonDownFcn(h(1), []);
end


function click_eigenvalue(G_eig, c)
% Click the eigenvalue c on the eigenvalue map: the CurrentPoint of the figure at it and the
% ButtonDownFcn of the marker set that holds it, as a mouse click calls it.
    ax = G_eig.ax(1);
    fig = ancestor(ax, "figure");
    fig.CurrentPoint = data_to_figure(ax, real(c), imag(c));
    a_h = G_eig.sct_plt.Element;
    rv_d = arrayfun(@(h) min([abs(complex(h.XData, h.YData) - c), Inf]), a_h);
    [~, k] = min(rv_d);
    a_h(k).ButtonDownFcn(a_h(k), []);
end


function rv_xy = data_to_figure(ax, x, y)
% [px] Point of the figure (from the bottom left) of the data point (x, y) of a 2D axes.
    pos = getpixelposition(ax, true);
    rv_xl = ax.XLim;
    rv_yl = ax.YLim;
    if ax.DataAspectRatioMode == "manual" || ax.PlotBoxAspectRatioMode == "manual"
        rv_dar = ax.DataAspectRatio;
        r_dx = diff(rv_xl)/rv_dar(1);
        r_dy = diff(rv_yl)/rv_dar(2);
        r_k = min(pos(3)/r_dx, pos(4)/r_dy);
        r_w = r_dx*r_k;
        r_h = r_dy*r_k;
        r_x0 = pos(1) + (pos(3) - r_w)/2;
        r_y0 = pos(2) + (pos(4) - r_h)/2;
    else
        r_w = pos(3);  r_h = pos(4);  r_x0 = pos(1);  r_y0 = pos(2);
    end
    rv_xy = [r_x0 + (x - rv_xl(1))/diff(rv_xl)*r_w, r_y0 + (y - rv_yl(1))/diff(rv_yl)*r_h];
end


function type_command(rec, h_cmd, s_cmd)
% Type s_cmd into the command strip, a few characters per frame.
    n = strlength(s_cmd);
    for k = 3:3:n + 2
        h_cmd.String = extractBefore(s_cmd, min(k, n) + 1) + "_";
        rec.shot();
    end
    h_cmd.String = s_cmd;
    rec.shot();
end


%% Output

function rec = make_recorder(fig)
% Frame recorder of a figure: shots with getframe, a drawn mouse pointer and click rings,
% and the encoding to MP4 and the poster PNG (as in make_about_carousel).
%
% rec.shot()             one frame
% rec.hold(n)            n frames
% rec.cursor(xy)         pointer at xy [px of the figure, from the bottom left]; [] none
% rec.move(xy, n)        move the pointer to xy in n frames
% rec.click(f)           a click ring at the pointer, then f() ([] for none)
% rec.poster()           the next frame is the poster (default: the last frame)
% rec.finish(s_base)     write s_base.mp4 and s_base.png
    r_fps = 20;
    s_dir = string(tempname);
    mkdir(s_dir);
    n_out = 0;
    i_poster = 0;
    rv_cur = [];
    rm_ripple = zeros(0, 3);       % x, y [px of the image], age [frames]
    iv_size = [];
    r_scale = NaN;
    n_ripple = 10;

    rec.r_fps = r_fps;
    rec.shot = @shot;
    rec.hold = @hold_frames;
    rec.cursor = @set_cursor;
    rec.move = @move;
    rec.click = @click;
    rec.poster = @mark_poster;
    rec.finish = @finish;

    function set_cursor(xy)
        rv_cur = xy;
    end

    function mark_poster()
        i_poster = n_out + 1;
    end

    function shot()
        drawnow;
        pause(0.02);            % getframe in matlab -batch otherwise returns the frame before
        drawnow;
        m_img = frame2im(getframe(fig));
        if isempty(iv_size)
            iv_size = 2*floor([size(m_img, 1), size(m_img, 2)]/2);
            r_scale = size(m_img, 2)/fig.Position(3);
        end
        m_out = 255*ones(iv_size(1), iv_size(2), 3, "uint8");
        n_h = min(iv_size(1), size(m_img, 1));
        n_w = min(iv_size(2), size(m_img, 2));
        m_out(1:n_h, 1:n_w, :) = m_img(1:n_h, 1:n_w, :);
        for i = 1:size(rm_ripple, 1)
            m_out = draw_ring(m_out, rm_ripple(i, 1:2), rm_ripple(i, 3)/n_ripple, r_scale);
        end
        rm_ripple(:, 3) = rm_ripple(:, 3) + 1;
        rm_ripple(rm_ripple(:, 3) > n_ripple, :) = [];
        if ~isempty(rv_cur)
            m_out = draw_pointer(m_out, to_image(rv_cur), r_scale);
        end
        n_out = n_out + 1;
        imwrite(m_out, fullfile(s_dir, sprintf("f%05d.png", n_out)));
    end

    function rv = to_image(xy)
        rv = [xy(1)*r_scale, (fig.Position(4) - xy(2))*r_scale];
    end

    function hold_frames(n)
        for i = 1:n
            shot();
        end
    end

    function move(xy, n)
        rv_0 = rv_cur;
        if isempty(rv_0)
            rv_0 = xy;
        end
        for i = 1:n
            r_u = (1 - cos(pi*i/n))/2;
            rv_cur = rv_0 + (xy - rv_0)*r_u;
            shot();
        end
    end

    function click(f)
        if isnan(r_scale)
            shot();             % the scale of the image comes with the first frame
        end
        rm_ripple(end+1, :) = [to_image(rv_cur), 0];
        if ~isempty(f)
            f();
        end
    end

    function finish(s_base)
        if i_poster == 0 || i_poster > n_out
            i_poster = n_out;
        end
        s_in = fullfile(s_dir, "f%05d.png");
        s_scale = "scale=1280:640:flags=lanczos";
        for r_crf = [23, 26, 29, 32]
            run_ffmpeg(sprintf(['-framerate %d -i "%s" -vf %s -c:v libx264 -preset slow ' ...
                '-crf %d -pix_fmt yuv420p -movflags +faststart "%s"'], r_fps, s_in, s_scale, r_crf, s_base + ".mp4"));
            sct = dir(s_base + ".mp4");
            if sct.bytes < 3.0e6
                break
            end
        end
        run_ffmpeg(sprintf('-i "%s" -vf %s "%s"', fullfile(s_dir, sprintf("f%05d.png", i_poster)), s_scale, s_base + ".png"));
        fprintf("%s.mp4: %d frames (%.1f s), %.2f MB, crf %d\n", s_base, n_out, n_out/r_fps, sct.bytes/1e6, r_crf);
        rmdir(s_dir, "s");
    end
end


function m = draw_pointer(m, rv_xy, r_s)
% Draw a mouse pointer (black with a white edge) with its tip at rv_xy [px of the image].
    rm_p = [0 0; 0 17; 4.2 13.3; 7 19.6; 9.6 18.5; 6.9 12.3; 12 12.1] * 1.15 * r_s + rv_xy;
    r_edge = 1.3*r_s;
    iv_x = max(1, floor(min(rm_p(:, 1)) - r_edge)):min(size(m, 2), ceil(max(rm_p(:, 1)) + r_edge));
    iv_y = max(1, floor(min(rm_p(:, 2)) - r_edge)):min(size(m, 1), ceil(max(rm_p(:, 2)) + r_edge));
    [X, Y] = meshgrid(iv_x, iv_y);
    l_in = inpolygon(X, Y, rm_p(:, 1), rm_p(:, 2));
    r_d = inf(size(X));
    rm_q = [rm_p; rm_p(1, :)];
    for k = 1:size(rm_p, 1)
        rv_a = rm_q(k, :);
        rv_b = rm_q(k+1, :) - rv_a;
        r_t = min(max(((X - rv_a(1))*rv_b(1) + (Y - rv_a(2))*rv_b(2)) / sum(rv_b.^2), 0), 1);
        r_d = min(r_d, hypot(X - rv_a(1) - r_t*rv_b(1), Y - rv_a(2) - r_t*rv_b(2)));
    end
    r_white = min(max(r_edge + 0.5 - r_d, 0), 1);       % anti-aliased edge
    r_white(l_in) = 1;
    r_black = l_in .* min(max(r_d - 0.8*r_edge, 0), 1);
    for c = 1:3
        P = double(m(iv_y, iv_x, c));
        P = P.*(1 - r_white) + 255*r_white;
        P = P.*(1 - r_black);
        m(iv_y, iv_x, c) = uint8(P);
    end
end


function m = draw_ring(m, rv_xy, r_age, r_s)
% Draw a click ring at rv_xy [px of the image]: it grows and fades with r_age (0 to 1).
    r_rad = (5 + 16*r_age)*r_s;
    r_w = 2.2*r_s;
    r_a = 0.85*(1 - r_age);
    rv_col = [17 113 190];          % #1171BE
    iv_x = max(1, floor(rv_xy(1) - r_rad - r_w)):min(size(m, 2), ceil(rv_xy(1) + r_rad + r_w));
    iv_y = max(1, floor(rv_xy(2) - r_rad - r_w)):min(size(m, 1), ceil(rv_xy(2) + r_rad + r_w));
    [X, Y] = meshgrid(iv_x, iv_y);
    r_d = abs(hypot(X - rv_xy(1), Y - rv_xy(2)) - r_rad);
    A = r_a*min(max(r_w/2 + 0.5 - r_d, 0), 1);
    for c = 1:3
        P = double(m(iv_y, iv_x, c));
        m(iv_y, iv_x, c) = uint8(P.*(1 - A) + rv_col(c)*A);
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
