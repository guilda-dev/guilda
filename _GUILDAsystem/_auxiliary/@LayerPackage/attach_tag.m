function out = attach_tag(obj,sm_name_list)
% Generate names with layer tag suffix.
%
% Appends to each input name the tag of this layer followed by the tags of its parents,
% joined by "_", up to the layer below the network: the network tag is not part of a
% label. Tags are unique only among siblings, so the parent tags keep the labels unique
% within a network.
%
% <@Examples>
% ```matlab
% >> net = network.Tutorial10bus();
% >> gen = net.a_Bus{1}.a_Component{1};
% >> gen.attach_tag(["delta", "omega"])
% ans =
%     "delta_SG1B001_B001"    "omega_SG1B001_B001"
% ```
    arguments (Input)
        obj % Target layer object.
        sm_name_list (:,:) string % Base names to be tagged.
    end
    arguments (Output)
        out % Input names with layer tag suffix.
    end
    s_suffix = string(obj.s_tag);
    a_layer  = obj.parent;
    while isa(a_layer,"LayerPackage") && ~isa(a_layer,"PowerNetwork")
        s_suffix = s_suffix + "_" + a_layer.s_tag;
        a_layer  = a_layer.parent;
    end
    out = sm_name_list + "_" + s_suffix;
end
