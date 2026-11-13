function s_tag = tag_key(obj)
% Tag of a layer as a string scalar ("" while the tag is not set), used by struct to find
% the layers already stored with the same tag.
    arguments (Input)
        obj (1,1) LayerPackage  % Layer.
    end
    arguments (Output)
        s_tag (1,1) string      % Tag of the layer, or "".
    end
    if isempty(obj.s_tag)
        s_tag = "";
    else
        s_tag = string(obj.s_tag);
    end
end
