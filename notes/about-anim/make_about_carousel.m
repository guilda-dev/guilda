function make_about_carousel(opt)
% Make the media of the carousel "GUILDA の出力例" in the About tab of the docs site.
%
% Every item is drawn by a plot_* method of GUILDA and its graph object (GraphBase); the
% script only drives the graphs (set_time, the playback bar, clicks, the control panel)
% and records the figure. Items (file names in OutDir):
%
%   01-opf-lmp.png               (still) ResultOPF.plot_lmp: LMP of IEEE 14-bus with a
%                                congested branch (AC OPF)
%   02-single-line-diagram.png   (still) ResultPF.plot_single_line_diagram of IEEE 14-bus
%   03-fault-diagram.mp4         (animation) ResultODE.plot_diagram: a fault at bus B008
%                                of IEEE 14-bus; flows, currents and the |V| chart
%   04-spring-model-3d.mp4       (animation) ResultODE.plot_spring_model(Dimension=3):
%                                IEEE 9-bus after a fault at bus B007, with the omega chart
%   05-cpf-steps.mp4             (animation) ResultCPF.plot_diagram: the steps of the
%                                continuation power flow of IEEE 14-bus with the PV curves
%   06-explore-click.mp4         (interactive) the playback bar is dragged and buses are
%                                clicked: ElementClickedFcn selects the bus in the diagram
%                                and its line in the |V| chart
%   07-control-panel.mp4         (interactive) G.show_controls(): settings changed in the
%                                panel and by commands, the panel and drawing follow
%   08-eigen-participation.mp4   (interactive) ResultLIN.plot_participation of IEEE 68-bus:
%                                eigenvalues clicked on the map (an inter-area mode, a local
%                                mode, another inter-area mode), then a bus for its table
%   09-app-gui.mp4               (interactive) GUILDA.launch_gui on IEEE 14-bus: a load
%                                clicked and its P edited in the model GUI, the power flow
%                                run, and Analyze result opens the result window
%
% Each video has a poster PNG of the same name. The videos are recorded frame by frame with
% getframe (the playback bar and the control panel are in the frames of the interactive
% items; a drawn mouse pointer and click rings show the actions) and encoded by ffmpeg
% (H.264, yuv420p, faststart, width 1280 px or less, under 4 MB).
%
% Run with R2026a and ffmpeg installed (matlab -batch works):
%   addpath("notes/about-anim"); make_about_carousel();
%   make_about_carousel(Item="cpf", OutDir="/tmp/carousel");   % one item only
    arguments (Input)
        opt.OutDir (1,1) string = ""     % Output folder; "" for _GUILDAdocPages/images/about/carousel.
        opt.Item (1,:) string {mustBeMember(opt.Item, ["lmp", "single-line", "fault-diagram", "spring-3d", "cpf", "explore", "controls", "participation", "gui"])} ...
            = ["lmp", "single-line", "fault-diagram", "spring-3d", "cpf", "explore", "controls", "participation", "gui"]  % Items to make.
    end
    s_out = opt.OutDir;
    if s_out == ""
        s_root = fileparts(fileparts(fileparts(mfilename("fullpath"))));   % notes/about-anim -> notes -> root
        s_out = fullfile(s_root, "_GUILDAdocPages", "images", "about", "carousel");
    end
    if ~isfolder(s_out)
        mkdir(s_out);
    end
    sct_warn = warning("off", "MATLAB:print:ContentTypeImageSuggested");
    c_warn = onCleanup(@() warning(sct_warn));
    for s_item = opt.Item
        fprintf("== %s\n", s_item);
        switch s_item
            case "lmp"
                make_lmp(fullfile(s_out, "01-opf-lmp"));
            case "single-line"
                make_single_line(fullfile(s_out, "02-single-line-diagram"));
            case "fault-diagram"
                make_fault_diagram(fullfile(s_out, "03-fault-diagram"));
            case "spring-3d"
                make_spring_3d(fullfile(s_out, "04-spring-model-3d"));
            case "cpf"
                make_cpf(fullfile(s_out, "05-cpf-steps"));
            case "explore"
                make_explore(fullfile(s_out, "06-explore-click"));
            case "controls"
                make_controls(fullfile(s_out, "07-control-panel"));
            case "participation"
                make_participation(fullfile(s_out, "08-eigen-participation"));
            case "gui"
                make_gui(fullfile(s_out, "09-app-gui"));
        end
        close all
    end
