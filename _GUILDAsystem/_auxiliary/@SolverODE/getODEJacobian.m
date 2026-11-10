function odeJac = getODEJacobian(ctx, t, x, RM, EM, lg)
% Method for obtaining the Jacobian of the DAE system under analysis.
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

    a_bus = ctx.net.a_Bus;

    odeJac = zeros(numel(x), numel(x));

    rv_Bus_V = zeros(0,1);
    rv_Bus_I = zeros(0,1);

    a_GCs = ctx.net.a_GlobalController;
    for k = 1:numel(a_GCs)
        a_GC = a_GCs{k};
        if ~a_GC.l_isConnect
            continue        % tripped: no output (see getODEFunction)
        end

        lh_GC = [a_GC.iv_odeX; a_GC.iv_odeU];
        lv_GC = [a_GC.iv_odeX; a_GC.iv_odeY];

        x_GC = x(a_GC.iv_odeX);
        u_GC = x(a_GC.iv_odeU);

        [Axx_GC, ~, Bxu_GC] = a_GC.f_JacobiDx(t,x_GC,[],u_GC);
        [Cyx_GC, ~, Dyu_GC] = a_GC.f_JacobiY(t,x_GC,[],u_GC);

        odeJac(lv_GC, lh_GC) = odeJac(lv_GC, lh_GC) + [  Axx_GC,   Bxu_GC;
                                                        -Cyx_GC,  -Dyu_GC];

    end

    for i=1:numel(a_bus)
        cm = a_bus{i}.a_Component;

        idx_V = a_bus{i}.iv_odeX;
        idx_I = a_bus{i}.iv_odeI;

        Vi = x(idx_V);

        for j=1:numel(cm)
            cj = cm{j};

            idx_X = cj.iv_odeX;
            idx_U = cj.iv_odeU;

            xi = x(idx_X);
            ui = x(idx_U);

            [Axx, Bxv, Bxu] = cj.f_JacobiDx(t,xi,Vi,ui);
            [Cix, Div, Diu] = cj.f_JacobiI(t,xi,Vi,ui);

            rh = [idx_X; idx_U; idx_V];
            rv = [idx_X; idx_V];

            % Outputs of the component (no input feedthrough), read by its controllers
            if cj.l_hasController
                [Cyx, Dyv] = cj.f_JacobiY(t,xi,Vi);
            end

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
                                                  + [-Cyx(iv_y,:), -Dyv(iv_y,:)];
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

        rv_Bus_V(2*i+[-1;0]) = idx_V;
        rv_Bus_I(2*i+[-1;0]) = idx_I;
    end

    odeJac(rv_Bus_I,rv_Bus_V) = odeJac(rv_Bus_I,rv_Bus_V) - ctx.Ymat;

    odeJac([rv_Bus_V; rv_Bus_I], rv_Bus_I) = odeJac([rv_Bus_V; rv_Bus_I], rv_Bus_I) + [eye(2*i); eye(2*i)];

    odeJac = odeJac(lg,lg);
    if ctx.l_sparse
        odeJac = sparse(odeJac);        % ode15s uses a sparse LU only if the mass matrix is sparse too
    end

end
