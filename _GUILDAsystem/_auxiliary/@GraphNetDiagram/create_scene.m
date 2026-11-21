function create_scene(obj)
% Draw the diagram of the sample shown in 2D or 3D (Dimension), with its colors, sizes and labels.
%
% The axes are cleared (a title set by the user stays) and drawn again. Both drawings
% hide the axis lines, keep the aspect ratio of the coordinates and fit the limits to the
% drawing with a small padding (fit_axes; in 2D also to the labels, which are moved apart
% when they overlap). 2D looks with an orthographic projection and draws the children
% in their order (SortMethod "childorder", no depth sorting of the flat symbols); 3D with
% a perspective projection, a fixed view angle (vis3d) and lights. The first drawing
% looks from the top; later drawings keep the view of the axes. The colorbar is shown by
% apply_style when an element has a color value. The callbacks (clicks, data tips) hold
% the diagram by a weak reference only, so that saving the figure does not save it.
%
% The timer of the flow animation is stopped first and started again at the end when it
% should run (flow_timer); the flow dots (2D only) take the new paths (flow_paths).
%
% A 2D redraw by set_data (net.plot_diagram(Graph=G), res.plot_diagram(Graph=G)) keeps the
% graphics objects of the drawing before (GraphBase.sct_pltPrevious) instead of clearing
% the axes, when the geometry (diagram_geometry), the tags, the graph parameters of the
% buses, branches and components, LinkWidth and the label font are the same (sct_plt.ReuseKey):
% only the colors, sizes, labels, flow dots and limits are set again.
    arguments (Input)
        obj
    end
    obj.flow_timer("stop");
    k = obj.i_time;
    obj.set_powerflow(obj.sct_state.cm_Vbus(:, k), obj.sct_state.cm_Icomp(:, k), obj.sct_state.cm_Ibranch(:, k));

    ax = obj.ax;
    l_keepView = obj.l_viewSet;
    if l_keepView
        [r_az, r_el] = view(ax);
    end
    % A 2D redraw by set_data keeps the objects of the drawing before when what they show
    % stays: the geometry, the tags, the shapes and styles, the link width and the label font
    sct_g = obj.diagram_geometry();
    sct_key = struct("g", sct_g, "bus", {obj.sv_bus}, "component", {obj.sv_componentTag}, "branch", {obj.sv_branch}, ...
        "busGraph", obj.tab_bus.graph, "branchGraph", obj.tab_branch.graph, "componentGraph", [], ...
        "font", {{obj.LinkWidth, obj.LabelFontSize, obj.LabelFontWeight}});
    if obj.n_component > 0
        sct_key.componentGraph = obj.tab_component.graph;
    end
    plt_old = obj.sct_pltPrevious;
    l_reuse = obj.Dimension == "2D" && isscalar(plt_old) && isfield(plt_old, "ReuseKey") ...
        && isequaln(plt_old.ReuseKey, sct_key);
    if l_reuse
        hv_old = [plt_old.EdgeMain(:); plt_old.NodeMain(:); plt_old.NodeLabel(:); plt_old.CompMain(:); ...
                  plt_old.CompEdge(:); plt_old.FlowBranch; plt_old.FlowLink];
        l_reuse = all(isgraphics(hv_old)) && all(arrayfun(@(h) h.Parent == ax, hv_old));
    end
    hold(ax, "on");
    wr = matlab.lang.WeakReference(obj);
    if l_reuse
        obj.sct_plt = plt_old;
        colorbar(ax, "off");
    else
        s_title = ax.Title.String;          % cla reset clears the title; a title set by the user stays
        cla(ax, "reset");
        colorbar(ax, "off");
        title(ax, s_title);
        hold(ax, "on");

        fcn_click = @(i_row) @(~, ~) click_weak(wr, i_row);
        if obj.Dimension == "2D"
            obj.draw_diagram_2d(sct_g, fcn_click);
        else
            obj.draw_graph_network(sct_g, fcn_click);
            obj.sct_plt.FlowBranch = gobjects(0);   % no flow dots in 3D
            obj.sct_plt.FlowLink   = gobjects(0);
        end
    end
    obj.sct_plt.ReuseKey = sct_key;
    obj.flow_paths();

    % Colors, labels and sizes of the sample, then every element drawn once
    obj.l_drawing = true;
    try
        obj.reflect_color_mode();
        obj.reflect_node_label();
        obj.update_sizes();
    catch err
        obj.l_drawing = false;
        rethrow(err);
    end
    obj.l_drawing = false;
    obj.apply_style((1:height(obj.element_table()))');
    obj.reflect_arrow_forward();

    % Box of the drawing (bus centers and bar ends, components, paths) for fit_axes
    tab_g = obj.tab_bus.graph;
    rv_h  = tab_g.Length/2;
    rv_h(~isfinite(rv_h)) = 0;
    rm_p = [sct_g.rm_bus; sct_g.rm_comp; vertcat(sct_g.c_branch{:}, zeros(0, 3)); vertcat(sct_g.c_link{:}, zeros(0, 3))];
    if obj.n_bus > 0
        lv_h = tab_g.Shape == "hbar";
        lv_v = tab_g.Shape == "vbar";
        rm_d = [rv_h.*lv_h, rv_h.*lv_v, zeros(obj.n_bus, 1)];
        rm_p = [rm_p; sct_g.rm_bus - rm_d; sct_g.rm_bus + rm_d];
    end
    rm_p = rm_p(all(isfinite(rm_p), 2), :);
    if isempty(rm_p)
        rm_p = [0 0 0; 1 1 0];
    end
    obj.sct_plt.DrawBox = [min(rm_p, [], 1); max(rm_p, [], 1)];

    clim(ax, obj.color_limits());
    colormap(ax, obj.Colormap);
    ax.XColor = "none";
    ax.YColor = "none";
    ax.ZColor = "none";
    obj.GridSpacing = obj.GridSpacing;
    zticks(ax, 0);
    daspect(ax, [1 1 1]);
    view(ax, 0, 90);
    obj.fit_axes();                     % limits (before vis3d of 3D), and 2D labels apart from each other
    if obj.Dimension == "2D"
        ax.Projection = "orthographic";
        ax.SortMethod = "childorder";
    else
        pbaspect(ax, "auto");
        daspect(ax, [1 1 1]);
        ax.Projection = "perspective";
        % The view angle is fixed (vis3d) only now, from the final aspect, view and
        % projection: fixed earlier, it is too narrow, the drawing overflows the axes and
        % the title lies outside the figure (and outside an exported image)
        axis(ax, "vis3d");
        for rv_pos = [1 0 1; -1 0 1; 0 1 1; 0 -1 1]'
            light(ax, "Position", rv_pos', "Style", "infinite", "Color", [0.35 0.35 0.35]);
        end
        light(ax, "Position", [0 0 1], "Style", "infinite", "Color", [0.20 0.20 0.20]);
        lighting(ax, "gouraud");
        material(ax, "shiny");
    end
    if l_keepView
        view(ax, r_az, r_el);
    end
    obj.l_viewSet = true;
    hold(ax, "off");

    fig = ancestor(ax, "figure");
    try                                 % a uifigure may not take these settings
        set(fig, "Renderer", "opengl", "GraphicsSmoothing", "on");
    catch
    end
    dcm = datacursormode(fig);
    set(dcm, "Enable", "on", "UpdateFcn", @(~, event) customhover(event, wr));
    obj.flow_timer("auto");
end


function click_weak(wr, i_row)
% Click on element i_row of the diagram held by the weak reference wr (nothing once deleted).
    arguments (Input)
        wr                  % Weak reference to the diagram. <@Type> matlab.lang.WeakReference
        i_row (1,1) double  % Row of the element in tab_element.
    end
    G = wr.Handle;
    if ~isempty(G) && isvalid(G)
        G.click_element(i_row);
    end
end


function txt = customhover(event_obj, wr)
% Data tip text of the element under the cursor; the data tip is also a click on it.
    arguments (Input)
        event_obj  % Event data of the data tip.
        wr         % Weak reference to the diagram. <@Type> matlab.lang.WeakReference
    end
    arguments (Output)
        txt  % Data tip text.
    end
    txt  = 'No Data...';
    G    = wr.Handle;
    hObj = event_obj.Target;
    if isempty(G) || ~isvalid(G) || ~isprop(hObj, 'UserData')
        return
    end
    sct_ud = hObj.UserData;
    if ~(isstruct(sct_ud) && all(isfield(sct_ud, ["Type", "Index"])))
        return
    end
    i = sct_ud.Index;
    switch sct_ud.Type
        case "Bus"
            txt = G.hover_bus(i);
            i_row = i;
        case "Branch"
            txt = G.hover_branch(i);
            i_row = G.n_bus + G.n_component + i;
        case "Component"
            txt = G.hover_component(i);
            i_row = G.n_bus + i;
        case "Link"
            txt = G.hover_component(i);
            i_row = G.n_bus + G.n_component + G.n_branch + i;
        otherwise
            return
    end
    G.click_element(i_row);   % a data tip is the click of the data cursor mode
end