end


%% Items

function make_lmp(s_base)
% Still: the LMP of an AC OPF of IEEE 14-bus with a limit of 1 pu on the first branch.
    net = network.IEEE14bus();
    net.a_Branch{1}.tab_parameter.operation.Pmax = 1;
    res = net.calculate_optimal_powerflow(Method="AC OPF");
    fig = figure(Color="w", Position=[100 100 820 600]);
    res.plot_lmp(LabelMode="bus", LabelFontSize=9, Parent=fig);
    write_still(fig, s_base);
end


function make_single_line(s_base)
% Still: the black-and-white single-line diagram of IEEE 14-bus for a paper.
    res = network.IEEE14bus().calculate_powerflow();
    G = res.plot_single_line_diagram();
    write_still(G.ax, s_base, 300);
end


function make_fault_diagram(s_base)
% Animation: a three-phase fault at bus B008 from 1 s to 1.05 s, IEEE 14-bus, 5 s. The
% fault is shown in slow motion (5 ms of the result per frame), the rest at real time.
    net = network.IEEE14bus();
    sc = net.add_scenario("fault", Time=[0, 5]);
    sc.add_fault("B008", [1, 1.05]);
    res = net.simulate("fault", Progress="none");
    fig = figure(Color="w", Position=[100 100 1120 560]);
    G = res.plot_diagram(LabelFontSize=8, Parent=fig);
    hide_bar(fig);
    rec = make_recorder(fig);
    rec.set_tick(@() G.step_flow(1/rec.r_fps));
    rv_t = [0.5:0.05:0.95, 0.96:0.005:1.15, 1.2:0.05:5];
    for t = rv_t
        G.set_time(t);
        rec.shot();
        if abs(t - 1.02) < 1e-6
            rec.poster();
        end
    end
    rec.hold(20);
    rec.finish(s_base);
end


function make_spring_3d(s_base)
% Animation: the spring-mass picture on the surface z = log|V| of IEEE 9-bus after a fault
% at bus B007 (1 s to 1.05 s), real time, with the omega chart.
    net = network.IEEE9bus();
    sc = net.add_scenario("fault", Time=[0, 5]);
    sc.add_fault("B007", [1, 1.05]);
    res = net.simulate("fault", Progress="none");
    fig = figure(Color="w", Position=[100 100 1120 560]);
    G = res.plot_spring_model(Dimension=3, Parent=fig);
    hide_bar(fig);
    camzoom(G.ax(1), 1.3);          % the picture fills its panel (a MATLAB camera setting)
    rec = make_recorder(fig);
    for t = 0.5:0.05:5
        G.set_time(t);
        rec.shot();
        if abs(t - 1.5) < 1e-6
            rec.poster();
        end
    end
    rec.hold(20);
    rec.finish(s_base);
end


function make_cpf(s_base)
% Animation: the steps of the continuation power flow of IEEE 14-bus (loads at B009 and
% B014 increased), past the nose and down the lower branch, with the PV curves.
    net = network.IEEE14bus();
    net.initialize();
    res = net.calculate_continuation_powerflow(LoadBus=["B009", "B014"]);
    fig = figure(Color="w", Position=[100 100 1120 560]);
    G = res.plot_diagram(LabelFontSize=8, Parent=fig);
    hide_bar(fig);
    rec = make_recorder(fig);
    rec.set_tick(@() G.step_flow(1/rec.r_fps));
    n_step = numel(G.rv_t);
    iv_step = unique([1:3:n_step, n_step]);
    [~, i_nose] = min(abs(iv_step - res.r_noseStep));
    iv_step(i_nose) = res.r_noseStep;
    for k = iv_step
        G.set_time(k);
        rec.shot();
        if k == res.r_noseStep
            rec.poster();
            rec.hold(15);          % a pause at the nose
        end
    end
    rec.hold(20);
    rec.finish(s_base);
