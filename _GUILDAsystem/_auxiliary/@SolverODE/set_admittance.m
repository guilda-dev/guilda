function ctx = set_admittance(ctx, sv_open, l_force)
% ctx.Ymat (real 2n x 2n, I = Y*V) and ctx.absYmat with the branches sv_open
% left out of the bus admittance matrix. Rebuilt only when the set changes.
    arguments (Input)
        ctx                     % Context of the run.
        sv_open                 % Tags of the open branches.
        l_force  (1,1) logical  % True to rebuild even when the set is unchanged.
    end
    arguments (Output)
        ctx  % Context with Ymat, absYmat and sv_open updated.
    end
    sv_open = reshape(sv_open, [], 1);
    if ~l_force && isequal(sv_open, ctx.sv_open)
        return
    end
    Yc = ctx.Ybus;
    if ~isempty(sv_open)
        a_br  = ctx.net.a_Branch(ismember(string(ctx.net.a_Branch), sv_open));
        sv_bus = string(ctx.net.a_Bus);
        for k = 1:numel(a_br)
            [~, iv] = ismember(string(a_br{k}.a_Bus), sv_bus);
            Yc(iv,iv) = Yc(iv,iv) - a_br{k}.get_admittance_matrix();
        end
    end
    ctx.Ymat = tools.complex2matrix(Yc);
    if ctx.l_sparse
        ctx.Ymat = sparse(ctx.Ymat);
    end
    ctx.absYmat = abs(ctx.Ymat);      % scale of the terms of I = Y*V (see getODEFunction)
    ctx.sv_open = sv_open;
end
