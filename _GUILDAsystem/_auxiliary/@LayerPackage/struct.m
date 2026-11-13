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
        sct_visited (1,1) struct   = struct("a_obj",{cell(0,1)}, "sv_path",strings(0,1)); % Layers already stored (a_obj) and their paths (sv_path), used by the recursion. The recursion adds the fields sv_tag and d_override (see private/snapshot).
    end
    arguments (Output)
        net % Nested struct of the layer.
        sct_visited % Layers stored so far and their paths (with the recursion fields sv_tag and d_override).
    end

    % The recursion keeps the tag of each stored layer (sv_tag) to compare only layers with
    % the same tag, and which classes override struct (d_override). A caller that passes
    % only a_obj and sv_path gets them here; a subclass override that calls this method
    % within the recursion passes them on.
    if ~isfield(sct_visited, "sv_tag")
        sct_visited.sv_tag = string(cellfun(@tag_key, sct_visited.a_obj, "UniformOutput", false));
        sct_visited.sv_tag = reshape(sct_visited.sv_tag, [], 1);
    end
    if ~isfield(sct_visited, "d_override")
        sct_visited.d_override = dictionary(strings(0,1), false(0,1));
    end
    [net, sct_visited] = snapshot(obj, l_disp, s_header, sct_visited);
end
