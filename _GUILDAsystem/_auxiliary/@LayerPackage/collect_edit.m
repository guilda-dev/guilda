function sct_log = collect_edit(obj)
    % Edits of this layer and its descendants, in the order they were made.
    %
    % Returns the rows of every layer of the subtree (children form a tree: no layer
    % twice) as one struct array (Nx1), sorted by time and then by the sequence number
    % for edits within one clock tick.
    arguments (Input)
        obj
    end
    arguments (Output)
        sct_log  % Edit rows (Nx1 struct; fields as sct_editLog).
    end
    c_log = collect_rows(obj, {obj.sct_editLog([])});
    sct_log = reshape([c_log{:}], [], 1);
    [~, iv] = sortrows([reshape([sct_log.r_time],[],1), reshape([sct_log.i_seq],[],1)]);
    sct_log = sct_log(iv);
end


function c_log = collect_rows(obj, c_log)
% Append the rows of obj and its descendants to c_log. A Parameter container among the
% children keeps no rows (log_edit stores them on its owner) and has no children.
    if ~isempty(obj.sct_editLog)
        c_log{end+1} = obj.sct_editLog;
    end
    a_children = obj.children;
    for i = 1:numel(a_children)
        if ~isa(a_children{i}, "Parameter")
            c_log = collect_rows(a_children{i}, c_log);
        end
    end
end
