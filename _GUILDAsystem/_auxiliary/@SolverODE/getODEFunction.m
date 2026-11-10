function odeX = getODEFunction(ctx, t, x, RM, EM, lg)
% Method for retrieving the DAE system to be analyzed.
%
% Order of evaluation: the outputs y of the components (they do not depend on the inputs),
% the global controllers (they read those outputs, states and all bus voltages), then for
% each component its local controllers (nested first), its inputs, its state derivatives
% and current, and last the current balance of the buses.
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

    % 1. Outputs of the components read by a controller (stacked, idx_Y)
    c_unit = ctx.c_unit;
    y_all  = zeros(ctx.n_y, 1, 'like', x);
    for j = 1:numel(c_unit)
        unit = c_unit{j};
        if unit.l_y
            y_all(unit.idx_Y) = unit.comp.f_Y(t, x(unit.idx_X), x(unit.idx_V));
        end
    end

    % 2. Global controllers: their outputs summed at the inputs they drive (y_GC)
    y_GC = zeros(0,1);
    if ctx.l_GC
        y_GC = zeros(size(x), 'like', x);
    end
    for k = 1:numel(ctx.c_gc)
        sct_gc = ctx.c_gc{k};
        a_GC = sct_gc.gc;
        if ~a_GC.l_isConnect
            continue        % tripped: no output; its states are removed by EM
        end
        % Its inputs: the outputs or states of its units, 0 for a tripped unit
        u_GC = zeros(numel(sct_gc.lv_y), 1, 'like', x);
        u_GC(sct_gc.lv_y) = y_all(sct_gc.iv_y(sct_gc.lv_y));
        u_GC(sct_gc.lv_x) = x(sct_gc.iv_x(sct_gc.lv_x));
        u_GC = u_GC .* repelem(cellfun(@(c) c.l_isConnect, a_GC.controlledUnits), numel(a_GC.sv_u), 1);
        x_GC = x(a_GC.iv_odeX);
        odeX(a_GC.iv_odeX) = a_GC.f_dx(t, x_GC, odeV, u_GC);
        y_k = a_GC.f_Y(t, x_GC, odeV, u_GC);
        y_GC(sct_gc.iv_tgt) = y_GC(sct_gc.iv_tgt) + y_k(sct_gc.iv_src);
    end

    % 3. Each component with its local controllers
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

        odeX = get_dx_algebraic(unit.comp, t, x, x(unit.idx_V), ue, y_all(unit.idx_Y), y_GC, odeX);
    end

    % 4. Current balance of the buses
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
