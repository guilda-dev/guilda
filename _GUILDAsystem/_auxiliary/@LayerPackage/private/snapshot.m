function [net, sct_visited] = snapshot(obj, l_disp, s_header, sct_visited)
% Recursion of LayerPackage.struct: the nested struct of one layer.
%
% A layer stored before (compared by identity among the stored layers with the same tag)
% becomes its path. A child layer whose class overrides struct (e.g. Branch, which adds
% cm_Y) is converted by that method, which calls LayerPackage.struct and so this function
% again; the other child layers are converted here directly.
%
% sct_visited holds a_obj (stored layers), sv_path (their paths), sv_tag (their tags, see
% tag_key) and d_override (class name -> the class overrides struct).
    arguments (Input)
        obj         (1,1) LayerPackage
        l_disp      (1,1) logical
        s_header    (1,1) string
        sct_visited (1,1) struct
    end
    arguments (Output)
        net
        sct_visited (1,1) struct
    end

    % compared by identity: different layers may share a tag
    s_tag = tag_key(obj);
    for k = reshape(find(sct_visited.sv_tag == s_tag), 1, [])
        if sct_visited.a_obj{k} == obj
            net = sct_visited.sv_path(k);
            return
        end
    end

    sct_visited.a_obj{end+1,1}   = obj;
    sct_visited.sv_path(end+1,1) = s_header;
    sct_visited.sv_tag(end+1,1)  = s_tag;
    net = struct('class', string(class(obj)) );

    sv_prop = properties(obj);
    for i = 1:numel(sv_prop)
        s_pi = sv_prop{i};
        s_header_i = s_header + "." + s_pi;
        try
            inst_pi = obj.(s_pi);
        catch
            if l_disp
                disp("(!) Failed to get.  >> " + s_header_i)
            end
            continue
        end
        if iscell(inst_pi) || isobject(inst_pi)
            [net.(s_pi), sct_visited] = copy(inst_pi, l_disp, s_header_i, sct_visited);
        else
            net.(s_pi) = inst_pi;   % plain value (copy returns it as it is)
        end
    end
end

function [out, sct_visited] = copy(data_inst, l_disp, s_head, sct_visited)
% Copy of one property value: cells element by element, layers as nested structs.
    arguments (Input)
        data_inst
        l_disp      (1,1) logical
        s_head      (1,1) string
        sct_visited (1,1) struct
    end
    arguments (Output)
        out
        sct_visited (1,1) struct
    end

    if iscell(data_inst)
        n_inst = numel(data_inst);
        out = cell(n_inst,1);
        for i = 1:n_inst
            s_head_i = s_head + "{"+i+"}";
            [out{i}, sct_visited] = copy(data_inst{i}, l_disp, s_head_i, sct_visited);
        end

    elseif isa(data_inst, "LayerPackage")
        [l_override, sct_visited] = overrides_struct(data_inst, sct_visited);
        if l_override
            [out, sct_visited] = data_inst.struct(l_disp, s_head, sct_visited);
        else
            [out, sct_visited] = snapshot(data_inst, l_disp, s_head, sct_visited);
        end

    elseif isa(data_inst, "auxiliary")
        out = "out of target.";

    elseif isa(data_inst,"handle")
        if l_disp
            disp("(!) Unable to copy. >> "+s_head)
        end
        out = nan;
    else
        out = data_inst;
    end
end

function [l_override, sct_visited] = overrides_struct(obj, sct_visited)
% True when the class of the layer defines its own struct method (cached per class).
    arguments (Input)
        obj         (1,1) LayerPackage
        sct_visited (1,1) struct
    end
    arguments (Output)
        l_override  (1,1) logical
        sct_visited (1,1) struct
    end
    s_class = string(class(obj));
    if isKey(sct_visited.d_override, s_class)
        l_override = sct_visited.d_override(s_class);
        return
    end
    a_method   = metaclass(obj).MethodList;
    a_struct   = a_method(strcmp({a_method.Name}, 'struct'));
    l_override = ~strcmp(a_struct(1).DefiningClass.Name, 'LayerPackage');
    sct_visited.d_override(s_class) = l_override;
end
