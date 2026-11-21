function ev = add_open_branch(obj, branch, time, opt)
% Add the opening of branches at time t.
%
% "6open" (the default) opens all circuits: the branch is left out of the bus admittance
% matrix. "3open" opens one circuit. The branches stay open until the end of the
% simulation. The opening is an EventOpenBranch with a new tag Parallel<n>, returned:
% change it with ev.edit and remove it with remove_event(ev.s_tag). It gives one row per
% branch in tab_event: (t, Status). A branch is opened by one parallel event at most.
% "3open" needs a branch of two or more circuits (GUILDA:Scenario:SingleCircuit). An
% opening may overlap a fault of the same branch: the two states give one matrix (see
% PowerNetwork.get_admittance_matrix), e.g. "3open" during a "3LG" fault opens the
% faulted circuit.
%
% <@Examples>
% ```matlab
% sc.add_open_branch(["EL003"; "EL004"], 0.17);   % open from t = 0.17 to the end
% sc.add_open_branch("EL005", 1, Status="3open");  % one circuit open from t = 1
% ```
    arguments (Input)
        obj
        branch (:,1) string  % Tags of the branches (see string(net.a_Branch)).
        time   (1,1) double  % [s] Time of the opening.
        opt.Status (1,1) string {mustBeMember(opt.Status, ["6open","3open"])} = "6open"  % All circuits or one circuit.
    end
    arguments (Output)
        ev EventOpenBranch  % The added event (a handle: edit it with ev.edit).
    end
    ev = EventOpenBranch(branch, time, Status=opt.Status);
    obj.insert_event(ev, false);
end
