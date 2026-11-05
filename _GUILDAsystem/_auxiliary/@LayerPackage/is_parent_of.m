function l = is_parent_of(obj, a_layer)
% True when obj is the parent of a_layer (parent is protected, so a subclass cannot
% read it on a layer of another branch of the class tree, e.g. a Parameter).
    arguments (Input)
        obj
        a_layer  % Any layer.
    end
    arguments (Output)
        l (1,1) logical  % True when a_layer.parent is obj.
    end
    a_parent = a_layer.parent;
    l = isa(a_parent, "LayerPackage") && a_parent == obj;
end
