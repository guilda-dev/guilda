function out = get_tag(obj,l_with_layer, str_split)
    % Build tag string with optional hierarchy composition.
    %
    % Returns the layer tag, optionally including parent-layer tags.
    arguments
        obj % Target layer object.
        l_with_layer (1,1) logical = false; % Include parent-layer tags recursively.
        str_split    (1,1) string  = ""; % Delimiter for composed tags.
    end
    arguments (Output)
        out % Layer tag string.
    end

    if obj.l_managedTag
        out = obj.str_tag;
    else
        out = "";
    end

    if l_with_layer && isa(obj.parent,"LayerPackage")
        str_pTag = obj.parent.get_tag(l_with_layer,str_split);
        if isempty(char(str_pTag)) || isempty(char(out))
            str_split = "";
        end
        out =  out + str_split + str_pTag;
    end
end