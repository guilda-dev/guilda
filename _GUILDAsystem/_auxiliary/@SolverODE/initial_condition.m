function [EM, RM, lv_FBorTC, x0, M0] = initial_condition(ctx, ph, x0, M0)
% The reduction of the DAE vector for a phase (without the elements of the faulted buses
% and tripped units) and the initial value and mass matrix of the phase. x0 and M0 are
% those at the end of the last phase ([] for the first one). The state offsets of the
% disturbances starting in the phase are added to the states of the components; in the
% first phase the inputs start at their equilibrium with the input events at t = 0.
    arguments (Input)
        ctx  % Context of the run (build_index and the state of the phase).
        ph   % Data of the phase (an element of the output of Scenario.compile).
        x0   % Initial value at the end of the last phase, or [] for the first phase.
        M0   % Mass matrix at the end of the last phase, or [] for the first phase.
    end
    arguments (Output)
        EM         % Expansion matrix from the reduced to the full state vector.
        RM         % Reduction matrix from the full to the reduced state vector.
        lv_FBorTC  % True for the entries of the faulted buses and tripped units.
        x0         % Initial value of the reduced state vector.
        M0         % Mass matrix of the reduced state vector.
    end
    lv_FBorTC = ismember(ctx.sv_owner, [reshape(string(ph.sv_trip), [], 1); reshape(string(ph.sv_fault), [], 1)]);

    n  = numel(lv_FBorTC);
    EM = speye(n);
    RM = speye(n);
    EM = EM(:, ~lv_FBorTC);
    RM = RM(~lv_FBorTC, :);

    l_first = isempty(x0);
    if l_first
        x0 = ctx.rv_z0;
    end
    c_comp = ctx.c_comp;
    for j = 1:numel(c_comp)
        idx = c_comp{j}.iv_x;
        x0(idx) = x0(idx) + ph.c_Xoffset{j};
        if l_first && ~isempty(ph.c_Uoffset{j})     % empty without an input (see Scenario.compile)
            idx = c_comp{j}.iv_u;
            x0(idx) = x0(idx) + ph.c_Uoffset{j}(0);
        end
    end
    x0 = RM * x0;

    if isempty(M0)
        M0 = ctx.rm_M;
    end
    M0 = RM * M0 * RM.';
end
