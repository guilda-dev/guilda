function sct_page = gui_content(obj)
% Pages of the GUI of a network: "Summary" and "Equilibrium", then the pages of PowerSystemModel.
%
% - "Summary" ("table"): the numbers of buses, branches, components (over all buses) and
%   global controllers.
% - "Equilibrium" ("table"): one row per bus with the columns Tag, Type (`s_bustype`),
%   V (`cv_Vequilibrium`), |V|, ∠V [rad] and I (`cv_Iequilibrium`).
%
% See also PowerSystemModel.gui, PowerSystemModel.gui_content
    arguments (Input)
        obj
    end
    arguments (Output)
        sct_page (:,1) struct  % Pages: fields s_title, s_type, content, s_label.
    end
    Item   = ["Bus"; "Branch"; "Component"; "GlobalController"];
    Number = [numel(obj.a_Bus); numel(obj.a_Branch); ...
        sum(cellfun(@(b) numel(b.a_Component), obj.a_Bus)); numel(obj.a_GlobalController)];
    cv_V = obj.cv_Vequilibrium;
    tab_equilibrium = table( ...
        string(cellfun(@(b) b.s_tag, obj.a_Bus, "UniformOutput", false)), ...
        string(cellfun(@(b) b.s_bustype, obj.a_Bus, "UniformOutput", false)), ...
        cv_V, abs(cv_V), angle(cv_V), obj.cv_Iequilibrium, ...
        'VariableNames', ["Tag","Type","V","|V|","∠V [rad]","I"]);
    sct_page = [struct("s_title","Summary", "s_type","table", "content",table(Item, Number), "s_label",""); ...
        struct("s_title","Equilibrium", "s_type","table", "content",tab_equilibrium, "s_label",""); ...
        gui_content@PowerSystemModel(obj)];
end
