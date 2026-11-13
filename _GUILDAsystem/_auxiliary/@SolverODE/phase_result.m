function sct_out = phase_result(ctx, ph, sct_sol)
% Trajectory of one phase: the variables x, V, u, uc in the order of the variable map, the
% bus currents and the current of each component; the states of the tripped components,
% local controllers and global controllers are NaN. The current of a component is its f_I
% at each output time (t from the start of the phase, as the solver), NaN while it is
% tripped; it is evaluated here, over the output times, and not in the right-hand side.
    arguments (Input)
        ctx      % Context of the run (Ymat of the phase).
        ph       % Data of the phase (an element of sct_event).
        sct_sol  % Solution of the phase (fields Time and Solution, full state vector).
    end
    arguments (Output)
        sct_out  % Trajectory of the phase (fields t, x (all variable rows of the map), i, ic (Ire, Iim of each component in the order of ctx.c_comp)).
    end
    xsol = sct_sol.Solution;

    % States of the tripped components, local controllers and global controllers
    c_unit = [ctx.c_comp(ph.iv_tripComp); ctx.c_lc(ph.iv_tripLC); ctx.c_gc(ph.iv_tripGC)];
    if ~isempty(c_unit)
        iv = tools.vcellfun(@(b) b.iv_x, c_unit);
        xsol(:, iv) = NaN;
    end

    Isol = ctx.Ymat * xsol(:, ctx.iv_V).';

    % Current of each component into its bus (NaN while tripped)
    rv_tp = sct_sol.Time(:) - ph.t1;
    n_t   = numel(rv_tp);
    n_c   = numel(ctx.c_comp);
    rm_Ic = NaN(n_t, 2*n_c);
    lv_on = true(n_c, 1);
    lv_on(ph.iv_tripComp) = false;
    for j = find(lv_on).'
        b  = ctx.c_comp{j};
        Xj = xsol(:, b.iv_x).';
        Vj = xsol(:, b.iv_V).';
        Uj = xsol(:, b.iv_u).';
        cv = zeros(n_t, 1);
        for k = 1:n_t
            cv(k) = b.f_I(rv_tp(k), Xj(:,k), Vj(:,k), Uj(:,k));
        end
        rm_Ic(:, 2*j - 1 + (0:1)) = [real(cv), imag(cv)];
    end
    sct_out = struct('t', sct_sol.Time, 'x', xsol(:, ctx.iv_var), 'i', Isol.', 'ic', rm_Ic);
end
