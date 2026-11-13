function [sct_sol, flag, output] = solve(obj, sct_dae, sct_event, rv_x0, sct_options)
% Integrate the network DAE of the data of a run with the given settings.
%
% The data comes from net.build_simulation_data: the blocks (rows in the variable map and
% function handles), the maps, the admittance, the equilibrium (sct_dae), the phases with
% the disturbances as positions (sct_event) and the initial value (rv_x0). solve reads
% only these and the settings sct_options: no network, bus, branch, component,
% controller or scenario. In each phase a tripped unit is masked (its states and inputs
% are left out, a component injects no current, a global controller gives no output and
% the inputs that observe a tripped component read 0), a faulted bus holds V = 0, and an
% open branch has its 2x2 matrix subtracted from the admittance matrix. Called by
% net.simulate; calling it directly is for advanced use:
%
%   [sct_dae, sct_event, rv_x0] = net.build_simulation_data(tag, time);
%   [sct_sol, flag, output] = net.solver_ODE.solve(sct_dae, sct_event, rv_x0, sct_options);
%
% sct_sol holds the raw trajectories: rv_t (the times; a phase boundary appears twice),
% rm_variable (the variable rows x, Vre, Vim, u, uc of sct_dae.tab_variable; the states of
% a tripped unit are NaN), rm_I (Ire, Iim of each bus) and rv_phase (the phase of each time).
% flag is 1 when the simulation reached the end time, 0 when it stopped because the
% run exceeded TimeLimit, and -1 when the solver stopped before the end time or could
% not solve a phase (output.message has the reason; output.exception has the error
% when there was one). In the last two cases sct_sol holds the trajectories up to
% the time reached (output.tEnd), with no time points when the first phase could not
% be solved. An error of other code during a phase, such as a model, stops with an error
% (GUILDA:SolverODE:PhaseFailed, the original as cause).
    arguments (Input)
        obj % Solver (net.solver_ODE).
        sct_dae     (1,1) struct % Blocks, maps, admittance and equilibrium of the network (build_simulation_data).
        sct_event   (:,1) struct % One element per phase, the disturbances as positions (build_simulation_data).
        rv_x0       (:,1) double % Initial value of the variable rows of sct_dae.tab_variable.
        sct_options (1,1) struct % Effective settings (net.simulate: GUILDA.setting and the options of the call).
    end
    arguments (Output)
        sct_sol (1,1) struct % Raw trajectories: rv_t, rm_variable, rm_I, rv_phase.
        flag    (1,1) double % 1 completed, 0 stopped by TimeLimit, -1 stopped by the solver.
        output  (1,1) struct % Details: message, tEnd, nPhases, nPhasesDone, isSparse (false when the run fell back to dense matrices), exception (MException of a phase that could not be solved, with the original as cause; otherwise empty).
    end
    ctx = SolverODE.build_index(sct_dae);
    ctx.rv_x0    = ctx.rv_z0;
    ctx.rv_x0(ctx.iv_var) = rv_x0;
    ctx.l_sparse = true;              % until the solver rejects the sparse matrices (see use_dense)
    ctx.cm_Y     = sct_dae.cm_Y;      % complex, all branches closed
    ctx.im_branchBus = sct_dae.im_branchBus;
    ctx.c_branchY    = sct_dae.c_branchY;
    ctx.iv_open  = zeros(0,1);        % open branches of ctx.Ymat (see set_admittance)
    ctx          = SolverODE.set_admittance(ctx, zeros(0,1), true);

    o = makeODE(sct_options);
    options = odeset("RelTol", o.RelativeTolerance, "AbsTol", o.AbsoluteTolerance);
    np   = numel(sct_event);
    x0   = [];
    Mass = [];

    % Set reporter
    ts = sct_event(1).t1;
    te = sct_event(end).t2;
    odeProg  = ProgressODE( sct_options.Progress, [ts,te], sct_options.TimeLimit);
    o.SolverOptions.OutputFcn = odeProg.OutputFcn;
    o.EventDefinition = odeEvent("EventFcn", @(t,x) odeProg.Events(), "Response", "stop");

    c_phase = cell(1,0);
    flag    = 1;
    me_stop = [];       % error of a phase that could not be solved
    tp      = 1;
    while tp <= np

        % Faults, trips, open branches, offsets and inputs of the phase (Scenario.compile)
        ph = sct_event(tp);

        % Trips (a tripped global controller gives no output), faults and input events
        ctx = set_phase(ctx, ph);

        t1 = ph.t1;
        t2 = ph.t2;

        % Y of the phase: without the branches opened in it (OpenBranch)
        ctx = SolverODE.set_admittance(ctx, ph.iv_openBranch, false);

        [EM, RM, lv_FBorTC, x0, Mass] = SolverODE.initial_condition(ctx, ph, x0, Mass);

        if ~ctx.l_sparse
            Mass = full(Mass);
        end

        o.InitialValue = x0;
        o = SolverODE.set_equations(o, ctx, RM, EM, ~lv_FBorTC, Mass);
        if isfield(sct_options, "PhaseProbe")     % test hook: compare Jacobian and right-hand side
            sct_options.PhaseProbe(o);
        end

        % update reporter
        odeProg.timeoffset = t1;
        odeProg.message  = "|";
        if tp~=np
            sr_evti  = sct_event(tp+1).sr_event;
            sr_evti  = sr_evti(~contains(sr_evti,"NoAction"));
            if ~isempty(sr_evti)
                odeProg.message  = "|("+join(sr_evti,",")+": t="+t2+")";
            end
        end

        % The warning of the solver (e.g. why it stopped) goes into output.message
        [s_warn0, id_warn0] = lastwarn();
        lastwarn("");
        sr_phase = {num2str(tp), num2str(t1), num2str(t2)};

        % Consistent initial condition: the differential states keep their values at
        % the start of the phase and only the algebraic variables are solved again.
        % Without differential states the solver stops on the mass matrix.
        try
            x0_ic = x0;  xp0_ic = zeros(0,1);  l_failed = false;
            if nnz(Mass) > 0
                [x0_ic, xp0_ic, l_failed, s_why, me_ic] = CalculateInitialCondition(o, options);
            end
        catch me
            odeProg.OutputFcn([],[],"break");
            ME = MException('GUILDA:SolverODE:PhaseFailed', '%s', ...
                            msg('GUILDA:SolverODE:PhaseFailed', sr_phase{:}, me.message));
            throw(ME.addCause(me))
        end
        if l_failed
            odeProg.OutputFcn([],[],"break");
            me_stop = MException('GUILDA:SolverODE:InitialConditionFailed', '%s', ...
                                 msg('GUILDA:SolverODE:InitialConditionFailed', sr_phase{:}, s_why));
            me_stop = me_stop.addCause(me_ic);
            flag = -1;
            break
        end
        lv_dif = full(any(o.MassMatrix.MassMatrix ~= 0, 1)).';

        l_solved = false;
        while ~l_solved
            % The solver takes them without its own consistency step, which could move
            % the differential states
            o.InitialValue = x0_ic;
            o.InitialSlope = xp0_ic;
            try
                % When solving the equation, specify [0, duration of each phase]
                sol = solve(o, 0, t2-t1);
            catch me

                if SolverODE.is_false_index_error(ctx, me)
                    [ctx, o] = SolverODE.use_dense(ctx, o, x0, RM, EM, ~lv_FBorTC, sct_options.Verbose, Mass);
                    continue
                end

                odeProg.OutputFcn([],[],"break");
                % NeedBetterY0: the solver did not accept the consistent initial condition
                s_id = 'GUILDA:SolverODE:PhaseFailed';
                if endsWith(string(me.identifier), ":NeedBetterY0")
                    s_id = 'GUILDA:SolverODE:UnfeasibleDAE';
                end
                ME = MException(s_id, '%s', msg(s_id, sr_phase{:}, me.message));
                ME = ME.addCause(me);
                if ~SolverODE.is_numerical_failure(me, o)
                    throw(ME)
                end
                me_stop = ME;
                break
            end
            l_solved = true;
        end
        o.InitialSlope = zeros(0,1);
        if isempty(me_stop) && ~isequal(sol.Solution(lv_dif,1), x0_ic(lv_dif))
            % Not expected: the solver changed the differential states at the start
            odeProg.OutputFcn([],[],"break");
            s_why = sprintf("the solver moved the differential states by up to %g at the start of the phase.", ...
                              max(abs(sol.Solution(lv_dif,1) - x0_ic(lv_dif))));
            me_stop = MException('GUILDA:SolverODE:InitialConditionFailed', '%s', ...
                                 msg('GUILDA:SolverODE:InitialConditionFailed', sr_phase{:}, s_why));
        end
        if ~isempty(me_stop)
            flag = -1;
            break
        end
        s_warn = lastwarn();
        if isempty(s_warn)
            lastwarn(s_warn0, id_warn0);
        end

        c_phase{tp} = SolverODE.phase_result(ctx, ph, struct('Time', (sol.Time + t1)', 'Solution', (EM * sol.Solution).'));
        if sol.Time(end) < (t2-t1)
            if odeProg.ToBeContinue
                flag = -1;
            else
                flag = 0;
            end
            break;
        end

        [x0, Mass] = SolverODE.getNextPhase(ctx, reshape(sol.Solution(:,end),[],1), Mass, RM, EM);

        tp = tp + 1;
    end

    output = struct();
    if isempty(c_phase)
        output.tEnd    = ts;
    else
        output.tEnd    = c_phase{end}.t(end);
    end
    output.nPhases     = np;
    output.nPhasesDone = numel(c_phase) - (flag ~= 1 && isempty(me_stop));
    output.isSparse    = ctx.l_sparse;
    output.exception   = me_stop;
    switch flag
        case 1
            output.message = sprintf("The simulation reached t = %g s (%d phases).", output.tEnd, np);
        case 0
            output.message = sprintf("The simulation stopped at t = %g s of %g s in phase %d: the computation time exceeded TimeLimit = %g s. " + ...
                                     "Increase TimeLimit (Inf for no limit).", output.tEnd, te, tp, sct_options.TimeLimit);
        otherwise
            if ~isempty(me_stop)
                output.message = sprintf("The simulation stopped at t = %g s of %g s. %s\n" + ...
                                         "Try a smaller Tolerance or MaxStep, the other Solver, or check the model and the events.", ...
                                         output.tEnd, te, me_stop.message);
            elseif isempty(s_warn)
                s_warn = "(no message from the solver)";
            end
            if isempty(me_stop)
                output.message = sprintf("The solver stopped at t = %g s of %g s in phase %d (t = [%g, %g] s). " + ...
                                         "Solver (time from the start of the phase): %s\n" + ...
                                         "Try a smaller Tolerance or MaxStep, the other Solver, or check the model.", ...
                                         output.tEnd, te, tp, sct_event(tp).t1, sct_event(tp).t2, strtrim(s_warn));
            end
    end
    if sct_options.Verbose
        disp(output.message)
    end

    % Trajectories of the phases
    n_var = numel(ctx.iv_var);
    sol = reshape(c_phase, [], 1);
    sct_sol = struct();
    sct_sol.rv_t        = cell2mat([{zeros(0,1)}; cellfun(@(T) T.t, sol, 'UniformOutput', false)]);
    sct_sol.rm_variable = cell2mat([{zeros(0,n_var)}; cellfun(@(T) T.x, sol, 'UniformOutput', false)]);
    sct_sol.rm_I        = cell2mat([{zeros(0,2*ctx.n_bus)}; cellfun(@(T) T.i, sol, 'UniformOutput', false)]);
    sct_sol.rv_phase    = repelem((1:numel(sol)).', cellfun(@(T) numel(T.t), sol));
end


function ctx = set_phase(ctx, ph)
% The trips, faults and input events of a phase in the context (positions of sct_event).
% An input of a global controller that observes a tripped component reads 0. The input
% events become functions of the time from the start of the phase: a constant, or one
% interpolant per input row ("foh": linear, "spline"; the end values outside the points).
    arguments (Input)
        ctx  % Context of the run.
        ph   % Data of the phase (an element of sct_event).
    end
    arguments (Output)
        ctx  % Context with lv_compOn, lv_gcOn, lv_fault, S_sig, S_var, c_input, iv_inputAll.
    end
    ctx.lv_compOn = true(numel(ctx.c_comp), 1);
    ctx.lv_compOn(ph.iv_tripComp) = false;
    ctx.lv_gcOn   = true(numel(ctx.c_gc), 1);
    ctx.lv_gcOn(ph.iv_tripGC) = false;
    ctx.lv_fault  = false(ctx.n_bus, 1);
    ctx.lv_fault(ph.iv_faultBus) = true;
    w = ones(numel(ctx.iv_in), 1);
    w(ctx.iv_gateIn) = ctx.lv_compOn(ctx.iv_gateComp);
    ctx.S_sig = w .* ctx.S_sig0;
    ctx.S_var = w .* ctx.S_var0;

    i0 = ctx.iv_in(1) - 1;           % the input events act on the rows of the inputs (iv_in)
    n_ev = size(ph.c_input, 1);
    ctx.c_input = cell(n_ev, 1);
    iv_all = zeros(0,1);
    sct_method = struct("foh", "linear", "spline", "spline");
    for m = 1:n_ev
        [iv_row, rv_t, rm_v, s_method] = ph.c_input{m,:};
        ev = struct("iv", ctx.iv_var(iv_row) - i0, "rv_v", [], "c_F", {{}});
        if isscalar(rv_t)
            ev.rv_v = reshape(rm_v(1,:), [], 1);
        elseif s_method == "zoh"
            ev.rv_v = reshape(rm_v(max(1, nnz(rv_t <= 0)), :), [], 1);
        else
            ev.c_F = cell(size(rm_v,2), 1);
            for c = 1:size(rm_v,2)
                ev.c_F{c} = griddedInterpolant(rv_t, rm_v(:,c), sct_method.(s_method), "nearest");
            end
        end
        ctx.c_input{m} = ev;
        iv_all = union(iv_all, ev.iv);
    end
    ctx.iv_inputAll = iv_all;
end
