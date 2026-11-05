function out = attach_tag(obj,sm_name_list)
% Generate names with layer tag suffix.
%
% Appends this class tag to each input name.
%
% <@Examples>
% ```matlab
% >> obj.attach_tag(["V", "P"])
% ans =
%     ["V_Tag", "P_Tag"]
% ```
    arguments (Input)
        obj % Target layer object.
        sm_name_list (:,:) string % Base names to be tagged.
    end
    arguments (Output)
        out % Input names with layer tag suffix.
    end
    out = sm_name_list +"_"+ obj.get_tag("_");
end
