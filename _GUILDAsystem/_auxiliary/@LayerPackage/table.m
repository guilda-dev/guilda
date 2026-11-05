function tab = table(obj)
% Convert layer parameters into table format.
%
% Returns the parameter table associated with this layer object.
%
% <@Examples>
% ```matlab
% tab = table(obj);
% ```
    arguments (Input)
        obj
    end
    arguments (Output)
        tab % Parameter table of the layer.
    end
    tab = obj.tab_parameter;
end
