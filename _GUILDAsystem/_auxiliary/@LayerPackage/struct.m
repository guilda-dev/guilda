function [net, dict_cls] = struct(obj, l_disp, str_header, dict_cls)
% Convert the layer and its descendants to a nested struct.
%
% Copies every property of the layer into a struct field (field "class" holds the class
% name); child layers become nested structs and an object reached a second time becomes
% the path where it was first stored. Analysis objects (auxiliary) and other handles are
% not copied.
    arguments
        obj 
        l_disp     (1,1) logical   = true; % Print the properties that cannot be read or copied.
        str_header (1,1) string    = "net"; % Path of this layer in the struct, used for messages and repeated objects.
        dict_cls   (1,1) dictionary= dictionary("NoData","NaN"); % Objects already stored and their paths (used by the recursion).
    end
    arguments (Output)
        net % Nested struct of the layer.
        dict_cls % Objects stored so far and their paths.
    end

    if isKey(dict_cls, obj)
        net = string(obj);
        return
    end

    dict_cls(obj) = str_header;
    net = struct('class', string(class(obj)) );

    str_prop = properties(obj);
    for i = 1:numel(str_prop)
        str_pi = str_prop{i};
        str_header_i = str_header + "." + str_pi;
        try
            inst_pi = obj.(str_pi);
        catch
            if l_disp
                disp("(!) Failed to get.  >> " + str_header_i)
            end
            continue
        end
        [net.(str_pi), dict_cls] = copy(inst_pi, l_disp, str_header_i, dict_cls);
    end    
end

function [out, dict_cls] = copy(data_inst, l_disp, str_head, dict_cls)

    if iscell(data_inst)
        n_inst = numel(data_inst);
        out = cell(n_inst,1);
        for i = 1:n_inst
            str_head_i = str_head + "{"+i+"}";
            [out{i}, dict_cls]  = copy(data_inst{i}, l_disp, str_head_i, dict_cls);
        end

    elseif isa(data_inst, "LayerPackage")
        [out,dict_cls] = data_inst.struct(l_disp, str_head, dict_cls);

    elseif isa(data_inst, "auxiliary")
        out = "out of target.";

    elseif isa(data_inst,"handle")
        if l_disp
            disp("(!) Unable to copy. >> "+str_head)
        end
        out = nan;
    else
        out = data_inst;
    end
end