function out = attach_tag(obj,str_name_list)
% <@Desc> 
% Appends this class tag to each input name.
% <@Role>
% Tag
% <@Summary>
% Generate names with layer tag suffix.
% <@Signatures>
% [
%   "out = attach_tag(obj, str_name_list)"
% ]
% <@Parameters>
% [
%   {
%     "Name": "obj",
%     "Type": "LayerPackage",
%     "Description": "Target layer object.",
%     "Required": true,
%     "Default": "-"
%   },
%   {
%     "Name": "str_name_list",
%     "Type": "string array",
%     "Description": "Base names to be tagged.",
%     "Required": true,
%     "Default": "-"
%   }
% ]
% <@Returns>
% [
%   {
%     "Name": "out",
%     "Type": "string array",
%     "Description": "Input names with layer tag suffix."
%   }
% ]
% <@Examples>
% [
%   ">> obj.attach_tag([\"V\", \"P\"])\nans =\n    [\"V_Tag\", \"P_Tag\"]"
% ]
    arguments
        obj 
        str_name_list (:,:) string
    end
    out = str_name_list +"_"+ obj.get_tag(true,"_");
end
