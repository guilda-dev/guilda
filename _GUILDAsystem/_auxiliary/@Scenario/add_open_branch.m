function s_tag = add_open_branch(obj, branch, time, opt)
% Add the opening of branches from t_start to t_end.
%
% "6open" (the default) opens all circuits: the branch is left out of the bus admittance
% matrix. "3open" opens one circuit. The branches are reconnected at t_end; a t_end at or
% after the end of the simulation keeps them open. Two rows per branch are added to
% tab_event with one new tag Parallel<n>: (t_start, Status) and (t_end, "close").
% remove_disturbance(tag) removes them. Two parallel events of one branch may touch but
% not overlap. "3open" needs a branch of two or more circuits
% (GUILDA:Scenario:SingleCircuit).
%
% <@Examples>
% ```matlab
% sc.add_open_branch(["EL003"; "EL004"], [0.17, 20]);   % open until the end
% ```
    arguments (Input)
        obj
        branch (:,1) string % Tags of the branches (see string(net.a_Branch)).
        time   (1,2) double % [s] [t_start, t_end] of the opening.
        opt.Status (1,1) string {mustBeMember(opt.Status, ["6open","3open"])} = "6open" % All circuits or one circuit.
    end
    arguments (Output)
        s_tag (1,1) string % Tag of the added opening (Parallel<n>).
    end
    tab = new_event_rows(obj.tab_event, "Parallel", branch, time, [opt.Status, "close"], NaN);
    obj.add_events(tab);
    s_tag = tab.Tag(1);
end
