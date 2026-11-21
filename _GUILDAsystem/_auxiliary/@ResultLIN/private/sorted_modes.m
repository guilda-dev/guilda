function sct = sorted_modes(obj, s_type, k)
% Modes of section k of the model s_type, as in get_mode: tools.linear_modes sorted by the
% real part (largest first), with the mode shapes normalized (get_mode, get_participation)
    arguments (Input)
        obj    ResultLIN         % The result.
        s_type (1,1) string      % Type of the model: "ODE" or "DAE".
        k      (1,1) double      % Section.
    end
    arguments (Output)
        sct struct  % lambda, frequency, zeta, l_osc, owner (modes), rm_participation, cm_shape (states x modes), sv_state, sv_owner (states).
    end
    sys = obj.get_ss(s_type, Index=k, Format="struct");
    sv_state = sys.StateName;
    sv_owner = state_owner(obj, sv_state);
    sct_m = tools.linear_modes(sys.A, sys.E, sv_owner);
    [~, iv] = sort(real(sct_m.lambda), "descend");
    cm_shape = sct_m.V(:, iv);
    [~, iv_max] = max(abs(cm_shape), [], 1);
    cm_shape = cm_shape ./ cm_shape(sub2ind(size(cm_shape), iv_max, 1:numel(iv)));
    sct = struct("lambda", sct_m.lambda(iv), "frequency", sct_m.frequency(iv), "zeta", sct_m.zeta(iv), ...
        "l_osc", sct_m.l_osc(iv), "owner", sct_m.owner(iv), "rm_participation", sct_m.rm_participation(:, iv), ...
        "cm_shape", cm_shape, "sv_state", sv_state, "sv_owner", sv_owner);
end
