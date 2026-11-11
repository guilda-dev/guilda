function odeJac = getODEJacobian(ctx, t, x, RM, EM, lg)
% Method for obtaining the Jacobian of the DAE system under analysis.
%
% Same blocks as getODEFunction: for each component [Axx, Bxv, Bxu] in its state rows and
% -[Cix, Div, Diu] in the rows of its bus, for each controller [Axx, Bxv, Bxu]; the
% Jacobian Js of the signals ([Cyx, Dyv] of a component, [Cyx, Dyv, Dyu] of a controller)
% enters the input rows as I - S_var - S_sig*Js; then the current balance of the buses.
    arguments (Input)
        ctx                 % Context of the run.
        t    (1,1) double   % [s] Time from the start of the phase.
        x    (:,1) double   % Reduced state vector.
        RM                  %#ok<INUSA> Reduction matrix of the phase.
        EM                  %#ok<INUSA> Expansion matrix of the phase.
        lg   (:,1) logical  % True for the entries of the full state vector that are solved.
    end
    arguments (Output)
        odeJac  (:,:) double  % Jacobian of the reduced DAE (sparse when ctx.l_sparse).
    end

    x_lg = x;
    x = zeros(size(lg), 'like', x_lg);
    x(lg) = x_lg;

    n    = numel(x);
    odeJac = zeros(n, n);
    Js   = zeros(ctx.n_s, n);
    iv_V = ctx.iv_V;
    odeV = x(iv_V);

    % 1. Components (a model may return [] for an all-zero block)
    c_comp = ctx.c_comp;
    for j = 1:numel(c_comp)
        b  = c_comp{j};
        xj = x(b.iv_x);
        Vj = x(b.iv_V);
        uj = x(b.iv_u);
        nx = numel(xj);
        nu = numel(uj);
        [Axx, Bxv, Bxu] = b.f_JacobiDx(t, xj, Vj, uj);
        odeJac(b.iv_x, [b.iv_x; b.iv_V; b.iv_u]) = [blk(Axx,nx,nx), blk(Bxv,nx,2), blk(Bxu,nx,nu)];
        if ctx.lv_compOn(j)                % a tripped unit gives no current
            [Cix, Div, Diu] = b.f_JacobiI(t, xj, Vj, uj);
            rh = [b.iv_x; b.iv_V; b.iv_u];
            odeJac(b.iv_V, rh) = odeJac(b.iv_V, rh) - [blk(Cix,2,nx), blk(Div,2,2), blk(Diu,2,nu)];
        end
        if b.l_y
            ny = numel(b.iv_s);
            [Cyx, Dyv] = b.f_JacobiY(t, xj, Vj);
            Js(b.iv_s, [b.iv_x; b.iv_V]) = [blk(Cyx,ny,nx), blk(Dyv,ny,2)];
        end
    end

    % 2. Local controllers
    c_lc = ctx.c_lc;
    for k = 1:numel(c_lc)
        b  = c_lc{k};
        xk = x(b.iv_x);
        Vk = x(b.iv_V);
        uk = x(b.iv_u);
        nx = numel(xk);
        nu = numel(uk);
        ny = numel(b.iv_s);
        rh = [b.iv_x; b.iv_V; b.iv_u];
        [Axx, Bxv, Bxu] = b.f_JacobiDx(t, xk, Vk, uk);
        [Cyx, Dyv, Dyu] = b.f_JacobiY(t, xk, Vk, uk);
        odeJac(b.iv_x, rh) = [blk(Axx,nx,nx), blk(Bxv,nx,2), blk(Bxu,nx,nu)];
        Js(b.iv_s, rh)     = [blk(Cyx,ny,nx), blk(Dyv,ny,2), blk(Dyu,ny,nu)];
    end

    % 3. Global controllers (a tripped one gives no output)
    c_gc = ctx.c_gc;
    nv = numel(iv_V);
    for k = 1:numel(c_gc)
        if ~ctx.lv_gcOn(k)
            continue
        end
        b  = c_gc{k};
        xk = x(b.iv_x);
        uk = x(b.iv_u);
        nx = numel(xk);
        nu = numel(uk);
        ny = numel(b.iv_s);
        rh = [b.iv_x; iv_V; b.iv_u];
        [Axx, Bxv, Bxu] = b.f_JacobiDx(t, xk, odeV, uk);
        [Cyx, Dyv, Dyu] = b.f_JacobiY(t, xk, odeV, uk);
        odeJac(b.iv_x, rh) = [blk(Axx,nx,nx), blk(Bxv,nx,nv), blk(Bxu,nx,nu)];
        Js(b.iv_s, rh)     = [blk(Cyx,ny,nx), blk(Dyv,ny,nv), blk(Dyu,ny,nu)];
    end

    % 4. Inputs: u - (e + S_sig*s + S_var*z)
    iv_in = ctx.iv_in;
    odeJac(iv_in, :) = odeJac(iv_in, :) - full(ctx.S_var) - ctx.S_sig*Js;
    odeJac(sub2ind([n, n], iv_in, iv_in)) = odeJac(sub2ind([n, n], iv_in, iv_in)) + 1;

    % 5. Current balance of the buses
    iv_I = ctx.iv_I;
    odeJac(iv_I, iv_V) = odeJac(iv_I, iv_V) - ctx.Ymat;
    n_v = numel(iv_V);
    odeJac([iv_V; iv_I], iv_I) = odeJac([iv_V; iv_I], iv_I) + [eye(n_v); eye(n_v)];

    odeJac = odeJac(lg,lg);
    if ctx.l_sparse
        odeJac = sparse(odeJac);        % ode15s uses a sparse LU only if the mass matrix is sparse too
    end

end


function M = blk(M, nr, nc)
    % A block of the size nr x nc (a model may return [] for an all-zero block)
    if isempty(M)
        M = zeros(nr, nc);
    else
        M = full(reshape(M, nr, nc));
    end
end
