function validate(obj, net)
% Check every disturbance against the network net as it is now.
    arguments (Input)
        obj
        net % Network to check against ([] checks only what needs no network).
    end
    for k = 1:height(obj.tab_disturbance)
        validate_disturbance(get_record(obj.tab_disturbance, k), obj.s_tag, net);
    end
end
