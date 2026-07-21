function varargout = disp_tree(obj,str_space,str_ignore,l_isfirst)
% <@Desc>
% Displays or returns a text tree of this layer and its descendants.
% <@Role>
% Layer Structure
% <@Summary>
% Render the hierarchy tree with optional filtering.
% <@Signatures>
% [
%   "disp_tree(obj)",
%   "text = disp_tree(obj, str_space, str_ignore, l_isfirst)"
% ]
% <@Parameters>
% [
%   {
%     "Name": "obj",
%     "Type": "LayerPackage",
%     "Description": "Root layer object.",
%     "Required": true,
%     "Default": "-"
%   },
%   {
%     "Name": "str_space",
%     "Type": "string scalar",
%     "Description": "Indentation prefix for recursive rendering.",
%     "Required": false,
%     "Default": "\"\""
%   },
%   {
%     "Name": "str_ignore",
%     "Type": "string array",
%     "Description": "Class names to ignore in output.",
%     "Required": false,
%     "Default": "[\"Parameter\"]"
%   },
%   {
%     "Name": "l_isfirst",
%     "Type": "logical scalar",
%     "Description": "Whether this call is the root invocation.",
%     "Required": false,
%     "Default": "true"
%   }
% ]
% <@Returns>
% [
%   {
%     "Name": "text",
%     "Type": "string",
%     "Description": "Hierarchy string when one output is requested."
%   }
% ]
    arguments
        obj 
        str_space  (1,1) string  = ""
        str_ignore (1,:) string  = ["Parameter"];
        l_isfirst  (1,1) logical = true;
    end
    text = "";
    if l_isfirst
        text = text + newline;
        clsLink = link(obj);
        text = text +" "+obj.str_tag+" "+clsLink+newline;
    end
    
    a_children = obj.children;
    for ig = str_ignore
        l_ignore = cellfun(@(c) isa(c,ig), a_children);
        a_children = a_children(~l_ignore);
    end
    
    if isempty(a_children)
        varargout{1} = text;
        return
    end
    
    for i = 1:numel(a_children)-1
        child   = a_children{i};
        clsLink = link(child);
        text = text+str_space+"   ┣━━ "+child.str_tag+" "+clsLink+newline;
        text_ = child.disp_tree(str_space+"   ┃  ",str_ignore,false);
        text  = text + text_;
    end
    child   = a_children{end};
    clsLink = link(child);
    text  = text + str_space+"   ┗━━ "+child.str_tag+" "+clsLink+newline;
    text_ = child.disp_tree(str_space+"     ",str_ignore,false);
    text  = text + text_;
    
    if l_isfirst
        text = text+newline;
    end

    switch nargout
        case 0; disp(text)
        case 1; varargout{1} = text;
    end
end

function clsLink = link(cls)
    clsName = class(cls);
    clsLink = ['<a href="matlab:doc(''',clsName,''');">@',clsName,'</a>'];
end