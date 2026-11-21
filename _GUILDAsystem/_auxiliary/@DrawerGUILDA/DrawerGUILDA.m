classdef DrawerGUILDA < auxiliary
% The GUILDA app: tabs for the usual work, the network diagram, the run log and the script.
%
% GUILDA.launch_gui creates one in a new uifigure, with one HistoryGUILDA for the whole app:
% every action is a line of MATLAB code run by that history, so the log shows the code and
% "Export script" writes a script that repeats the session (HistoryGUILDA.export_script).
% Every model GUI and result GUI opened from the app uses the same history. All the text of
% the app is in English.
%
% - Start screen (without a network): Empty network (`net = PowerNetwork();`), Sample network
%   (a list of the classes of `_GUILDAobject/+network`, `net = network.IEEE14bus();`), Model
%   folder (`net = PowerNetwork.import("<path>");`) and MATPOWER case
%   (`net = PowerNetwork.import_matpower("<case>");`). The choice runs through the history,
%   so it is the first line of the script. With a network (GUILDA.launch_gui(net)) the
%   history holds it as `net` and the script header says so.
% - Top: a tab bar across the whole width (toggle buttons): Model, Power flow, OPF, CPF,
%   Time simulation, Linearization.
% - Left half: a two-line info strip (counts of buses, branches and components, the stale
%   state and the last run; then what the colors of the diagram mean) with the toggle
%   "Display options", the network diagram G, and under it the run log
%   (HistoryGUILDA.attach_view, 130 px high; "Hide log" collapses it) with "Export script".
%   "Display options" shows the control panel of the diagram (G.show_controls) to the right
%   of the diagram; its changes only set properties of G and are not logged.
% - Right half: the panel of the active tab.
%
% Each tab has a diagram of its own, in a panel of its own in the left half; only the panel
% of the active tab is shown, and only its diagram runs the flow animation. A run of the
% history that ended (Changed) marks every tab out of date: the active tab gets its hook
% f_changed and its diagram is drawn again; a hidden tab gets both on its next show, and a
% tab switch without a run in between draws nothing. These drawings are not logged. What a diagram shows depends on
% its tab (the hook f_diagram of the tab), and the hook f_legend of the tab writes what its
% colors mean in the info strip; a click on an element is passed to the hook f_click of the
% tab. In the model tab a click shows the element in the model GUI (DrawerModelGUI) and the
% element shown is selected in the diagram, also after a navigation in the model GUI
% (TargetChanged). The diagram fits itself to its panel (plot_diagram).
%
% The window is built hidden and shown once its first tab is drawn. In a visible window the
% drawing after a run follows by a short timer, so the GUI that ran the code responds first.
%
% Each tab is a set of private files registered in private/tab_list.m. Its build function
% fills the panel of the tab on its first show and returns its hooks; it gets the tab API, a
% struct with the helpers of the frame (run code with a progress dialog, a stale banner with
% a button that runs `net.initialize();`). The frame never changes to fill a tab. The
% contract is documented in notes/launch-gui.md and in private/tab_list.m.
%
% The colors are the fixed light palette of the GUILDA GUIs (tools.gui_palette).
%
% <@Examples>
% ```matlab
% h = GUILDA.launch_gui();                     % start screen
% h = GUILDA.launch_gui(network.IEEE9bus());   % with a network
% disp(h.history.get_script())                 % the code of the session
% ```
%
% See also GUILDA.launch_gui, HistoryGUILDA, DrawerModelGUI, DrawerResultGUI, GraphNetDiagram

    properties(SetAccess = private) % App
        history      % Log that runs and records every action of the app as code. <@Type> HistoryGUILDA
        G            % Network diagram of the active tab ([] before its first drawing). <@Type> GraphNetDiagram
        h_figure     % Figure of the app. <@Type> matlab.ui.Figure
    end
    properties(Access = private) % Layout
        sct_tab      % Tabs (tab_list) with h_button, h_panel, l_built, the hooks f_show, f_changed, f_diagram, f_legend, f_click, and n_changed (n_change at its last f_changed), the diagram h_diagram, G, n_drawn (n_change at its drawing), l_flow (its FlowAnimation while hidden), a_click, s_error (of its drawing) and l_controls (its control panel has controls). <@Type> struct
        s_active     % Key of the active tab ("" before the main layout). <@Type> string
        h_root       % Grid of the figure: the tab bar over the body. <@Type> matlab.ui.container.GridLayout
        h_info       % Info strip over the diagram (two lines). <@Type> matlab.ui.control.Label
        h_toggle     % Toggle "Display options". <@Type> matlab.ui.control.StateButton
        h_diagram    % Panel of the diagrams (Tag "diagram"); its grid holds one panel per tab. <@Type> matlab.ui.container.Panel
        h_side       % Grid of the diagram panel and, in its second column, the control panels of the diagrams. <@Type> matlab.ui.container.GridLayout
        a_listener   % Listener of the history (Changed). <@Type> event.listener
        n_change     % Number of the ended runs of the history; a diagram drawn at a smaller number is out of date. <@Type> double
        h_timer      % Single-shot timer (0.05 s) of the drawing after a run in a visible figure. <@Type> timer
    end

    methods
        function obj = DrawerGUILDA(net, opt)
        % Create the app in a new uifigure: the start screen, or the main layout with net.
        %
        % Called by GUILDA.launch_gui. Visible=false builds the app in a hidden figure (tests).
            arguments (Input)
                net = []                                        % Network to work on; [] shows the start screen. <@Type> PowerNetwork
                opt.Visible (1,1) matlab.lang.OnOffSwitchState = "on"  % Visibility of the figure.
            end
            arguments (Output)
                obj  % The app.
            end
            s_header = "Script of the GUILDA app (GUILDA.launch_gui).";
            if isempty(net)
                obj.history = HistoryGUILDA(Header=s_header);
            elseif isa(net, "PowerNetwork") && isscalar(net)
                obj.history = HistoryGUILDA(Header=[s_header, ...
                    "net is the network passed at startup (GUILDA.launch_gui(net)): run this script with it in the workspace as net."]);
                obj.history.set_variable("net", net);
            else
                error(msg("GUILDA:DrawerGUILDA:NotNetwork", class(net)))
            end
            sct_color = tools.gui_palette();
            obj.h_figure = uifigure("Name", "GUILDA", "Position", [60 60 1440 860], ...     % Tag: ProgressGUILDA shows its dialog in this window
                "Color", sct_color.rv_background, "Visible", "off", "Tag", "GUILDA:app");
            if isprop(obj.h_figure, "Theme")
                obj.h_figure.Theme = "light";
            end
            obj.h_root = uigridlayout(obj.h_figure, [2 1], "RowHeight", {36, "1x"}, "Padding", 0, ...
                "RowSpacing", 0, "BackgroundColor", sct_color.rv_background);

            % Tab bar: one toggle button per tab, enabled with the main layout
            obj.sct_tab = tab_list();
            n_tab = numel(obj.sct_tab);
            h_bar = uigridlayout(obj.h_root, [1 n_tab], "ColumnWidth", repmat({"1x"}, 1, n_tab), ...
                "Padding", [6 4 6 0], "ColumnSpacing", 4, "BackgroundColor", sct_color.rv_blue);
            for i = 1:n_tab
                obj.sct_tab(i).h_button = uibutton(h_bar, "state", "Text", obj.sct_tab(i).s_title, ...
                    "Tag", "tab", "UserData", obj.sct_tab(i).s_key, "Enable", "off", "FontWeight", "bold", ...
                    "FontColor", sct_color.rv_header_text, "BackgroundColor", sct_color.rv_blue, ...
                    "ValueChangedFcn", @(src, ~) obj.show_tab(src.UserData));
                obj.sct_tab(i).h_panel = gobjects(0);
                obj.sct_tab(i).l_built = false;
                for s_hook = ["f_show", "f_changed", "f_diagram", "f_legend", "f_click"]
                    obj.sct_tab(i).(s_hook) = [];
                end
                obj.sct_tab(i).h_diagram = gobjects(0);
                obj.sct_tab(i).G = [];
                obj.sct_tab(i).n_drawn = -1;
                obj.sct_tab(i).n_changed = 0;
                obj.sct_tab(i).l_flow = true;
                obj.sct_tab(i).a_click = [];
                obj.sct_tab(i).s_error = "";
                obj.sct_tab(i).l_controls = false;
            end
            obj.s_active = "";
            obj.G = [];
            obj.n_change = 0;
            obj.h_timer = timer("ExecutionMode", "singleShot", "StartDelay", 0.05, "BusyMode", "drop", ...
                "Tag", "GUILDA:DrawerGUILDA:Redraw", "TimerFcn", @(~, ~) obj.redraw());    % drawing after a run (on_history_changed)
            obj.a_listener = listener(obj.history, "Changed", @(~, ~) obj.on_history_changed());
            obj.h_figure.DeleteFcn = @(~, ~) cellfun(@(f, x) f(x), {@stop, @delete, @delete}, {obj.h_timer, obj.h_timer, obj.a_listener});
            if isempty(net)
                obj.build_start();
            else
                obj.build_main();
            end
            % Shown once built: the components are drawn together
            obj.h_figure.Visible = opt.Visible;
            if opt.Visible && obj.s_active ~= ""
                drawnow    % the window is usable before the flow animation starts (its first timer start is slow)
                obj.show_tab(obj.s_active);    % starts the flow animation, which a hidden figure does not run
            end
        end
    end

    methods(Access = private)
        build_start(obj)
        build_main(obj)
        show_tab(obj, s_key)
        call_hook(obj, s_hook, varargin)
        redraw(obj, l_force)
        on_history_changed(obj)
        [l_ok, s_detail] = run_code(obj, s_group, s_label, s_code, opt)
        h_banner = stale_banner(obj, h_grid, i_row, s_group)
    end
end
