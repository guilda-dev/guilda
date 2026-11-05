function sc = copy(obj)
% Return an unattached duplicate of the scenario.
%
% The duplicate has the same tag, disturbances, Time, Options, Judge and
% Description, and no network: add it to another network with net.add_scenario.
    arguments (Input)
        obj
    end
    arguments (Output)
        sc % New Scenario, not attached to a network.
    end
    sc = Scenario(obj.s_tag, Time=obj.Time, Options=obj.Options, Judge=obj.Judge, ...
                  Description=obj.Description);
    sc.tab_disturbance = obj.tab_disturbance;
end