end


function make_explore(s_base)
% Interactive: the result of the fault of make_fault_diagram. The playback bar is dragged
% to the fault, buses are clicked (ElementClickedFcn selects the bus in the diagram and its
% line in the chart), then the bar is dragged on.
    net = network.IEEE14bus();
    sc = net.add_scenario("fault", Time=[0, 5]);
    sc.add_fault("B008", [1, 1.05]);
    res = net.simulate("fault", Progress="none");
    fig = figure(Color="w", Position=[100 100 1120 560]);
    [G, G_chart] = res.plot_diagram(LabelFontSize=8, Parent=fig);
    G.ElementClickedFcn = @(G, data) select_bus(G, G_chart, data);
    for ax = findall(fig, "Type", "axes")'
        ax.Toolbar.Visible = "off";
    end
    rec = make_recorder(fig);
    rec.set_tick(@() G.step_flow(1/rec.r_fps));
    h_slider = findall(fig, "Tag", "GUILDA:GraphBase:TimeSlider");
    f_thumb = @() slider_thumb(h_slider);
    f_bus = @(s_tag) bus_point(G, s_tag);

    rec.cursor(f_thumb() + [140, 120]);
    rec.hold(8);
    rec.move(f_thumb(), 14);
    rec.hold(3);
    drag_slider(rec, G, h_slider, 1.02, 34);
    rec.hold(10);
    rec.move(f_bus("B004"), 16);
    rec.click(@() click_bus(G, "B004"));
    rec.hold(4);
    rec.poster();
    rec.hold(18);
    rec.move(f_bus("B012"), 16);
    rec.click(@() click_bus(G, "B012"));
    rec.hold(22);
    rec.move(f_thumb(), 16);
    drag_slider(rec, G, h_slider, 3.2, 34);
    rec.hold(24);
    rec.finish(s_base);
end


function make_controls(s_base)
% Interactive: the power flow of IEEE 39-bus. show_controls opens the panel; settings are
% changed in the panel (a drawn pointer clicks it) and by commands, and both stay in step.
    net = network.IEEE39Bus();
    res = net.calculate_powerflow();
    fig = figure(Color="w", Position=[100 100 1120 560]);
    h_main = uipanel(fig, Units="normalized", Position=[0 0.08 1 0.92], BorderType="none", BackgroundColor="w");
    ax_cmd = axes(fig, Units="normalized", Position=[0 0 1 0.08], Visible="off", XLim=[0 1], YLim=[0 1]);
    h_cmd = text(ax_cmd, 0.015, 0.5, "", FontName="Menlo", FontSize=13, Interpreter="none", Color=[0.15 0.15 0.15]);
    G = res.plot_diagram(LabelFontSize=7, Parent=h_main);
    for ax = findall(fig, "Type", "axes")'
        ax.Toolbar.Visible = "off";
    end
    rec = make_recorder(fig);
    rec.set_tick(@() G.step_flow(1/rec.r_fps));

    rec.hold(10);
    type_command(rec, h_cmd, ">> G.show_controls()");
    G.show_controls();
    rec.hold(16);
    f_widget = @(s_label) control_point(fig, s_label);
    rec.cursor(f_widget("Color") + [-160, -60]);
    sv_step = [ ...
        "panel",   "Color",       "P",     ">> % panel: Color = P        -> G.ColorMode is ""P"""; ...
        "panel",   "Bus color",   "V",     ">> % panel: Bus color = V    -> G.BusColorMode is ""V"""; ...
        "command", "",            "",      ">> G.MarkerSizeMode = ""S"";   % the panel follows"; ...
        "panel",   "Drawing",     "3D",    ">> % panel: Drawing = 3D     -> G.Dimension is ""3D"""; ...
        "panel",   "Bus height",  "V",     ">> % panel: Bus height = V   -> G.BusHeightMode is ""V"""];
    for i = 1:size(sv_step, 1)
        if sv_step(i, 1) == "panel"
            rec.move(f_widget(sv_step(i, 2)), 14);
            rec.click(@() set_control(fig, sv_step(i, 2), sv_step(i, 3)));
            h_cmd.String = sv_step(i, 4);
        else
            type_command(rec, h_cmd, sv_step(i, 4));
            G.MarkerSizeMode = "S";
        end
        rec.hold(12);
        if i == 2
            rec.poster();
        end
        rec.hold(10);
    end
    rec.hold(16);
    rec.finish(s_base);
