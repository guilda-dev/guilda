function h = launch_gui(obj, h_container, opt)
% Show the model in a GUI: breadcrumb, class, tag, Docs button, stale state, child cards and tables.
%
% With no container it opens a new uifigure; with a container (uifigure, uipanel, uitab or
% uigridlayout) it fills it, so that the GUI can be embedded in another app. The breadcrumb
% runs from the root to this model, and the cards show its children by kind; a click on
% either shows that model in the same container. The Docs button opens the reference page
% of the class. The add buttons and the Remove item of the card menus add and remove
% models (and the disturbances of a Scenario), and the parameter tables are editable; the
% abstract classes provide the other tables (gui_content), so a model class needs no GUI
% code. A Scenario has no parameter tab, only its pages (Disturbances, Settings).
%
% Every action runs as a line of MATLAB code in History (HistoryGUILDA.run), from the root
% variable of the model tree (`net` for a network): the code is logged, and
% `h.history.get_script()` returns a script that repeats the actions. The default history
% prints each `>> code` in the Command Window. See DrawerModelGUI.
%
% <@Examples>
% ```matlab
% net = network.IEEE14bus();
% h = net.a_Bus{1}.launch_gui();                % new window
% fig = uifigure();
% p = uipanel(uigridlayout(fig, [1 1]));
% h = net.launch_gui(p);                        % embedded in a panel
% hist = HistoryGUILDA();
% h = net.launch_gui(History=hist);             % log the actions in hist
% ```
    arguments (Input)
        obj
        h_container = []  % Container to fill: uifigure, uipanel, uitab or uigridlayout (default: a new uifigure).
        opt.History (1,1) HistoryGUILDA = HistoryGUILDA(Echo=true)  % Log that runs and records the actions; its root variable (net, bus, ...) is set when missing.
    end
    arguments (Output)
        h DrawerModelGUI  % The GUI.
    end
    % Made here, in the base class of every layer, so that DrawerModelGUI, an outside class,
    % can read the protected members (parent, children, gui_content) of every layer it shows,
    % including a Scenario (a LayerPackage that is not a PowerSystemModel).
    f_model = @(o) struct("parent", {o.parent}, "children", {o.children}, "pages", {o.gui_content()});
    h = DrawerModelGUI(obj, h_container, f_model, opt.History);
end
