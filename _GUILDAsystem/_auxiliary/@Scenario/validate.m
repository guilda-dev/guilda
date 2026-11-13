function validate(obj)
% Check every disturbance against the network of the scenario as it is now.
    arguments (Input)
        obj
    end
    validate_events(obj.tab_event, obj.s_tag, obj.a_PowerNetwork);
    for c_tab = {obj.tab_offset, obj.tab_input}
        for k = 1:height(c_tab{1})
            validate_disturbance(get_record(c_tab{1}, k), obj.s_tag, obj.a_PowerNetwork);
        end
    end
end
