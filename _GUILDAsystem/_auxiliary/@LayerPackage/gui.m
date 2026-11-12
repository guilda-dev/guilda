function h = gui(obj, h_container)
% Show the model in a GUI: breadcrumb, class, tag, Docs button, stale state, child cards and tables.
%
% With no container it opens a new uifigure; with a container (uifigure, uipanel, uitab or
% uigridlayout) it fills it, so that the GUI can be embedded in another app. The breadcrumb
% runs from the root to this model, and the cards show its children by kind; a click on
% either shows that model in the same container. The Docs button opens the reference page
% of the class. The parameter tables are editable; the abstract classes provide the other
% tables (gui_content), so a model class needs no GUI code. A Scenario has no parameter
% tab, only its pages (Disturbances, Settings). See DrawerModelGUI.
%
% <@Examples>
% ```matlab
% net = network.IEEE14bus();
% h = net.a_Bus{1}.gui();                       % new window
% fig = uifigure();
% p = uipanel(uigridlayout(fig, [1 1]));
% h = net.gui(p);                               % embedded in a panel
% ```
    arguments (Input)
        obj
        h_container = []  % Container to fill: uifigure, uipanel, uitab or uigridlayout (default: a new uifigure).
    end
    arguments (Output)
        h DrawerModelGUI  % The GUI.
    end
    % Made here, in the base class of every layer, so that DrawerModelGUI, an outside class,
    % can read the protected members (parent, children, gui_content) of every layer it shows,
    % including a Scenario (a LayerPackage that is not a PowerSystemModel).
    f_model = @(o) struct("parent", {o.parent}, "children", {o.children}, "pages", {o.gui_content()});
    h = DrawerModelGUI(obj, h_container, f_model);
end
