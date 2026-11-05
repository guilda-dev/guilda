function out = get_tag(obj,l_with_layer, s_split)
    % Build tag string with optional hierarchy composition.
    %
    % Returns the layer tag, optionally including parent-layer tags.
    arguments (Input)
        obj % Target layer object.
        l_with_layer (1,1) logical = false; % Include parent-layer tags recursively.
        s_split      (1,1) string  = ""; % Delimiter for composed tags.
    end
    arguments (Output)
        out % Layer tag string.
    end

    if obj.l_managedTag
        out = obj.s_tag;
    else
        out = "";
    end

    if l_with_layer && isa(obj.parent,"LayerPackage")
        s_pTag = obj.parent.get_tag(l_with_layer,s_split);
        if strlength(s_pTag) == 0 || strlength(out) == 0
            s_split = "";
        end
        out =  out + s_split + s_pTag;
    end
end