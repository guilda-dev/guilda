function str_newtag = validate_tag(obj,str_newtag)
    % Ensure tag uniqueness among same-layer objects.
    %
    % Validates tag uniqueness within sibling layers and renames on conflicts.
    %
    % Inputs:
    % - `str_newtag`: Candidate tag.
    arguments (Output)
        str_newtag % Validated unique tag.
    end
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