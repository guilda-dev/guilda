function create_scene(obj)
% Draw the graph plot of the map: buses at their positions, the flows as arrows, the colorbar.
%
% With Arrow "P" or "Q" the graph is a digraph whose edges point from the end where the
% power enters the branch; with "none" an undirected graph. The edges of a graph plot are
% sorted by their end nodes, so sct_plt.EdgeBranch keeps the branch of each edge.
% The buses are at the positions of the data (load_data placed those without one). The
% color limits are fixed at the range of the
% voltage values so that the RGB colors of BusColor and the colormap agree.
    arguments (Input)
        obj
    end
    sd     = obj.sct_data;
    sv_bus = sd.sv_bus;
    n_br   = numel(sd.sv_branch);
    im_end = sd.im_end;
    l_rev  = sd.rm_flow(:, 1) < 0;                     % the power enters at the second bus
    im_dir = im_end;
    im_dir(l_rev, :) = im_end(l_rev, [2 1]);
    l_undirected = sd.s_arrow == "none";
    if l_undirected
        gr = graph(im_end(:, 1), im_end(:, 2), [], cellstr(sv_bus));
        im_ref = sort(im_end, 2);
    else
        gr = digraph(im_dir(:, 1), im_dir(:, 2), [], cellstr(sv_bus));
        im_ref = im_dir;
    end
    % Branch of each edge of the graph plot (G.Edges is sorted by its end nodes)
    im_gr   = reshape(findnode(gr, gr.Edges.EndNodes), [], 2);
    iv_edge = zeros(n_br, 1);
    l_used  = false(n_br, 1);
    for k = 1:n_br
        i = find(~l_used & im_ref(:, 1) == im_gr(k, 1) & im_ref(:, 2) == im_gr(k, 2), 1);
        iv_edge(k) = i;
        l_used(i)  = true;
    end

    ax = obj.ax;
    h = plot(ax, gr, "XData", sd.rm_xy(:, 1), "YData", sd.rm_xy(:, 2));
    if sd.s_color == "V"
        rv_c = abs(sd.cv_V);
    else
        rv_c = rad2deg(angle(sd.cv_V));
    end
    h.NodeCData = rv_c;
    rv_lim = [min(rv_c), max(rv_c)];
    if ~(rv_lim(2) > rv_lim(1))
        rv_lim = mean(rv_lim) + [-1 1] * max(1e-3, 1e-3 * abs(mean(rv_lim)));
    end
    colormap(ax, parula);
    clim(ax, rv_lim);
    cb = colorbar(ax);
    if ~l_undirected && any(sd.rm_flow(:) ~= 0)
        h.ArrowSize = 9;
    end
    h.UserData = sd.sv_branch(iv_edge);                % branch tag of each edge, in plot order
    h.Tag      = "GraphNetMap";
    title(ax, "Power flow (color: " + sd.s_color + ", arrows: " + sd.s_arrow + ")");
    axis(ax, "off");
    wr = matlab.lang.WeakReference(obj);           % a saved figure does not save the map
    h.ButtonDownFcn = @(~, evt) click_weak(wr, evt.IntersectionPoint(1:2));

    obj.sct_plt = struct("Graph", h, "Colorbar", cb, "EdgeBranch", iv_edge, ...
        "EdgeColor0", h.EdgeColor(1, :), "BranchWidth", nan(n_br, 1), "Selection", gobjects(0, 1));
    cb.Label.String = obj.colorbar_text();
    obj.apply_style((1:height(obj.element_table()))');
end


function click_weak(wr, rv_point)
% Click at a point of the map held by the weak reference wr (nothing once deleted).
    arguments (Input)
        wr                     % Weak reference to the map. <@Type> matlab.lang.WeakReference
        rv_point (1,2) double  % Point clicked [x y].
    end
    G = wr.Handle;
    if ~isempty(G) && isvalid(G)
        G.click_at(rv_point);
    end
end
