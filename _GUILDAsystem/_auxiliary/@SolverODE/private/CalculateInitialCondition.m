function [x0, xp0, l_failed, str_why, me_why] = CalculateInitialCondition(o, options)
% Consistent initial condition of a phase, for the ode object o.
% The differential states (the variables that the mass matrix multiplies) keep the values
% of o.InitialValue exactly: they are continuous at an event, and an offset event has already
% been added to them. Only the algebraic variables are solved, from the algebraic equations
% (the zero rows of the mass matrix) for the network of the phase, by Newton's method with the
% analytic Jacobian and the values of o.InitialValue as the start. xp0 is the slope of both.
% decic and the consistency step of the solver are not used: they may move the differential
% states (decic when it cannot keep them, the solver for a sparse mass matrix that is not
% diagonal).
% l_failed: no algebraic variables satisfy the equations (x0, xp0 are empty). str_why: the
% reason. me_why: the error when l_failed.

    M  = o.MassMatrix.MassMatrix;
    x0 = o.InitialValue;
    n  = numel(x0);

    xp0 = zeros(0,1);
    l_failed = false;
    str_why  = "";
    me_why   = [];

    lv_alg = reshape(full(all(M == 0, 1)), [], 1);     % variables without derivative
    lv_eqA = full(all(M == 0, 2));                     % algebraic equations
    if nnz(lv_alg) ~= nnz(lv_eqA)
        [x0, l_failed, str_why, me_why] = fail(sprintf(['The mass matrix has %d zero rows and %d zero columns, ' ...
            'so the algebraic variables cannot be solved from the algebraic equations.'], nnz(lv_eqA), nnz(lv_alg)));
        return
    end

    % Newton's method on the algebraic variables, with a line search on the residual
    rtol = options.RelTol;
    atol = max(options.AbsTol);
    w = warning("off", "MATLAB:singularMatrix");
    w(2) = warning("off", "MATLAB:nearlySingularMatrix");
    c_warn = onCleanup(@() warning(w));
    f = o.ODEFcn(0, x0);
    g = f(lv_eqA);
    l_done = isempty(g);
    max_iter = 50;
    for k = 1:max_iter
        if l_done
            break
        end
        if ~all(isfinite(f))
            break
        end
        J  = o.Jacobian.Jacobian(0, x0);
        dy = -(J(lv_eqA, lv_alg) \ g);
        if ~all(isfinite(dy))
            break
        end
        y = x0(lv_alg);
        x_new = x0;
        for probe = 1:10
            x_new(lv_alg) = y + dy;
            f_new = o.ODEFcn(0, x_new);
            if norm(f_new(lv_eqA)) < norm(g) || norm(dy, inf) <= 1e-3*(rtol*norm(y, inf) + atol)
                break
            end
            dy = dy/2;
        end
        x0 = x_new;
        f  = f_new;
        g  = f(lv_eqA);
        % Converged after a full step far below the accuracy of the solver: the error left is
        % of the order of its square
        l_done = probe == 1 && norm(dy, inf) <= 1e-3*(rtol*norm(y, inf) + atol);
    end
    if ~l_done || ~all(isfinite(f))
        [x0, l_failed, str_why, me_why] = fail(sprintf(['The algebraic equations could not be satisfied at the start of the phase ' ...
            'with the differential states kept (largest residual %g after %d Newton iterations). ' ...
            'A common reason is a constant-power load ("load-power") that the network cannot supply ' ...
            'at the voltages of the phase, e.g. during a fault on or next to the bus that feeds it. ' ...
            'Use "load-impedance" for such a load or fault another bus.'], norm(g, inf), k));
        return
    end

    % Slope: the differential equations give that of the differential states, and the
    % derivative of the algebraic equations, g_x*xp + g_y*yp = 0, that of the algebraic ones
    xp0 = zeros(n, 1);
    lv_dif = ~lv_alg;
    if any(lv_dif)
        xp0(lv_dif) = M(~lv_eqA, lv_dif) \ f(~lv_eqA);
    end
    if any(lv_alg) && any(lv_dif)
        J = o.Jacobian.Jacobian(0, x0);
        xp0(lv_alg) = -(J(lv_eqA, lv_alg) \ (J(lv_eqA, lv_dif)*xp0(lv_dif)));
        if ~all(isfinite(xp0))
            xp0(lv_alg) = 0;
        end
    end
    xp0 = full(xp0);
end

function [x0, l_failed, str_why, me_why] = fail(str_why)
    x0       = zeros(0,1);
    l_failed = true;
    str_why  = string(str_why);
    me_why   = MException("GUILDA:SolverODE:AlgebraicNotSolved", "%s", str_why);
end
