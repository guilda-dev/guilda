function out = get_tag(obj, s_split)
    % Tag of the layer followed by the tags of its parents, up the hierarchy.
    %
    % Returns the tags from the layer up to the top layer, joined by s_split.
    arguments (Input)
        obj % Target layer object.
        s_split (1,1) string = ""; % Delimiter between the tags.
    end
    arguments (Output)
        out % Composed tag string.
    end
    out = obj.s_tag;
    if isa(obj.parent,"LayerPackage")
        out = out + s_split + obj.parent.get_tag(s_split);
    end
end