end


function make_participation(s_base)
% Interactive: the participation of the buses in the modes of IEEE 68-bus (plot_participation).
% Eigenvalues are clicked on the map: the inter-area mode of 0.39 Hz, the local mode of the
% generator at B011 (1.63 Hz) and the mode of 0.66 Hz of the area of B014 to B016; then bus
% B014 is clicked and the table lists the participation of its states in that mode.
    res = network.IEEE68bus().get_sys();
    fig = figure(Color="w", Position=[100 100 1120 560]);
    sct = res.plot_participation(Parent=fig);
    for ax = findall(fig, "Type", "axes")'
        ax.Toolbar.Visible = "off";
    end
    G_eig = sct.Eigenvalue;
    G = sct.Diagram;
    cv_lambda = res.get_participation().cv_lambda;
    f_lambda = @(c) cv_lambda(nearest(cv_lambda, c));
    c_inter = f_lambda(-0.20 + 2.47i);
    c_local = f_lambda(-0.40 + 10.23i);
    c_area = f_lambda(-0.11 + 4.16i);
    f_eig = @(c) data_to_figure(G_eig.ax(1), real(c), imag(c));
    rec = make_recorder(fig);

    rec.cursor(f_eig(-0.2 + 5i));
    rec.hold(12);
    rec.move(f_eig(c_inter), 16);
    rec.click(@() click_eigenvalue(G_eig, c_inter));
    rec.hold(12);
    rec.poster();
    rec.hold(28);
    rec.move(f_eig(c_local), 18);
    rec.click(@() click_eigenvalue(G_eig, c_local));
    rec.hold(36);
    rec.move(f_eig(c_area), 18);
    rec.click(@() click_eigenvalue(G_eig, c_area));
    rec.hold(32);
    rec.move(bus_point(G, "B014"), 18);
    rec.click(@() click_bus(G, "B014"));
    rec.hold(44);
    rec.finish(s_base);
end


function make_gui(s_base)
% Interactive: the GUILDA app (GUILDA.launch_gui) on IEEE 14-bus. The load at B009 is clicked
% on the diagram and shown in the model GUI; its P is edited (a user types it into the cell of
% the page; the script sends the same edit event and shows the model again with render); the
% Power flow tab is opened and run; Analyze result opens the result window, which is recorded
% as its own figure and drawn over the app.
    h = GUILDA.launch_gui(network.IEEE14bus());
    fig = h.h_figure;
    fig.Position = [40 40 1360 680];
    settle();
    G = h.G;
    rec = make_recorder(fig);
    f_center = @(h_ui) center_of(h_ui);

    rec.cursor(data_to_figure(G.ax(1), 0.5, 0.45));
    rec.hold(12);
    [h_load, rv_load] = component_line(G, "B009LPQ1");
    rec.move(rv_load, 16);
    rec.click(@() h_load.ButtonDownFcn(h_load, []));
    settle();
    rec.hold(24);
    gui = findall(fig, "Tag", "tab_model").UserData.gui;
    h_body = findobj(gui.h_container, "Type", "uihtml", "Tag", "body");
    pos = getpixelposition(h_body, true);
    rec.move([pos(1) + 301, pos(2) + pos(4) - 159], 18);     % the cell P of the panel powerflow
    rec.click(@() edit_cell(gui, h_body, "powerflow", "P", "-0.6"));
    settle();
    rec.move([pos(1) + 345, pos(2) + pos(4) - 215], 10);     % off the cell: its new value shows
    rec.hold(22);
    h_tab_button = findall(fig, "Tag", "tab", "UserData", "pf");
    rec.move(f_center(h_tab_button), 18);
    rec.click(@() select_toggle(h_tab_button));
    settle();
    rec.hold(16);
    h_tab = findall(fig, "Tag", "tab_pf");
    h_run = findall(h_tab, "Tag", "run");
    rec.move(f_center(h_run), 16);
    rec.click(@() h_run.ButtonPushedFcn(h_run, []));
    settle();
    rec.hold(10);
    rec.poster();
    rec.hold(20);
    h_analyze = findall(h_tab, "Tag", "analyze");
    rec.move(f_center(h_analyze), 14);
    rec.click(@() h_analyze.ButtonPushedFcn(h_analyze, []));
    settle();
    fig_result = findall(groot, "Type", "figure", "Tag", "result_gui");
    fig_result = fig_result(1);
    fig_result.Position = [200 100 1000 540];
    settle();
    rec.hold(4);
    rec.overlay(fig_result, [330 96 1000 540]);
    rec.hold(16);
    rec.move([900, 300], 20);
    rec.hold(44);
    rec.finish(s_base);
    delete(fig_result);
    delete(fig);
