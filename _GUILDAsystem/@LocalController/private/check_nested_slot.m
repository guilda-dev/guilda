function check_nested_slot(con, a_con)
% Stop unless a_con fits the nested slot of the controller (set.a_LocalController):
% empty, or one PSS under an AVR.
    arguments (Input)
        con
        a_con (:,1) cell  % New value of a_LocalController.
    end
    if isempty(a_con)
        return
    end
    sv_role = reshape(string(cellfun(@(c) char(c.s_role), a_con, 'UniformOutput', false)), [], 1);
    if ~(con.s_role == "avr" && isscalar(a_con) && sv_role == "pss")
        sv_tag = reshape(string(cellfun(@(c) char(c.s_tag), a_con, 'UniformOutput', false)), [], 1);
        error(msg("GUILDA:LocalController:NestedControllerSlot", char(con.s_tag), char(con.s_role), ...
                  char(join(sv_tag', ", ")), char(join(sv_role', ", "))))
    end
end
