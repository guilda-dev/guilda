function sct_out = phase_result(ctx, ph, sct_sol)
% Trajectory of one phase: the variables x, V, u, uc in the order of the variable map, and
% the bus currents; the states of the tripped components and global controllers are NaN.
    arguments (Input)
        ctx      % Context of the run (Ymat of the phase).
        ph       % Data of the phase (an element of sct_event).
        sct_sol  % Solution of the phase (fields Time and Solution, full state vector).
    end
    arguments (Output)
        sct_out  % Trajectory of the phase (fields t, x (all variable rows of the map), i).
    end
    xsol = sct_sol.Solution;

    % States of the tripped components and global controllers (not of local controllers)
    c_unit = [ctx.c_comp(ph.iv_tripComp); ctx.c_gc(ph.iv_tripGC)];
    if ~isempty(c_unit)
        iv = tools.vcellfun(@(b) b.iv_x, c_unit);
        xsol(:, iv) = NaN;
    end

    Isol = ctx.Ymat * xsol(:, ctx.iv_V).';
    sct_out = struct('t', sct_sol.Time, 'x', xsol(:, ctx.iv_var), 'i', Isol.');
end
