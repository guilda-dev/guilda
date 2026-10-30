function p = findparent(obj) 
    % Retrieve root layer from current object.
    %
    % Finds the top-level parent layer in the hierarchy.
    arguments (Output)
        p % Top-level parent layer (or self if root).
    end
    if isa(obj.parent,"LayerPackage")
        p = obj.parent.layer_root;
    else
        p = obj;
    end
end