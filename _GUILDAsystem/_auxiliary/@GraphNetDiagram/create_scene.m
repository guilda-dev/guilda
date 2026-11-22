function create_scene(obj)
% Draw the diagram of the sample shown in 2D or 3D (Dimension), with its colors, sizes and labels.
%
% The axes are cleared (a title set by the user stays) and drawn again. Both drawings
% hide the axis lines, keep the aspect ratio of the coordinates and fit the limits to the
% drawing with a small padding (fit_axes; in 2D also to the labels, which are moved apart
% when they overlap). 2D looks with an orthographic projection and draws the children
% in their order (SortMethod "childorder", no depth sorting of the flat symbols); 3D with
% a perspective projection, a fixed view angle (vis3d) and lights. The first drawing
% looks from the top; later drawings keep the view of the axes. In 3D with BusHeightMode
% other than "none" (the height guide of draw_graph_network), the z axis shows the
% quantity and its unit, the limits take in the floor and the top of every sample, and
% the view turns to az -37.5, el 30 when the heights appear while the axes look from the
% top (back to the top when they go away and that view was kept). The colorbar is shown by
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
    % Whether the drawing before had the height guide (3D with BusHeightMode): the view
    % turns to the oblique default only when the guide appears or goes away
    plt_before = obj.sct_plt;
    if isempty(plt_before)
        plt_before = obj.sct_pltPrevious;
    end
    l_guideBefore = isscalar(plt_before) && isfield(plt_before, "HeightGuide") && ~isempty(plt_before.HeightGuide);
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
    sct_guide = struct.empty;
    if isfield(obj.sct_plt, "HeightGuide")
        sct_guide = obj.sct_plt.HeightGuide;
    end
    if ~isempty(sct_guide)                  % the floor and the top of every sample: limits that stay over time
        rm_p = [rm_p; rm_p(1, 1:2), sct_guide.ZFloor; rm_p(1, 1:2), sct_guide.ZTop];
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
        if ~isempty(sct_guide)              % the z axis tells the values (1-2-5 steps), the quantity and its unit
            r_ref   = sct_guide.ZReference;
            rv_val  = r_ref + ([sct_guide.ZFloor, sct_guide.ZTop] - r_ref)/sct_guide.Scale;
            rv_step = 10^floor(log10(diff(rv_val)/5))*[1 2 5 10];
            r_step  = rv_step(find(rv_step >= diff(rv_val)/5, 1));
            rv_tick = (ceil(rv_val(1)/r_step):floor(rv_val(2)/r_step))*r_step;
            ax.ZColor = [0.35 0.35 0.35];
            zticks(ax, r_ref + sct_guide.Scale*(rv_tick - r_ref));
            zticklabels(ax, compose("%g", round(rv_tick/r_step)*r_step + 0));   % + 0: no "-0"
            zlabel(ax, sct_guide.Name);
        end
    end
    % The first 3D drawing with heights looks obliquely (from the top, the heights could
    % not be seen); the view goes back to the top when the heights go away and it was
    % still that oblique view. A view the user rotated to stays.
    rv_oblique = [-37.5 30];
    if ~isempty(sct_guide) && ~l_guideBefore && (~l_keepView || all(abs([r_az r_el] - [0 90]) < 1e-9))
        view(ax, rv_oblique);
    elseif isempty(sct_guide) && l_guideBefore && l_keepView && all(abs([r_az r_el] - rv_oblique) < 1e-9)
        view(ax, 0, 90);
    elseif l_keepView
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
%
% Under the first line (the tag), the color value of the element at the sample shown gets
% one line "<name> = <value>" (color_readout: the name of the colorbar, %.4g) after a
% square of its color, when it is finite: BusColorData of a bus, BranchColorData of a
% branch (the quantity of ColorMode, or the values of "user"), ComponentColorData of a
% component and LinkColorData of a link. It is the line of the colored value even when the
% tip lists the same quantity (|I| of the "from" end with "I", P_loss with "Loss").
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
    [s_line, r_value] = G.color_readout(lower(string(sct_ud.Type)), i);
    if ~ismissing(s_line)
        s_line = sprintf('\\fontname{SansSerif}{\\color[rgb]{%.3f,%.3f,%.3f}■} %s', G.color_of_values(r_value), s_line);
        txt = [txt(1), {s_line}, txt(2:end)];
    end
    G.click_element(i_row);   % a data tip is the click of the data cursor mode
end