end


%% Helpers of the items

function select_bus(G, G_chart, data)
% ElementClickedFcn of the explore item: a clicked bus is selected in the diagram and in the chart.
    if data.Kind ~= "bus"
        return
    end
    G.clear_selection();
    G.select(data.Tag);
    G_chart.clear_selection();
    G_chart.select(data.Tag);
end


function hide_bar(fig)
% Hide the playback bar (the axes take its strip, as in export_video) and the axes toolbars.
    h_bar = findall(fig, "Tag", "GUILDA:GraphBase:PlaybackBar");
    set(h_bar, "Visible", "off");
    drawnow;
    for ax = findall(fig, "Type", "axes")'
        ax.Toolbar.Visible = "off";
    end
end


function drag_slider(rec, G, h_slider, t_end, n_frame)
% Drag the time slider of the playback bar from its sample to the sample nearest t_end,
% calling its ValueChangingFcn as a drag does, with the pointer on the thumb.
    [~, k_end] = min(abs(G.rv_t - t_end));
    k_0 = h_slider.Value;
    rec.click([]);
    for i = 1:n_frame
        r_u = (1 - cos(pi*i/n_frame))/2;
        v = k_0 + (k_end - k_0)*r_u;
        h_slider.Value = v;
        h_slider.ValueChangingFcn(h_slider, struct("Value", v));
        rec.cursor(slider_thumb(h_slider));
        rec.shot();
    end
    h_slider.ValueChangedFcn(h_slider, struct("Value", h_slider.Value));
end


function rv_xy = slider_thumb(h_slider)
% [px] Position of the thumb of a uislider in the figure (from the bottom left).
    pos = getpixelposition(h_slider, true);
    r_pad = 7;
    r_f = (h_slider.Value - h_slider.Limits(1)) / diff(h_slider.Limits);
    rv_xy = [pos(1) + r_pad + r_f*(pos(3) - 2*r_pad), pos(2) + pos(4) + 7];
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


function i = nearest(cv, c)
% Index of the element of cv nearest to c.
    [~, i] = min(abs(cv - c));
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


function [h, rv_xy] = component_line(G, s_tag)
% The marker line of the component s_tag of a 2D diagram and its point in the figure [px].
    tab = G.tab_element;
    i_comp = tab.Index(tab.Tag == s_tag & tab.Kind == "component");
    h = findobj(G.ax(1), "-function", @(h) isprop(h, "UserData") && isstruct(h.UserData) ...
        && isfield(h.UserData, "Type") && h.UserData.Type == "Component" && isequal(h.UserData.Index, i_comp));
    h = h(1);
    rv_xy = data_to_figure(G.ax(1), mean(h.XData(isfinite(h.XData))), mean(h.YData(isfinite(h.YData))));
end


function edit_cell(gui, h_body, s_panel, s_var, s_value)
% Edit a cell of the Parameter tab of a model GUI: the event its page sends when a value is
% typed into the cell, then the model shown again (the page shows the typed value).
    c_panel = h_body.Data.tabs{1}.panels;
    sct = c_panel{cellfun(@(q) q.tag == s_panel, c_panel)};
    h_body.HTMLEventReceivedFcn(h_body, struct("HTMLEventName", "edit", ...
        "HTMLEventData", struct("index", sct.index, "var", s_var, "row", 1, "value", s_value)));
    gui.render(gui.a_target);
