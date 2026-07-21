function out = get_tag(obj,l_with_layer, str_split)
    % <@Desc>
    % Returns the layer tag, optionally including parent-layer tags.
    % <@Role>
    % Tag
    % <@Summary>
    % Build tag string with optional hierarchy composition.
    % <@Signatures>
    % [
    %   "out = get_tag(obj)",
    %   "out = get_tag(obj, l_with_layer, str_split)"
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
    %     "Name": "l_with_layer",
    %     "Type": "logical scalar",
    %     "Description": "Include parent-layer tags recursively.",
    %     "Required": false,
    %     "Default": "false"
    %   },
    %   {
    %     "Name": "str_split",
    %     "Type": "string scalar",
    %     "Description": "Delimiter for composed tags.",
    %     "Required": false,
    %     "Default": "\"\""
    %   }
    % ]
    % <@Returns>
    % [
    %   {
    %     "Name": "out",
    %     "Type": "string",
    %     "Description": "Layer tag string."
    %   }
    % ]
    arguments
        obj 
        l_with_layer (1,1) logical = false;
        str_split    (1,1) string  = "";
    end

    if obj.l_managedTag
        out = obj.str_tag;
    else
        out = "";
    end

    if l_with_layer && isa(obj.parent,"LayerPackage")
        str_pTag = obj.parent.get_tag(l_with_layer,str_split);
        if isempty(char(str_pTag)) || isempty(char(out))
            str_split = "";
        end
        out =  out + str_split + str_pTag;
    end
end