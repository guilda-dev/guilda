function s_tag = add_open_branch(obj, branch, time, opt)
% Add the opening of branches from t_start to t_end.
%
% The branches are left out of the bus admittance matrix and reconnected at t_end; a
% t_end at or after the end of the simulation keeps them open.
%
% <@Examples>
% ```matlab
% sc.add_open_branch(["EL003"; "EL004"], [0.17, 20]);   % open until the end
% ```
    arguments (Input)
        obj
        branch (:,1) string % Tags of the branches (see string(net.a_Branch)).
        time   (1,2) double % [s] [t_start, t_end] of the opening.
        opt.Tag (1,1) string = "" % Tag of the disturbance; default open<n>.
    end
    arguments (Output)
        s_tag (1,1) string % Tag of the added disturbance.
    end
    d = blank_record(opt.Tag, time);
    d.OpenBranch = branch;
    s_tag = obj.add_record(d, "open");
end
