function link(obj, G_other)
% Link another graph so that both follow set_time.
%
% The link is symmetric: G1.link(G2) is the same as G2.link(G1), and set_time on either
% moves both (each at the sample nearest to t of its own times). Linking a graph twice, or
% to itself, changes nothing. A deleted graph is dropped from the links. export_video
% records the figure of the graph it is called on: linked graphs in other figures move
% while the video is written but are not in it.
%
% <@Examples>
% ```matlab
% G1 = res.plot_spring_model();
% G2 = res.plot_diagram();
% G1.link(G2);
% G1.set_time(1.0);        % G2 shows t = 1.0 too
% ```
    arguments (Input)
        obj
        G_other (1,1) GraphBase  % Graph to link.
    end
    if G_other == obj
        return
    end
    obj.c_link     = add_graph(obj.c_link, G_other);
    G_other.c_link = add_graph(G_other.c_link, obj);
end


function c = add_graph(c, G)
% The list of graphs c without deleted graphs and with G once.
    arguments (Input)
        c cell   % Linked graphs.
        G (1,1)  % Graph to add. <@Type> GraphBase
    end
    arguments (Output)
        c cell  % Linked graphs.
    end
    c = c(cellfun(@(g) isvalid(g), c));
    if ~any(cellfun(@(g) g == G, c))
        c{end+1} = G;
    end
end
