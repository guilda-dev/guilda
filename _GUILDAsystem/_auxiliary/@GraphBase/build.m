function build(obj, opt, n_panel, rv_grid)
% Set the axes and the options, draw the scene and show the first sample.
%
% Called by the constructor of a subclass after load_data. The axes come from
% make_axes(opt.Parent, n_panel, rv_grid): a container (figure, uifigure, uipanel, uitab,
% uigridlayout) gets a tiled layout of rv_grid (n_row x n_col, default one column) with
% n_panel axes filled row by row, an axes or uiaxes is used directly (single-panel graphs
% only), and empty means a new figure. The appearance vectors at this
% point are kept as the defaults of reset_style. The other fields of opt are copied to the
% properties of the same name.
%
% The graph lives as long as its axes: a listener on ax(1) holds it in a containers.Map
% and empties the map when the axes are destroyed. The graphics callbacks of the
% subclasses hold the graph only by a matlab.lang.WeakReference (a strong reference in a
% callback makes savefig recurse), so a graph whose output is not taken keeps working, and
% deleting its figure frees it. The listener is not saved with the figure. A listener that
% captured the graph directly would not free it (graph -> axes -> listener -> graph).
%
% A graph with samples to play (has_playback) gets its playback bar (refresh_bar); the
% timer of its playback is stopped and deleted when the graph is deleted.
    arguments (Input)
        obj
        opt (1,1) struct                                                    % Name-Value options of the constructor of the subclass.
        n_panel (1,1) double {mustBeInteger, mustBePositive} = 1            % Number of panels of the graph.
        rv_grid (1,2) double {mustBeInteger, mustBePositive} = [n_panel 1]  % Rows and columns of the tiles (at least n_panel tiles).
    end
    h_parent = [];
    if isfield(opt, "Parent")
        h_parent = opt.Parent;
    end
    obj.ax = obj.make_axes(h_parent, n_panel, rv_grid);
    map_keep = containers.Map();
    map_keep("G") = obj;
    addlistener(obj.ax(1), "ObjectBeingDestroyed", @(~, ~) remove(map_keep, "G"));

    % Defaults of the appearance (reset_style) before the options change it
    sct_map = obj.style_properties();
    obj.sct_styleDefault = struct();
    for s_kind = string(fieldnames(sct_map))'
        for s_opt = string(fieldnames(sct_map.(s_kind)))'
            s_prop = sct_map.(s_kind).(s_opt);
            obj.sct_styleDefault.(s_prop) = obj.(s_prop);
        end
    end
    for s_field = setdiff(string(fieldnames(opt))', "Parent")
        obj.(s_field) = opt.(s_field);
    end
    obj.create_scene();
    obj.i_time = 1;
    obj.update_scene(1);
    obj.apply_selection();
    addlistener(obj, "ObjectBeingDestroyed", @(G, ~) G.play_bar(false));
    obj.refresh_bar();
end
