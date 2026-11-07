function sct_page = gui_content(obj)
% Pages of the GUI of a branch: "Equilibrium", then the pages of PowerSystemModel.
%
% "Equilibrium" ("table") has one row per end (from, to) and the columns Bus (tag of the
% end bus), V (`cv_Vequilibrium`) and I (`cv_Iequilibrium`). The table has no rows when
% the branch has no end buses (removed from the network).
%
% See also PowerSystemModel.gui, PowerSystemModel.gui_content
    arguments (Input)
        obj
    end
    arguments (Output)
        sct_page (:,1) struct  % Pages: fields s_title, s_type and content.
    end
    if isempty(obj.a_Bus)
        tab_equilibrium = table(strings(0,1), zeros(0,1), zeros(0,1), 'VariableNames', ["Bus","V","I"]);
    else
        tab_equilibrium = table(string(cellfun(@(b) b.s_tag, obj.a_Bus, "UniformOutput", false)), ...
            obj.cv_Vequilibrium, obj.cv_Iequilibrium, 'VariableNames', ["Bus","V","I"], ...
            'RowNames', ["from","to"]);
    end
    sct_page = [struct("s_title","Equilibrium", "s_type","table", "content",tab_equilibrium); ...
        gui_content@PowerSystemModel(obj)];
end
