function h = gui(obj, h_container)
% Show the model in a GUI: class, tag, stale state, parameter tables and layer tree.
%
% With no container it opens a new uifigure; with a container (uifigure, uipanel, uitab or
% uigridlayout) it fills it, so that the GUI can be embedded in another app. The parameter
% tables are editable; the tree shows the parent, this model and its children, and a click
% on a node shows that model in the same container. Subclasses add pages through
% gui_content. See DrawerModelGUI.
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
    % Made here so that DrawerModelGUI, an outside class, can read the protected members
    % (parent, children, gui_content) of every model it shows.
    f_model = @(o) struct("parent", {o.parent}, "children", {o.children}, "pages", {o.gui_content()});
    h = DrawerModelGUI(obj, h_container, f_model);
end
