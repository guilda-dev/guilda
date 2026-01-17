function out = get_tag(obj,l_with_layer, str_split)
    arguments
        obj 
        l_with_layer (1,1) logical = false;
        str_split    (1,1) string  = "";
    end

    if obj.tag=="NoTag"
        out = "";
        return
    end

    if isnan(obj.Index)
        out = obj.tag;
    else
        out = obj.tag+obj.index;
    end

    if l_with_layer && ~isnan(obj.parent)
        str_pTag = obj.parent.getTag(true);
        if ~isempty(char(str_pTag))
            out =  str_pTag + str_split + out;
        end
    end
end