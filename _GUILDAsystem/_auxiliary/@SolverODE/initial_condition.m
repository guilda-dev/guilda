function [EM, RM, lv_FBorTC, x0, M0] = initial_condition(ctx, ph, x0, M0)
% The reduction of the DAE vector for a phase (without the elements of the faulted buses
% and of the tripped components, local controllers and global controllers) and the initial value and mass matrix of the phase. x0 and M0 are
% those at the end of the last phase ([] for the first one: x0 is then the initial value
% of the run, ctx.rv_x0, which holds the offsets and inputs of the first phase). The state
% offsets of the disturbances starting in a later phase are added to the states.
    arguments (Input)
        ctx  % Context of the run (build_index and the state of the phase).
        ph   % Data of the phase (an element of sct_event).
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
    n = ctx.n_z;
    lv_FBorTC = false(n, 1);
    for b = [ctx.c_comp(ph.iv_tripComp); ctx.c_lc(ph.iv_tripLC); ctx.c_gc(ph.iv_tripGC)].'
        lv_FBorTC([b{1}.iv_x; b{1}.iv_u]) = true;
    end
    for i = reshape(ph.iv_faultBus, 1, [])
        lv_FBorTC([ctx.iv_V(2*i-1 + (0:1)'); ctx.iv_I(2*i-1 + (0:1)')]) = true;
    end

    EM = speye(n);
    RM = speye(n);
    EM = EM(:, ~lv_FBorTC);
    RM = RM(~lv_FBorTC, :);

    if isempty(x0)
        x0 = ctx.rv_x0;
    end
    iv = ctx.iv_var(ph.iv_offset);     % the rows x of the map are the leading elements of z
    x0(iv) = x0(iv) + ph.rv_offset;
    x0 = RM * x0;

    if isempty(M0)
        M0 = ctx.rm_M;
    end
    M0 = RM * M0 * RM.';
end
