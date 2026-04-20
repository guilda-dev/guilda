function reset_edit(obj)
    % <@Desc>
    % Resets edit status and clears edit logs recursively.
    % <@Role>
    % Edit Log
    % <@Abst>
    % Initialize edit state for this layer and descendants.
    % <@Signatures>
    % [
    %   "reset_edit(obj)"
    % ]
    % <@varargin>
    % [
    %   {
    %     "Name": "obj",
    %     "Type": "LayerPackage",
    %     "Description": "Target layer object.",
    %     "Required": true,
    %     "Default": "-"
    %   }
    % ]
    % <@varargout>
    % []
    obj.str_editFlag = "initialized";
    obj.tab_editLog  = array2table(zeros(0,6),'VariableNames',{'timestamp','ID','log','tag','before','after'});
    cellfun(@(c) c.reset_edit, obj.children);
end