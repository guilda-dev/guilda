function apply_edit(obj, sct)
% Set the properties of sct, check the scenario of the event, and undo them on an error.
%
% The common part of the edit methods: the old values of the fields of sct are kept, the
% new ones set, and Scenario.validate checks all the events of the scenario (with their
% tags) against its network. When a check fails, the old values are set back and the
% error is thrown. An event not in a scenario is not checked here.
    arguments (Input)
        obj
        sct (1,1) struct  % New values by property name.
    end
    sv_name = string(fieldnames(sct)).';
    sct_old = struct();
    for s_name = sv_name
        sct_old.(s_name) = obj.(s_name);
        obj.(s_name) = sct.(s_name);
    end
    if isempty(obj.a_Scenario) || ~isvalid(obj.a_Scenario)
        return
    end
    try
        obj.a_Scenario.validate();
    catch ME
        for s_name = sv_name
            obj.(s_name) = sct_old.(s_name);
        end
        rethrow(ME)
    end
end
