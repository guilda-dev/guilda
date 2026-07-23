function callbackPreSet(obj,name,event)
    % <@Desc>
    % Stores the current value before a property is changed.
    % <@Role>
    % Edit Log
    % <@Summary>
    % Stash the previous property value for later comparison.
    % <@Signatures>
    % [
    %   "callbackPreSet(obj, name, event)"
    % ]
    % <@Parameters>
    % [
    %   {
    %     "Name": "obj",
    %     "Type": "Parameter",
    %     "Description": "Target parameter container.",
    %     "Required": true,
    %     "Default": "-"
    %   },
    %   {
    %     "Name": "name",
    %     "Type": "string scalar",
    %     "Description": "Property name being updated.",
    %     "Required": true,
    %     "Default": "-"
    %   },
    %   {
    %     "Name": "event",
    %     "Type": "event data",
    %     "Description": "Property set event data.",
    %     "Required": true,
    %     "Default": "-"
    %   }
    % ]
    % <@Returns>
    % []
    obj.val_stash = event.AffectedObject.(name);
end