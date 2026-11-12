function validate(obj)
% Check every disturbance against the network of the scenario as it is now.
    arguments (Input)
        obj
    end
    for k = 1:height(obj.tab_disturbance)
        validate_disturbance(get_record(obj.tab_disturbance, k), obj.s_tag, obj.a_PowerNetwork);
    end
end
