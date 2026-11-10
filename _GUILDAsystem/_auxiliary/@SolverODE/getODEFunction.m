function odeX = getODEFunction(ctx, t, x, RM, EM, lg)
% Method for retrieving the DAE system to be analyzed.
    arguments (Input)
        ctx                 % Context of the run.
        t    (1,1) double   % [s] Time from the start of the phase.
        x    (:,1) double   % Reduced state vector.
        RM                  %#ok<INUSA> Reduction matrix of the phase.
        EM                  %#ok<INUSA> Expansion matrix of the phase.
        lg   (:,1) logical  % True for the entries of the full state vector that are solved.
    end
    arguments (Output)
        odeX  (:,1) double  % Right-hand side of the reduced DAE.
    end

    x_lg = x;
    x = zeros(size(lg), 'like', x_lg);
    x(lg) = x_lg;

    odeX = zeros(size(x));
    odeV = x(ctx.rv_odeV);

    I    = ctx.Ymat*odeV;
    absI = ctx.absYmat*abs(odeV);

    % Outputs of all global controllers, at the indices of the component inputs they drive
    if ctx.l_GC
        y_GC = zeros(size(x), 'like', x);
        a_GCs = ctx.net.a_GlobalController;
    else
        a_GCs = {};
    end
    for k = 1:numel(a_GCs)
        a_GC = a_GCs{k};
        if ~a_GC.l_isConnect
            continue        % tripped: no output; its states are removed by EM
        end

        x_GC = x(a_GC.iv_odeX);
        u_GC = x(a_GC.iv_odeU);

        u_connect = tools.dcellfun(@(CU) CU.l_isConnect, a_GC.controlledUnits);

        odeX(a_GC.iv_odeX) = a_GC.f_dx(t,x_GC,[],u_connect*u_GC);
        y_GC(a_GC.iv_odeY) = y_GC(a_GC.iv_odeY) + a_GC.f_Y(t,x_GC,[],u_connect*u_GC);
    end

    c_unit = ctx.c_unit;
    for j = 1:numel(c_unit)
        unit = c_unit{j};
        ue = unit.ue;
        if ctx.l_GC
            ue = ue + y_GC(unit.idx_U);    % zero for inputs no global controller drives
        end
        f_Uoffset = unit.comp.rv_Uoffset;
        if ~isempty(f_Uoffset)             % empty without an input event in this phase
            ue = ue + f_Uoffset(t);
        end

        odeX = get_dx_algebraic(unit.comp, t, x, x(unit.idx_V), ue, odeX);
    end

    Ib = x(ctx.iv_busI);
    odeX(ctx.iv_busV) = odeX(ctx.iv_busV) + Ib;
    odeX(ctx.iv_busI) = odeX(ctx.iv_busI) + Ib - I;

    % A current balance below the round-off level of its terms is zero. At rest
    % (e.g. at the start of a phase) the Newton corrections of the solver are then
    % zero instead of round-off noise, which ode15s can take for a diverging
    % iteration and shrink the step until it fails (IEEE68bus without AVR/PSS
    % stopped at t = 0)
    tol = 16*eps*[abs(Ib); abs(Ib) + absI];
    idx = [ctx.iv_busV; ctx.iv_busI];
    odeX(idx(abs(odeX(idx)) < tol)) = 0;

    odeX = odeX(lg);

end
