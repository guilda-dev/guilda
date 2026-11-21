function s_expr = model_expression(obj, a_model, a_chain)
% MATLAB expression of a model from the root variable of the history, e.g. "net.a_Bus{3}.a_Component{1}".
%
% Each step from the root is the list of the parent that holds the model (a_Bus, a_Branch,
% a_GlobalController, a_Scenario, a_Component or a_LocalController) and its index there.
% A model whose root is not the root variable of the history has no expression (an error).
% The models from the root to a_model (a_chain, as render finds them) save reading the
% parents again.
    arguments (Input)
        obj       % The GUI.
        a_model   % Model in the tree of the root.
        a_chain cell = {}  % Models from the root to a_model ({}: read through the parents).
    end
    arguments (Output)
        s_expr (1,1) string  % Expression, e.g. "net.a_Bus{3}".
    end
    if isempty(a_chain)
        a_chain = {a_model};
        a_parent = obj.f_model(a_model).parent;
        while true
            if iscell(a_parent)
                a_parent = [a_parent{:}];
            end
            if isempty(a_parent)
                break
            end
            a_chain = [{a_parent}, a_chain]; %#ok<AGROW>
            a_parent = obj.f_model(a_parent).parent;
        end
    end
    % The root: it must be the root variable of the history
    a_root = a_chain{1};
    a_variable = obj.history.get_variable(obj.s_root);
    if ~(isa(a_variable, "handle") && isscalar(a_variable) && isa(a_root, class(a_variable)) && a_variable == a_root)
        error(msg("GUILDA:DrawerModelGUI:OtherRoot", obj.s_root, string(a_root.s_tag)))
    end
    sv_list = ["a_Bus", "a_Branch", "a_GlobalController", "a_Scenario", "a_Component", "a_LocalController"];
    sv_kind = ["Bus",   "Branch",   "GlobalController",   "Scenario",   "Component",   "LocalController"];
    s_expr = obj.s_root;
    for k = 2:numel(a_chain)
        a_parent = a_chain{k-1};
        a_child  = a_chain{k};
        s_list = sv_list(arrayfun(@(s) isa(a_child, s), sv_kind));
        i_child = [];
        if isscalar(s_list) && isprop(a_parent, s_list)
            i_child = find(cellfun(@(c) isa(c, class(a_child)) && c == a_child, a_parent.(s_list)), 1);
        end
        if isempty(i_child)
            error(msg("GUILDA:DrawerModelGUI:NotInTree", string(a_child.s_tag)))
        end
        s_expr = s_expr + "." + s_list + "{" + i_child + "}";
    end
end
