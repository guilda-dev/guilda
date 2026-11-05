function [net, sct_visited] = struct(obj, l_disp, s_header, sct_visited)
% Convert the layer and its descendants to a nested struct.
%
% Copies every property of the layer into a struct field (field "class" holds the class
% name); child layers become nested structs and an object reached a second time becomes
% the path where it was first stored. Analysis objects (auxiliary) and other handles are
% not copied.
    arguments (Input)
        obj 
        l_disp     (1,1) logical   = true; % Print the properties that cannot be read or copied.
        s_header   (1,1) string    = "net"; % Path of this layer in the struct, used for messages and repeated objects.
        sct_visited (1,1) struct   = struct("a_obj",{cell(0,1)}, "sv_path",strings(0,1)); % Layers already stored (a_obj) and their paths (sv_path), used by the recursion.
    end
    arguments (Output)
        net % Nested struct of the layer.
        sct_visited % Layers stored so far and their paths.
    end

    % compared by identity: different layers may share a tag
    lv_visited = cellfun(@(o) o == obj, sct_visited.a_obj);
    if any(lv_visited)
        net = sct_visited.sv_path(lv_visited);
        return
    end

    sct_visited.a_obj{end+1,1}   = obj;
    sct_visited.sv_path(end+1,1) = s_header;
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
        [net.(s_pi), sct_visited] = copy(inst_pi, l_disp, s_header_i, sct_visited);
    end    
end

function [out, sct_visited] = copy(data_inst, l_disp, s_head, sct_visited)

    if iscell(data_inst)
        n_inst = numel(data_inst);
        out = cell(n_inst,1);
        for i = 1:n_inst
            s_head_i = s_head + "{"+i+"}";
            [out{i}, sct_visited] = copy(data_inst{i}, l_disp, s_head_i, sct_visited);
        end

    elseif isa(data_inst, "LayerPackage")
        [out, sct_visited] = data_inst.struct(l_disp, s_head, sct_visited);

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