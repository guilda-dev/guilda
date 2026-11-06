function a_owner = edit_owner(obj)
% Layer whose edits obj reports: the owner for a Parameter container, obj otherwise.
    arguments (Input)
        obj
    end
    arguments (Output)
        a_owner  % Owner layer.
    end
    a_owner = obj;
    if isa(obj,"Parameter") && isa(obj.parent,"LayerPackage")
        a_owner = obj.parent;
    end
end
