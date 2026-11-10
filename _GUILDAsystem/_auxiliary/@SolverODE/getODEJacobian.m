function odeJac = getODEJacobian(ctx, t, x, RM, EM, lg)
% Method for obtaining the Jacobian of the DAE system under analysis.
%
% Same order as getODEFunction: the outputs of the components (their Jacobians are shared
% by the local and global controllers that read them), the global controllers, then each
% component with its local controllers, and the current balance of the buses.
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
    iv_V = ctx.iv_busV;
    odeV = x(ctx.rv_odeV);

    % 1. Outputs of the components read by a controller: values and Jacobians [Cyx, Dyv]
    c_unit = ctx.c_unit;
    y_all  = zeros(ctx.n_y, 1);
    c_Cy   = cell(numel(c_unit), 1);
    c_Dy   = cell(numel(c_unit), 1);
    for j = 1:numel(c_unit)
        unit = c_unit{j};
        if unit.l_y
            xj = x(unit.idx_X);
            Vj = x(unit.idx_V);
            ny = numel(unit.idx_Y);
            y_all(unit.idx_Y) = unit.comp.f_Y(t, xj, Vj);
            [Cyx, Dyv] = unit.comp.f_JacobiY(t, xj, Vj);
            if isempty(Cyx)      % a model may return [] for an all-zero block
                Cyx = zeros(ny, numel(xj));
            end
            if isempty(Dyv)
                Dyv = zeros(ny, 2);
            end
            c_Cy{j} = Cyx;
            c_Dy{j} = Dyv;
        end
    end

    % 2. Global controllers. du_GC/dz (Du): the outputs or states of their units
    for k = 1:numel(ctx.c_gc)
        sct_gc = ctx.c_gc{k};
        a_GC = sct_gc.gc;
        if ~a_GC.l_isConnect
            continue        % tripped: no output (see getODEFunction)
        end
        n_u = numel(sct_gc.lv_y);
        rv_c = repelem(cellfun(@(c) double(c.l_isConnect), a_GC.controlledUnits), numel(a_GC.sv_u), 1);
        u_GC = zeros(n_u, 1);
        u_GC(sct_gc.lv_y) = y_all(sct_gc.iv_y(sct_gc.lv_y));
        u_GC(sct_gc.lv_x) = x(sct_gc.iv_x(sct_gc.lv_x));
        u_GC = u_GC .* rv_c;
        Du = zeros(n_u, n);
        for m = reshape(find(sct_gc.lv_y), 1, [])
            j = sct_gc.iv_unit(m);
            r = a_GC.iv_obsY(m);
            Du(m, c_unit{j}.idx_X) = rv_c(m) * c_Cy{j}(r,:);
            Du(m, c_unit{j}.idx_V) = rv_c(m) * c_Dy{j}(r,:);
        end
        iv_m = find(sct_gc.lv_x);
        Du(sub2ind([n_u, n], iv_m, sct_gc.iv_x(iv_m))) = rv_c(iv_m);

        idx_X = a_GC.iv_odeX;
        x_GC  = x(idx_X);
        ny = numel(a_GC.sv_y) * numel(a_GC.controlledUnits);
        [Axx, Bxv, Bxu] = a_GC.f_JacobiDx(t, x_GC, odeV, u_GC);
        [Cyx, Dyv, Dyu] = a_GC.f_JacobiY(t, x_GC, odeV, u_GC);

        % Its states (a model may return [] for an all-zero block)
        G = zeros(ny, n);
        if ~isempty(idx_X)
            odeJac(idx_X, idx_X) = odeJac(idx_X, idx_X) + Axx;
            if ~isempty(Bxv)
                odeJac(idx_X, iv_V) = odeJac(idx_X, iv_V) + Bxv;
            end
            if ~isempty(Bxu)
                odeJac(idx_X, :) = odeJac(idx_X, :) + Bxu * Du;
            end
            if ~isempty(Cyx)
                G(:, idx_X) = Cyx;
            end
        end

        % The inputs it drives: residual u - (... + y_GC)
        if ~isempty(Dyu)
            G = G + Dyu * Du;
        end
        if ~isempty(Dyv)
            G(:, iv_V) = G(:, iv_V) + Dyv;
        end
        odeJac(sct_gc.iv_tgt, :) = odeJac(sct_gc.iv_tgt, :) - G(sct_gc.iv_src, :);
    end

    % 3. Each component with its local controllers
    for j = 1:numel(c_unit)
        cj = c_unit{j}.comp;

        idx_V = c_unit{j}.idx_V;
        idx_X = cj.iv_odeX;
        idx_U = cj.iv_odeU;

        Vi = x(idx_V);
        xi = x(idx_X);
        ui = x(idx_U);

        [Axx, Bxv, Bxu] = cj.f_JacobiDx(t,xi,Vi,ui);
        [Cix, Div, Diu] = cj.f_JacobiI(t,xi,Vi,ui);

        rh = [idx_X; idx_U; idx_V];
        rv = [idx_X; idx_V];

        % The local controllers of the component, depth first (e.g. an AVR,
        % its PSS, then a governor)
        c_LC = controllers_depth_first(cj);
        for k = 1:numel(c_LC)
            con = c_LC{k};

            % Inputs of the controller read on the component by name (iv_obsY:
            % its outputs, iv_obsX: its states)
            lv_Y = con.iv_obsY > 0;
            if any(lv_Y)
                iv_y = con.iv_obsY(lv_Y);
                odeJac(con.iv_odeU(lv_Y), [idx_X; idx_V]) = odeJac(con.iv_odeU(lv_Y), [idx_X; idx_V]) ...
                                              + [-c_Cy{j}(iv_y,:), -c_Dy{j}(iv_y,:)];
            end
            for m = reshape(find(con.iv_obsX > 0), 1, [])
                idx_m = con.iv_odeU(m);
                idx_x = idx_X(con.iv_obsX(m));
                odeJac(idx_m, idx_x) = odeJac(idx_m, idx_x) - 1;
            end

            idx_X_LC = con.iv_odeX;
            idx_U_LC = con.iv_odeU;
            idx_Y_LC = con.iv_odeY;

            xi_LC = x(idx_X_LC);
            ui_LC = x(idx_U_LC);

            [Axx_LC, Bxv_LC, Bxu_LC] = con.f_JacobiDx(t,xi_LC,Vi,ui_LC);
            [Cyx_LC, Dyv_LC, Dyu_LC] = con.f_JacobiY(t,xi_LC,Vi,ui_LC);

            % Its outputs drive the inputs of its parent (rows idx_Y_LC)
            rh_LC = [idx_X_LC; idx_U_LC; idx_V];
            rv_LC = [idx_X_LC; idx_Y_LC];

            odeJac(rv_LC, rh_LC) = odeJac(rv_LC, rh_LC) + [ Axx_LC,  Bxu_LC,  Bxv_LC; ...
                                                           -Cyx_LC, -Dyu_LC, -Dyv_LC];

            odeJac(idx_U_LC,idx_U_LC) = odeJac(idx_U_LC,idx_U_LC) + eye(length(idx_U_LC));
        end

        % A tripped unit gives no current (see get_dx_algebraic)
        l_c = double(cj.l_isConnect);
        odeJac(rv,rh) = odeJac(rv,rh) + [ Axx,  Bxu,  Bxv;...
                                         -l_c*Cix, -l_c*Diu, -l_c*Div];

        odeJac(idx_U,idx_U) = odeJac(idx_U,idx_U) + eye(length(idx_U));
    end

    % 4. Current balance of the buses
    rv_Bus_V = ctx.iv_busV;
    rv_Bus_I = ctx.iv_busI;
    odeJac(rv_Bus_I,rv_Bus_V) = odeJac(rv_Bus_I,rv_Bus_V) - ctx.Ymat;

    n_v = numel(rv_Bus_V);
    odeJac([rv_Bus_V; rv_Bus_I], rv_Bus_I) = odeJac([rv_Bus_V; rv_Bus_I], rv_Bus_I) + [eye(n_v); eye(n_v)];

    odeJac = odeJac(lg,lg);
    if ctx.l_sparse
        odeJac = sparse(odeJac);        % ode15s uses a sparse LU only if the mass matrix is sparse too
    end

end

