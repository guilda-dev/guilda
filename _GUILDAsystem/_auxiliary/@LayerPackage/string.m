function str = string(obj)
% Convert the layer object to a tag string.
%
% Returns the tag string representation of this layer object.
%
% <@Examples>
% ```matlab
% str = string(obj);
% ```
    arguments (Input)
        obj
    end
    arguments (Output)
        str % Tag string of the layer object.
    end
    str = obj.s_tag;
end
