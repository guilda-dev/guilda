function varargout = disp_tree(obj, sr_ignore)
% Render the hierarchy tree with optional filtering.
%
% Displays or returns a text tree of this layer and its descendants.
%
% Outputs:
% - `text`: Hierarchy string when one output is requested.
    arguments
        obj % Root layer object.
        sr_ignore (1,:) string = ["Parameter"]; % Class names to ignore in output.
    end
    text = newline + " " + obj.s_tag + " " + link(obj) + newline ...
         + subtree(obj, "", sr_ignore) + newline;

    switch nargout
        case 0; disp(text)
        case 1; varargout{1} = text;
    end
end

function text = subtree(obj, s_space, sr_ignore)
% Lines of the descendants of obj, each indented by s_space.
    a_children = obj.children;
    for ig = sr_ignore
        l_ignore = cellfun(@(c) isa(c,ig), a_children);
        a_children = a_children(~l_ignore);
    end

    text = "";
    n_child = numel(a_children);
    for i = 1:n_child
        child = a_children{i};
        if i < n_child
            s_branch = "   ┣━━ ";  s_next = "   ┃  ";
        else
            s_branch = "   ┗━━ ";  s_next = "     ";
        end
        text = text + s_space + s_branch + child.s_tag + " " + link(child) + newline ...
             + subtree(child, s_space + s_next, sr_ignore);
    end
end

function clsLink = link(cls)
    clsName = class(cls);
    clsLink = ['<a href="matlab:doc(''',clsName,''');">@',clsName,'</a>'];
end
