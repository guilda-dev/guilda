function sv_owner = state_owner(obj, sv_state)
% Owner of each state of a model of the result: tab_variable.Owner by Label; a bus variable
% of the "DAE" (after the dynamic states, all buses for the first variable, then for the
% second) is owned by its bus
    arguments (Input)
        obj      ResultLIN        % The result.
        sv_state (:,1) string     % StateName of the model.
    end
    arguments (Output)
        sv_owner (:,1) string     % Tag of the owner of each state.
    end
    tab = obj.tab_variable;
    [lv_known, iv_row] = ismember(sv_state, tab.Label);
    sv_owner = strings(numel(sv_state), 1);
    sv_owner(lv_known) = tab.Owner(iv_row(lv_known));
    sv_bus = tab.Bus(tab.Kind == "Vre");
    iv_bus = find(~lv_known);
    if ~isempty(sv_bus) && ~isempty(iv_bus)
        sv_owner(iv_bus) = sv_bus(mod((1:numel(iv_bus)) - 1, numel(sv_bus)) + 1);
    end
end
