function ctx = set_admittance(ctx, i_Y, l_force)
% ctx.Ymat (real 2n x 2n, I = Y*V) and ctx.absYmat from the admittance matrix c_Y{i_Y} of
% the run (build_simulation_data made one per set of branch states). Rebuilt only when
% i_Y changes.
    arguments (Input)
        ctx                     % Context of the run (c_Y, i_Y).
        i_Y      (1,1) double   % Position of the matrix of the phase in ctx.c_Y.
        l_force  (1,1) logical  % True to rebuild even when i_Y is unchanged.
    end
    arguments (Output)
        ctx  % Context with Ymat, absYmat and i_Y updated.
    end
    if ~l_force && i_Y == ctx.i_Y
        return
    end
    ctx.Ymat = tools.complex2matrix(ctx.c_Y{i_Y});
    if ctx.l_sparse
        ctx.Ymat = sparse(ctx.Ymat);
    end
    ctx.absYmat = abs(ctx.Ymat);      % scale of the terms of I = Y*V (see getODEFunction)
    ctx.i_Y = i_Y;
end
