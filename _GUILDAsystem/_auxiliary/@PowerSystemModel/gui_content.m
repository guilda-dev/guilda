function sct_page = gui_content(obj)
% Pages that the GUI (gui) shows after the Parameter tab; subclasses override it to add pages.
%
% Each element of the struct column is one tab:
%
% - `s_title`: tab name.
% - `s_type`: "latex", "image", "table" or "action".
% - `content`: LaTeX strings, one display equation per element, drawn with the bundled
%   KaTeX ("latex"), image file path ("image"), table ("table") or `@() ...` run by the
%   button ("action"; the GUI is drawn again afterwards).
% - `s_label`: text of the button of an "action" page; "" for the other types.
%
% The default returns, in this order:
%
% - "Equations" ("latex"): the ```` ```math ```` blocks of the help of the class of the model,
%   from the `**Equations**` heading up to the next `**...**` heading or `<@Examples>`, in
%   the order they appear; none when the help has no such block.
% - "Image" ("image"): the image.svg of the class folder, searched from the class of the
%   model up through its superclasses; none when no folder has one.
%
% A subclass appends its pages to those of its superclass. Declare the override in the
% classdef as `methods(Access=protected) sct_page = gui_content(obj) end`.
%
% <@Examples>
% ```matlab
% function sct_page = gui_content(obj)
%     sct_page = gui_content@component.generator.abstract(obj);
%     sct_page(end+1,1) = struct("s_title","Swing", "s_type","latex", ...
%         "content","M\ddot{\delta} = P_m - P_e", "s_label","");
%     sct_page(end+1,1) = struct("s_title","Recompute", "s_type","action", ...
%         "content",@() obj.a_PowerNetwork.initialize(), "s_label","initialize");
% end
% ```
    arguments (Input)
        obj
    end
    arguments (Output)
        sct_page (:,1) struct  % Pages: fields s_title, s_type, content, s_label.
    end
    sct_page = repmat(struct("s_title","", "s_type","", "content",[], "s_label",""), 0, 1);
    sv_math = extract_math(string(class(obj)));
    if ~isempty(sv_math)
        sct_page(end+1,1) = struct("s_title","Equations", "s_type","latex", "content",sv_math, "s_label","");
    end
    % Breadth-first from the class of the model up through its superclasses.
    sv_class = string(class(obj));
    while ~isempty(sv_class)
        s_class = sv_class(1);
        sv_class(1) = [];
        s_folder = fileparts(which(s_class));
        [~, s_name] = fileparts(s_folder);
        s_image = fullfile(s_folder, "image.svg");
        if startsWith(s_name, "@") && isfile(s_image)
            sct_page(end+1,1) = struct("s_title","Image", "s_type","image", "content",string(s_image), "s_label","");
            return
        end
        mc = meta.class.fromName(s_class);
        if ~isempty(mc) && ~isempty(mc.SuperclassList)
            sv_class = [sv_class, string({mc.SuperclassList.Name})]; %#ok<AGROW>
        end
    end
end

function sv_math = extract_math(s_class)
% The ```math blocks of the help of a class between **Equations** and the next **...** or <@Examples>.
    arguments (Input)
        s_class (1,1) string  % Class name.
    end
    arguments (Output)
        sv_math (:,1) string  % LaTeX of each block, in the order they appear.
    end
    sv_math = strings(0,1);
    sv_line = strip(splitlines(string(help(s_class))), "left");
    i_start = find(startsWith(sv_line, "**Equations**"), 1);
    if isempty(i_start)
        return
    end
    sv_block = strings(0,1);
    l_math   = false;
    for i_line = i_start+1:numel(sv_line)
        s_line = sv_line(i_line);
        if l_math
            if strip(s_line) == "```"
                sv_math(end+1,1) = strjoin(sv_block, newline); %#ok<AGROW>
                l_math = false;
            else
                sv_block(end+1,1) = s_line; %#ok<AGROW>
            end
        elseif startsWith(s_line, "**") || contains(s_line, "<@Examples>")
            return
        elseif strip(s_line) == "```math"
            sv_block = strings(0,1);
            l_math   = true;
        end
    end
end
