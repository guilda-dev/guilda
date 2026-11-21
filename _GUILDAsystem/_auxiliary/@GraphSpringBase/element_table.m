function tab = element_table(obj)
% Elements of the picture: the nodes, the springs and the arrow pairs (tag of their node).
    arguments (Input)
        obj
    end
    arguments (Output)
        tab table  % Tag, Kind and Index of every element.
    end
    d = obj.sct_data;
    n_node  = numel(d.sv_node);
    n_edge  = size(d.im_edge, 2);
    n_arrow = numel(d.iv_arrow);
    Tag   = [d.sv_node; d.sv_edge; d.sv_node(d.iv_arrow)];
    Kind  = [repmat("node", n_node, 1); repmat("edge", n_edge, 1); repmat("arrow", n_arrow, 1)];
    Index = [(1:n_node)'; (1:n_edge)'; (1:n_arrow)'];
    tab = table(Tag, Kind, Index);
end
