function sct_page = gui_content(obj)
% Pages that the GUI (gui) shows after the Parameter tab; subclasses override it to add pages.
%
% Each element of the struct column is one tab:
%
% - `s_title`: tab name.
% - `s_type`: "latex", "ascii", "image", "table", "action" or "custom".
% - `content`: LaTeX string ("latex"), text ("ascii"), image file path ("image"), table
%   ("table"), `@() ...` run by the button ("action"; the GUI is drawn again afterwards)
%   or `@(h_container) ...` that draws into the tab ("custom").
% - `s_label`: text of the button of an "action" page; "" for the other types.
%
% The default returns one "image" page with the image.svg of the class folder, searched
% from the class of the model up through its superclasses; none when no folder has one.
% A subclass appends its pages to those of its superclass. Declare the override in the
% classdef as `methods(Access=protected) sct_page = gui_content(obj) end`.
%
% <@Examples>
% ```matlab
% function sct_page = gui_content(obj)
%     sct_page = gui_content@component.generator.abstract(obj);
%     sct_page(end+1,1) = struct("s_title","Equation", "s_type","latex", ...
%         "content","$M\ddot{\delta} = P_m - P_e$", "s_label","");
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
    % Breadth-first from the class of the model up through its superclasses.
    sv_class = string(class(obj));
    while ~isempty(sv_class)
        s_class = sv_class(1);
        sv_class(1) = [];
        s_folder = fileparts(which(s_class));
        [~, s_name] = fileparts(s_folder);
        s_image = fullfile(s_folder, "image.svg");
        if startsWith(s_name, "@") && isfile(s_image)
            sct_page(1,1) = struct("s_title","Image", "s_type","image", "content",string(s_image), "s_label","");
            return
        end
        mc = meta.class.fromName(s_class);
        if ~isempty(mc) && ~isempty(mc.SuperclassList)
            sv_class = [sv_class, string({mc.SuperclassList.Name})]; %#ok<AGROW>
        end
    end
end
