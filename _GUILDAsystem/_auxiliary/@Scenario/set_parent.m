function set_parent(obj, net)
% Called by net.add_scenario / net.remove_scenario only ([] detaches).
    arguments (Input)
        obj
        net % Network the scenario belongs to, or [] to detach it.
    end
    obj.a_PowerNetwork = net;
end
