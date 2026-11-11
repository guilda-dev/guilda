function sct_out = phase_result(ctx, ph, sct_sol)
% Trajectory of one phase for ResultODE: the variables x, V, u in the order of the variable
% map (ctx.iv_lin), and the bus currents; the states of the tripped units are NaN.
    arguments (Input)
        ctx      % Context of the run (Ymat of the phase).
        ph       % Data of the phase (an element of the output of Scenario.compile).
        sct_sol  % Solution of the phase (fields Time and Solution, full state vector).
    end
    arguments (Output)
        sct_out  % Trajectory of the phase (fields t, x, i).
    end
    xsol = sct_sol.Solution;

    % States of the tripped components and global controllers (not of local controllers)
    sv_trip = reshape(string(ph.sv_trip), [], 1);
    if ~isempty(sv_trip)
        c_unit = [ctx.c_comp; ctx.c_gc];
        lv = cellfun(@(b) ismember(b.s_tag, sv_trip), c_unit);
        iv = tools.vcellfun(@(b) b.iv_x, c_unit(lv));
        xsol(:, iv) = NaN;
    end

    Isol = ctx.Ymat * xsol(:, ctx.iv_V).';
    sct_out = struct('t', sct_sol.Time, 'x', xsol(:, ctx.iv_lin), 'i', Isol.');
end