end


function select_toggle(h)
% Press a toggle button (a tab of the app), as a click does.
    h.Value = true;
    h.ValueChangedFcn(h, []);
end


function rv_xy = center_of(h)
% [px] Center of a UI component in its figure (from the bottom left).
    pos = getpixelposition(h, true);
    rv_xy = pos(1:2) + pos(3:4)/2;
end


function settle()
% Let the app finish its drawing (its timers and the pages of uihtml).
    drawnow;
    pause(0.6);
    drawnow;
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


function w = control_widget(fig, s_label)
% The widget of the row labeled s_label in the control panel of show_controls.
    h_label = findall(fig, "Type", "uilabel", "Text", s_label);
    h_label = h_label(arrayfun(@(h) isa(h.Parent, "matlab.ui.container.GridLayout") && isequal(h.Layout.Column, 1), h_label));
    h_label = h_label(1);
    c_child = h_label.Parent.Children;
    w = c_child(arrayfun(@(h) ~isa(h, "matlab.ui.control.Label") && isequal(h.Layout.Row, h_label.Layout.Row), c_child));
    w = w(1);
end


function rv_xy = control_point(fig, s_label)
% [px] Point of the figure on the widget of the row s_label of the control panel.
    pos = getpixelposition(control_widget(fig, s_label), true);
    rv_xy = [pos(1) + 0.4*pos(3), pos(2) + 0.45*pos(4)];
end


function set_control(fig, s_label, s_value)
% Choose s_value in the dropdown of the row s_label of the control panel, as a user does:
% its Value, then its ValueChangedFcn.
    w = control_widget(fig, s_label);
    w.Value = s_value;
    w.ValueChangedFcn(w, struct("Value", s_value));
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

function write_still(h, s_base, r_res)
% Write a still PNG of a figure or axes, at most 1280 px wide.
    if nargin < 3
        r_res = 144;
    end
    drawnow;
    s_file = s_base + ".png";
    exportgraphics(h, s_file, Resolution=r_res, BackgroundColor="white");
    sct = imfinfo(s_file);
    if sct.Width > 1280
        run_ffmpeg(sprintf('-i "%s" -vf scale=1280:-2:flags=lanczos "%s"', s_file, s_file + ".tmp.png"));
        movefile(s_file + ".tmp.png", s_file);
    end
end


