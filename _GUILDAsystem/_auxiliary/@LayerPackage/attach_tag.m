function out = attach_tag(obj,sm_name_list)
% Generate names with layer tag suffix.
%
% Appends "_" and the tag of this layer to each input name. A generated tag already
% contains the tags of the parents (B001SG1 on bus B001, B001SG1CA1 under it,
% PowerNetworkAGC1 on the network), which keeps the labels unique within a network.
%
% <@Examples>
% ```matlab
% >> net = network.Tutorial10bus();
% >> gen = net.a_Bus{1}.a_Component{1};
% >> gen.attach_tag(["delta", "omega"])
% ans =
%     "delta_B001SG1"    "omega_B001SG1"
% ```
    arguments (Input)
        obj % Target layer object.
        sm_name_list (:,:) string % Base names to be tagged.
    end
    arguments (Output)
        out % Input names with layer tag suffix.
    end
    out = sm_name_list + "_" + obj.s_tag;
end
