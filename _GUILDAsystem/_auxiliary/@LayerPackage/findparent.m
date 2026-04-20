function p = findparent(obj) 
    % <@Desc>
    % Finds the top-level parent layer in the hierarchy.
    % <@Role>
    % Layer Structure
    % <@Abst>
    % Retrieve root layer from current object.
    % <@Signatures>
    % [
    %   "p = findparent(obj)"
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
    %     "Name": "p",
    %     "Type": "LayerPackage",
    %     "Description": "Top-level parent layer (or self if root)."
    %   }
    % ]
    if isa(obj.parent,"LayerPackage")
        p = obj.parent.layer_root;
    else
        p = obj;
    end
end