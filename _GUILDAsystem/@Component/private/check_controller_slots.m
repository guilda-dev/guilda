function check_controller_slots(comp, a_con)
% Stop unless a_con fits the slots of the top-level local controllers (set.a_LocalController):
% at most one "avr" or "local" controller, then at most one "governor", in this order.
% A PSS goes under the AVR (LocalController.a_LocalController), never at the top.
    arguments (Input)
        comp
        a_con (:,1) cell  % New value of a_LocalController.
    end
    sv_role = string(cellfun(@(c) char(c.s_role), a_con, 'UniformOutput', false));
    sv_role = reshape(sv_role, [], 1);
    l_ok = numel(a_con) <= 2 && all(ismember(sv_role, ["avr","local","governor"]));
    if l_ok && numel(a_con) == 2
        l_ok = ismember(sv_role(1), ["avr","local"]) && sv_role(2) == "governor";
    end
    if ~l_ok
        sv_tag = string(cellfun(@(c) char(c.s_tag), a_con, 'UniformOutput', false));
        error(msg("GUILDA:Component:ControllerSlots", char(comp.s_tag), ...
                  char(join(reshape(sv_tag,1,[]), ", ")), char(join(reshape(sv_role,1,[]), ", "))))
    end
end
