function odeX = getODEFunction(ctx, t, x, RM, EM, lg)
% Method for retrieving the DAE system to be analyzed.
%
% z = [x; V; I; u; uc] in the order of the variable map (build_index). Each block (component,
% local controller, global controller) is evaluated from its own states, bus voltage(s) and
% inputs: its state derivatives, the current of a component, and its outputs into the signal
% vector s (only the outputs of the components that a connection reads). The inputs are
% given by the connection map: u - (e + input events + S_sig*s + S_var*z) = 0. Last, the
% current balance of the buses.
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
    odeV = x(ctx.iv_V);

    I    = ctx.Ymat*odeV;
    absI = ctx.absYmat*abs(odeV);

    s = zeros(ctx.n_s, 1, 'like', x);

    % 1. Components: state derivatives, current into the bus, outputs read by a connection
    c_comp = ctx.c_comp;
    for j = 1:numel(c_comp)
        b  = c_comp{j};
        xj = x(b.iv_x);
        Vj = x(b.iv_V);
        uj = x(b.iv_u);
        odeX(b.iv_x) = b.f_dx(t, xj, Vj, uj);
        if ctx.lv_compOn(j)                % a tripped unit gives no current
            Ij = b.f_I(t, xj, Vj, uj);
            odeX(b.iv_V) = odeX(b.iv_V) - [real(Ij); imag(Ij)];
        end
        if b.l_y
            s(b.iv_s) = b.f_Y(t, xj, Vj);
        end
    end

    % 2. Local controllers: from their own states, bus voltage and inputs
    c_lc = ctx.c_lc;
    for k = 1:numel(c_lc)
        b  = c_lc{k};
        xk = x(b.iv_x);
        Vk = x(b.iv_V);
        uk = x(b.iv_u);
        odeX(b.iv_x) = b.f_dx(t, xk, Vk, uk);
        s(b.iv_s)    = b.f_Y(t, xk, Vk, uk);
    end

    % 3. Global controllers: all bus voltages; a tripped one gives no output (its states
    %    and inputs are removed by EM)
    c_gc = ctx.c_gc;
    for k = 1:numel(c_gc)
        if ~ctx.lv_gcOn(k)
            continue
        end
        b  = c_gc{k};
        xk = x(b.iv_x);
        uk = x(b.iv_u);
        odeX(b.iv_x) = b.f_dx(t, xk, odeV, uk);
        s(b.iv_s)    = b.f_Y(t, xk, odeV, uk);
    end

    % 4. Inputs: the sum of their sources (connection map) and the input events
    e = ctx.rv_e;
    for m = 1:numel(ctx.c_offset)
        e(ctx.c_offset{m}{1}) = e(ctx.c_offset{m}{1}) + ctx.c_offset{m}{2}(t);
    end
    iv_in = ctx.iv_in;
    odeX(iv_in) = x(iv_in) - e - ctx.S_sig*s - ctx.S_var*x;

    % 5. Current balance of the buses
    Ib = x(ctx.iv_I);
    odeX(ctx.iv_V) = odeX(ctx.iv_V) + Ib;
    odeX(ctx.iv_I) = odeX(ctx.iv_I) + Ib - I;

    % A current balance below the round-off level of its terms is zero. At rest
    % (e.g. at the start of a phase) the Newton corrections of the solver are then
    % zero instead of round-off noise, which ode15s can take for a diverging
    % iteration and shrink the step until it fails (IEEE68bus without AVR/PSS
    % stopped at t = 0)
    tol = 16*eps*[abs(Ib); abs(Ib) + absI];
    idx = [ctx.iv_V; ctx.iv_I];
    odeX(idx(abs(odeX(idx)) < tol)) = 0;

    odeX = odeX(lg);

end