function rec = make_recorder(fig)
% Frame recorder of a figure: shots with getframe, a drawn mouse pointer and click rings,
% and the encoding to MP4 and the poster PNG.
%
% rec.shot()             one frame (rec.set_tick(f) calls f() before each frame)
% rec.hold(n)            n frames
% rec.cursor(xy)         pointer at xy [px of the figure, from the bottom left]; [] none
% rec.move(xy, n)        move the pointer to xy in n frames
% rec.click(f)           a click ring at the pointer, then f() ([] for none)
% rec.poster()           the next frame is the poster (default: the last frame)
% rec.overlay(h, rect)   from now on, draw the frame of figure h over each frame in rect
%                        [x y w h] (px of the figure, from the top left), as a window
%                        opened over it; rec.overlay([]) none
% rec.finish(s_base)     write s_base.mp4 and s_base.png
    r_fps = 20;
    s_dir = string(tempname);
    mkdir(s_dir);
    n_out = 0;
    i_poster = 0;
    rv_cur = [];
    rm_ripple = zeros(0, 3);       % x, y [px of the image], age [frames]
    fcn_tick = [];
    iv_size = [];
    r_scale = NaN;
    n_ripple = 10;
    h_over = [];
    rv_over = [];

    rec.r_fps = r_fps;
    rec.shot = @shot;
    rec.hold = @hold_frames;
    rec.cursor = @set_cursor;
    rec.move = @move;
    rec.click = @click;
    rec.poster = @mark_poster;
    rec.set_tick = @set_tick;
    rec.overlay = @set_overlay;
    rec.finish = @finish;

    function set_overlay(h, rect)
        h_over = h;
        if nargin > 1
            rv_over = rect;
        end
    end

    function set_tick(f)
        fcn_tick = f;
    end

    function set_cursor(xy)
        rv_cur = xy;
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
        m_img = frame2im(getframe(fig));
        if isempty(iv_size)
            iv_size = 2*floor([size(m_img, 1), size(m_img, 2)]/2);
            r_scale = size(m_img, 2)/fig.Position(3);
        end
        m_out = 255*ones(iv_size(1), iv_size(2), 3, "uint8");
        n_h = min(iv_size(1), size(m_img, 1));
        n_w = min(iv_size(2), size(m_img, 2));
        m_out(1:n_h, 1:n_w, :) = m_img(1:n_h, 1:n_w, :);
        if ~isempty(h_over)
            m_out = draw_window(m_out, frame2im(getframe(h_over)), round(rv_over*r_scale));
        end
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
        n_w = min(1280, iv_size(2));
        s_in = fullfile(s_dir, "f%05d.png");
        for r_crf = [23, 26, 29, 32]
            run_ffmpeg(sprintf(['-framerate %d -i "%s" -vf scale=%d:-2:flags=lanczos -c:v libx264 -preset slow ' ...
                '-crf %d -pix_fmt yuv420p -movflags +faststart "%s"'], r_fps, s_in, n_w, r_crf, s_base + ".mp4"));
            sct = dir(s_base + ".mp4");
            if sct.bytes < 3.8e6
                break
            end
        end
        run_ffmpeg(sprintf('-i "%s" -vf scale=%d:-2:flags=lanczos "%s"', ...
            fullfile(s_dir, sprintf("f%05d.png", i_poster)), n_w, s_base + ".png"));
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


function m = draw_window(m, m_win, iv_rect)
% Draw the image m_win of a window, resized to iv_rect [x y w h] (px of the image, from the
% top left), over m with a gray edge and a soft shadow.
    m_win = resize_image(m_win, iv_rect([4 3]));
    [n_h, n_w, ~] = size(m);
    iv_y = iv_rect(2) + (1:iv_rect(4));
    iv_x = iv_rect(1) + (1:iv_rect(3));
    for r_off = 10:-2:2                % the shadow: darker near the window
        iv_sy = min(max(iv_y + r_off, 1), n_h);
        iv_sx = min(max(iv_x + r_off, 1), n_w);
        m(iv_sy, iv_sx, :) = uint8(double(m(iv_sy, iv_sx, :))*(0.93 + 0.004*r_off));
    end
    l_y = iv_y >= 1 & iv_y <= n_h;
    l_x = iv_x >= 1 & iv_x <= n_w;
    m(iv_y(l_y), iv_x(l_x), :) = m_win(l_y, l_x, :);
    rv_edge = uint8([150 150 150]);
    for c = 1:3
        m(iv_y(l_y), iv_x([find(l_x, 1), find(l_x, 1, "last")]), c) = rv_edge(c);
        m(iv_y([find(l_y, 1), find(l_y, 1, "last")]), iv_x(l_x), c) = rv_edge(c);
    end
end


function m = resize_image(m, iv_size)
% Resize an RGB image to iv_size [rows cols]: a box filter of the scale, then bilinear.
    [n_h, n_w, ~] = size(m);
    r_s = max(n_h/iv_size(1), n_w/iv_size(2));
    m = double(m);
    if r_s > 1
        n_k = max(1, round(r_s));
        K = ones(n_k)/n_k^2;
        for c = 1:3
            m(:, :, c) = conv2(m(:, :, c), K, "same");
        end
    end
    [X, Y] = meshgrid(linspace(1, n_w, iv_size(2)), linspace(1, n_h, iv_size(1)));
    m_out = zeros(iv_size(1), iv_size(2), 3);
    for c = 1:3
        m_out(:, :, c) = interp2(m(:, :, c), X, Y, "linear");
    end
    m = uint8(m_out);
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
