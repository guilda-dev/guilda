function callbackPostSet(obj,name,cls,event)
    % <@Desc>
    % Validates a property after it is changed and logs edits.
    % <@Role>
    % Edit Log
    % <@Abst>
    % Check type consistency and record changes when values differ.
    % <@Signatures>
    % [
    %   "callbackPostSet(obj, name, cls, event)"
    % ]
    % <@varargin>
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
    %     "Name": "cls",
    %     "Type": "string scalar",
    %     "Description": "Expected class name.",
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
    % <@varargout>
    % []
    val_pre  = obj.val_stash;
    val_post = event.AffectedObject.(name);            
    
    if ~isa(val_post,cls)
        obj.(name) = val_pre;
        error(msg('GUILDA:Parameter:ClassNameMismatch', name, cls))                
    elseif val_pre ~= val_post
        obj.log_edit("edit "+name, "Parameter("+obj.str_tag+")", val_pre, val_post);
        obj.CallbackChanged();
    end
end