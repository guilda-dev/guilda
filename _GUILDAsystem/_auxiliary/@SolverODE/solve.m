function [result, flag, output] = solve(obj, net, time, c_events, sct_options)
% Integrate the network DAE with the given settings.
%
% Runs the time simulation of net over time with the scenarios c_events and the
% effective settings sct_options, and returns the trajectories as an
% ResultODE. The solver is only read: nothing is written back into it.
% Nothing is written to the models: the positions of the run (build_index, from the
% variable map and the connection map) and the trips, faults and input events of each
% phase are kept in the context of the run. Called by net.simulate; calling it directly
% is for advanced use. Like net.simulate, it stops with the error GUILDA:SolverODE:Stale
% when net.initialize() is needed (build_index).
% flag is 1 when the simulation reached the end time, 0 when it stopped because the
% run exceeded TimeLimit, and -1 when the solver stopped before the end time or could
% not solve a phase (output.message has the reason; output.exception has the error
% when there was one). In the last two cases the result holds the trajectories up to
% the time reached (output.tEnd), with no time points when the first phase could not
% be solved. An error of other code during a phase, such as an input function or a
% model, stops with an error (GUILDA:SolverODE:PhaseFailed, the original as cause).
    arguments (Input)
        obj % Solver (net.solver_ODE).
        net % Network initialized by net.initialize.
        time      (:,1) double = [] % [s] Simulation time [t0, tend] (or [] for the time span of the events).
        c_events  cell = {} % Scenarios of the run (each attached to net; see Scenario).
        sct_options (1,1) struct = obj.get_options() % Effective settings (output of get_options).
    end
    arguments (Output)
        result % Trajectories of the buses and components.
        flag % 1 completed, 0 stopped by TimeLimit, -1 stopped by the solver.
        output % Details: message, tEnd, phases (time table of the phases), nPhases, nPhasesDone, isSparse (false when the run fell back to dense matrices), exception (MException of a phase that could not be solved, with the original as cause; otherwise empty).
    end
    t0 = tic;

    % Phases of the run: checks the scenarios, builds the data of each phase once
    [tab_phase, sct_phase] = Scenario.compile(c_events, net, time);
    check_islands(net, {sct_phase.sv_open}.', tab_phase);
    ctx = SolverODE.build_index(net);   % also stops when net.initialize() is needed
    ctx.net     = net;
    ctx.l_sparse = true;              % until the solver rejects the sparse matrices (see use_dense)
    ctx.Ybus    = net.get_admittance_matrix.Variables;   % complex, all branches closed
    ctx.sv_open = strings(0,1);       % open branches of ctx.Ymat (see set_admittance)
    ctx         = SolverODE.set_admittance(ctx, strings(0,1), true);

    o = makeODE(sct_options);
    options = odeset("RelTol", o.RelativeTolerance, "AbsTol", o.AbsoluteTolerance);
    np   = size(tab_phase,1);
    x0   = [];
    Mass = [];

    % Set reporter
    sr_evt = string(tab_phase.Properties.VariableNames(3:end));
    ts = tab_phase{  1,"t1"};
    te = tab_phase{end,"t2"};
    if sct_options.Verbose
        print_phases(tab_phase, sr_evt);
    end
    odeProg  = ProgressODE( sct_options.Progress, [ts,te], sct_options.TimeLimit);
    o.SolverOptions.OutputFcn = odeProg.OutputFcn;
    o.EventDefinition = odeEvent("EventFcn", @(t,x) odeProg.Events(), "Response", "stop");

    c_phase = cell(1,0);
    flag    = 1;
    me_stop = [];       % error of a phase that could not be solved
    tp      = 1;
    while tp <= np

        % Faults, trips, open branches, offsets and inputs of the phase (Scenario.compile)
        ph = sct_phase(tp);

        % Trips (a tripped global controller gives no output), faults and input events
        ctx = set_phase(ctx, ph);

        t1 = ph.t1;
        t2 = ph.t2;

        % Y of the phase: without the branches opened in it (OpenBranch)
        ctx = SolverODE.set_admittance(ctx, ph.sv_open, false);

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
            sr_evti  = sr_evt( tab_phase{tp+1,3:end} );
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
    output.phases      = tab_phase;
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
                                         "Try a smaller Tolerance, other SolverOptions, or check the model and the events.", ...
                                         output.tEnd, te, me_stop.message);
            elseif isempty(s_warn)
                s_warn = "(no message from the solver)";
            end
            if isempty(me_stop)
                output.message = sprintf("The solver stopped at t = %g s of %g s in phase %d (t = [%g, %g] s). " + ...
                                         "Solver (time from the start of the phase): %s\n" + ...
                                         "Try a smaller Tolerance, other SolverOptions, or check the model.", ...
                                         output.tEnd, te, tp, tab_phase{tp,"t1"}, tab_phase{tp,"t2"}, strtrim(s_warn));
            end
    end
    if sct_options.Verbose
        disp(output.message)
    end

    result = ResultODE(net, obj, sct_options, flag, output, t0, c_phase);
end


function ctx = set_phase(ctx, ph)
% The trips, faults and input events of a phase in the context (the models are not changed).
% An input of a global controller that observes a tripped component reads 0.
    sv_trip = reshape(string(ph.sv_trip), [], 1);
    ctx.lv_compOn = ~ismember(ctx.sv_comp, sv_trip);
    ctx.lv_gcOn   = ~ismember(ctx.sv_gc, sv_trip);
    ctx.lv_fault  = ismember(ctx.sv_bus, reshape(string(ph.sv_fault), [], 1));
    w = ones(numel(ctx.iv_in), 1);
    w(ctx.iv_gateIn) = ctx.lv_compOn(ctx.iv_gateComp);
    ctx.S_sig = w .* ctx.S_sig0;
    ctx.S_var = w .* ctx.S_var0;
    c_off = reshape(ph.c_Uoffset, [], 1);
    lv = ~cellfun(@isempty, c_off);
    i0 = ctx.iv_in(1) - 1;           % the input events act on the rows of the inputs (iv_in)
    ctx.c_offset = cellfun(@(b, f) {b.iv_u - i0, f}, ctx.c_comp(lv), c_off(lv), 'UniformOutput', false);
end
