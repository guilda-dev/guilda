function unlink(obj, G_other)
% Remove the link between this graph and another one (both ways).
%
% Unlinking a graph that is not linked changes nothing.
%
% <@Examples>
% ```matlab
% G1.unlink(G2);
% ```
    arguments (Input)
        obj
        G_other (1,1) GraphBase  % Graph to unlink.
    end
    obj.c_link     = obj.c_link(cellfun(@(g) isvalid(g) && g ~= G_other, obj.c_link));
    G_other.c_link = G_other.c_link(cellfun(@(g) isvalid(g) && g ~= obj, G_other.c_link));
end
