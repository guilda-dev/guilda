function ctx = set_admittance(ctx, iv_open, l_force)
% ctx.Ymat (real 2n x 2n, I = Y*V) and ctx.absYmat with the branches iv_open left out of
% the bus admittance matrix: the 2x2 matrix of each is subtracted at its buses. Rebuilt
% only when the set changes.
    arguments (Input)
        ctx                     % Context of the run (cm_Y, im_branchBus, c_branchY).
        iv_open  (:,1) double   % Positions of the open branches (ascending).
        l_force  (1,1) logical  % True to rebuild even when the set is unchanged.
    end
    arguments (Output)
        ctx  % Context with Ymat, absYmat and iv_open updated.
    end
    if ~l_force && isequal(iv_open, ctx.iv_open)
        return
    end
    Yc = ctx.cm_Y;
    for k = reshape(iv_open, 1, [])
        iv = ctx.im_branchBus(k,:);
        Yc(iv,iv) = Yc(iv,iv) - ctx.c_branchY{k};
    end
    ctx.Ymat = tools.complex2matrix(Yc);
    if ctx.l_sparse
        ctx.Ymat = sparse(ctx.Ymat);
    end
    ctx.absYmat = abs(ctx.Ymat);      % scale of the terms of I = Y*V (see getODEFunction)
    ctx.iv_open = iv_open;
end
