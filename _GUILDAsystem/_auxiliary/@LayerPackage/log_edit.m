function log_edit(obj, log, tag, before, after, time, tab)
    % <@Desc>
    % Records an edit event and propagates it to parent layers.
    % <@Role>
    % Edit Log
    % <@Summary>
    % Append a new edit-log record.
    % <@Signatures>
    % [
    %   "log_edit(obj)",
    %   "log_edit(obj, log, tag, before, after, time, tab)"
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
    %     "Name": "log",
    %     "Type": "string scalar",
    %     "Description": "Edit message.",
    %     "Required": false,
    %     "Default": "\"\""
    %   },
    %   {
    %     "Name": "tag",
    %     "Type": "string scalar",
    %     "Description": "Edited field tag.",
    %     "Required": false,
    %     "Default": "\"\""
    %   },
    %   {
    %     "Name": "before",
    %     "Type": "double scalar",
    %     "Description": "Value before edit.",
    %     "Required": false,
    %     "Default": "NaN"
    %   },
    %   {
    %     "Name": "after",
    %     "Type": "double scalar",
    %     "Description": "Value after edit.",
    %     "Required": false,
    %     "Default": "NaN"
    %   },
    %   {
    %     "Name": "time",
    %     "Type": "string scalar",
    %     "Description": "Timestamp for the event.",
    %     "Required": false,
    %     "Default": "current time"
    %   },
    %   {
    %     "Name": "tab",
    %     "Type": "table (1x6)",
    %     "Description": "Prebuilt edit-log row.",
    %     "Required": false,
    %     "Default": "auto-generated"
    %   }
    % ]
    % <@Returns>
    % []
    arguments
        obj 
        log   (1,1) string = "";                                                    %#ok
        tag   (1,1) string = ""; %#ok
        before = nan;                                                               %#ok
        after  = nan;                                                               %#ok
        time   = string(datetime('now','Format','uuuu/MM/dd HH:mm:ss'));            %#ok
        tab    = table(time, obj.get_tag(true,"/"), log, tag, {before}, {after})
    end
    if isa(obj,"PowerNetwork")
        if obj.str_editFlag == "unset"
            return
        else
            obj.str_editFlag = "editted";
            tab.Properties.VariableNames = {'timestamp','ID','log','tag','before','after'};
            obj.tab_editLog  = [obj.tab_editLog; tab];
        end
    elseif isa(obj.parent,"LayerPackage")
        obj.str_editFlag = "editted";
        obj.parent.log_edit("","",nan,nan,"",tab)
    else
        return
    end
end