function str_newtag = validate_tag(obj,str_newtag)
    % <@Desc>
    % Validates tag uniqueness within sibling layers and renames on conflicts.
    % <@Role>
    % Tag
    % <@Abst>
    % Ensure tag uniqueness among same-layer objects.
    % <@Signatures>
    % [
    %   "str_newtag = validate_tag(obj, str_newtag)"
    % ]
    % <@varargin>
    % [
    %   {
    %     "Name": "obj",
    %     "Type": "LayerPackage",
    %     "Description": "Target layer object.",
    %     "Required": true,
    %     "Default": "-"
    %   },
    %   {
    %     "Name": "str_newtag",
    %     "Type": "string scalar",
    %     "Description": "Candidate tag.",
    %     "Required": true,
    %     "Default": "-"
    %   }
    % ]
    % <@varargout>
    % [
    %   {
    %     "Name": "str_newtag",
    %     "Type": "string scalar",
    %     "Description": "Validated unique tag."
    %   }
    % ]
    str_newtag = string(str_newtag);

    if ~obj.l_managedTag || isempty(obj.parent)
        return
    end
    
    a_sameLayer = obj.parent.children;
    l_me  = tools.vcellfun(@(a) a==obj, a_sameLayer);
    str_sameLayer = string( a_sameLayer(~l_me) );
    lv_overlap    = str_sameLayer==str_newtag;
    if any(lv_overlap)
        id = 2;
        str_modified = str_newtag+num2str(id,"%.3d");
        while ismember(str_modified, str_sameLayer)
            id = id+1;
            str_modified = str_newtag+num2str(id,"%.3d");
        end
        fprintf("Info : Tag changed due to overlaps detected")
        disp(['[ "',char(str_newtag),'" >> "',char(str_modified),'"]'])
        str_newtag = str_modified;
    end
end