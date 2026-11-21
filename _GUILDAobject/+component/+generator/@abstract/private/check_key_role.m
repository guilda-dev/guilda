function check_key_role(gen, Key, s_role, s_method)
% Stop when the class of the model key does not have the role s_role (set_avr, set_pss, set_governor)
    s_class = GUILDA.keymap("LocalController");
    s_class = s_class(string(Key));
    mc = meta.class.fromName(s_class);
    p  = mc.PropertyList(string({mc.PropertyList.Name}) == "s_role");
    s_key_role = string(p.DefaultValue);
    if s_key_role ~= s_role
        error(msg("GUILDA:Component:ControllerRoleMismatch", char(s_method), char(Key), char(s_key_role), char(gen.s_tag), char(s_role)))
    end
end
