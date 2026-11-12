function [out, sct_visited] = struct(obj, l_disp, s_header, sct_visited)
% Convert the branch to a nested struct, with its admittance matrix.
%
% The struct of LayerPackage.struct with one more field, `cm_Y`: the 2x2 complex
% admittance matrix of get_admittance_matrix, in the order of a_Bus (from, to). A network
% snapshot (struct(net, false)) therefore holds the admittance of every branch, whatever
% its class, and ResultPF computes the branch flows from it. A branch reached a second
% time is the path where it was first stored, as in LayerPackage.struct.
%
% <@Examples>
% ```matlab
% net = network.IEEE9bus();
% s   = struct(net.a_Branch{1});
% s.cm_Y                         % 2x2 complex admittance matrix [pu]
% ```
%
% See also LayerPackage.struct, Branch.get_admittance_matrix, ResultPF
    arguments (Input)
        obj
        l_disp      (1,1) logical = true    % Print the properties that cannot be read or copied.
        s_header    (1,1) string  = "net"   % Path of this layer in the struct, used for messages and repeated objects.
        sct_visited (1,1) struct  = struct("a_obj",{cell(0,1)}, "sv_path",strings(0,1))   % Layers already stored (a_obj) and their paths (sv_path), used by the recursion.
    end
    arguments (Output)
        out          % Nested struct of the branch with the field cm_Y, or its path when stored before.
        sct_visited  % Layers stored so far and their paths.
    end
    [out, sct_visited] = struct@LayerPackage(obj, l_disp, s_header, sct_visited);
    if isstruct(out)
        out.cm_Y = obj.get_admittance_matrix();
    end
end
