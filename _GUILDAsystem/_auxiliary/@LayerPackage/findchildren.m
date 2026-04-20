function c = findchildren(obj)
    % <@Desc>
    % Collects all descendant layers from the current layer.
    % <@Role>
    % Layer Structure
    % <@Abst>
    % Retrieve child layers recursively.
    % <@Signatures>
    % [
    %   "c = findchildren(obj)"
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
    % [
    %   {
    %     "Name": "c",
    %     "Type": "cell array",
    %     "Description": "Flattened descendant list including self when managed."
    %   }
    % ]
    a_children = obj.children;
    n_children = numel(a_children);
    cc = cell(n_children,1);
    for i = 1:n_children
        cc{i} = a_children{i}.layer_lower;
    end
    c = vertcat(cc{:});
    if obj.l_managedTag
        c = [c;{obj}];
    end
end