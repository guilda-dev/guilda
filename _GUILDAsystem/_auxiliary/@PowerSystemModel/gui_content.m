function sct_page = gui_content(obj)
% Pages that the GUI (gui) shows after the Parameter tab; none by default.
%
% Each element of the struct column is one tab, drawn as a read-only table:
%
% - `s_title`: tab name.
% - `s_type`: "table", the only page type.
% - `content`: the table.
%
% The pages are defined in the abstract classes PowerNetwork, Bus, Branch, Component,
% LocalController and GlobalController (Summary, Equilibrium); a model class needs no
% override. An override puts its own pages first, followed by those of its superclass;
% declare it in the classdef as `methods(Access=protected) sct_page = gui_content(obj) end`.
% The meaning of the parameters and the model is in the class reference, opened by the
% Docs button of the GUI.
%
% <@Examples>
% ```matlab
% function sct_page = gui_content(obj)
%     sct_page = struct("s_title","Summary", "s_type","table", "content",table(["a";"b"], [1;2]));
%     sct_page = [sct_page; gui_content@PowerSystemModel(obj)];
% end
% ```
    arguments (Input)
        obj
    end
    arguments (Output)
        sct_page (:,1) struct  % Pages: fields s_title, s_type and content.
    end
    sct_page = repmat(struct("s_title","", "s_type","", "content",[]), 0, 1);
end
