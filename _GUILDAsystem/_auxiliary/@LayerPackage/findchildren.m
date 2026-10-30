function c = findchildren(obj)
    % Retrieve child layers recursively.
    %
    % Collects all descendant layers from the current layer.
    arguments (Output)
        c % Flattened descendant list including self when managed.
    end
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