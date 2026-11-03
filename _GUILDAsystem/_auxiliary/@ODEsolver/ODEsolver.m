classdef (Sealed = true) ODEsolver < auxiliary
% Solver of the time simulation (net.simulate).
%
% net.solver_ODE holds one; its properties are the stored defaults of net.simulate and are
% kept between runs. Name-Value options of a call override them for that call only (see OptionMap and
% get_options). The solver holds settings only: the network, the event time table and the
% trajectories of a run are local to solve, and the result is returned as an
% ODEresult. The DAE of the network is integrated phase by phase: a phase is a
% time interval in which the set of active events (ODEevent) does not change. Each
% phase is solved with the MATLAB ode object (Solver, SolverOptions, RelativeTolerance,
% AbsoluteTolerance).
%
% <@Examples>
% ```matlab
% net = network.IEEE14bus();
% net.initialize();
% net.solver_ODE.TimeLimit = 60;          % stored default, kept between runs
% ev = ODEevent("fault", net, "TimeSpan", [1, 1.05], "FaultBus", "B008");
% result = net.simulate([0, 10], ev, Solver="ode23t", Progress="none");  % this call only
% ```
%
% See also ODEresult, ODEevent, PowerNetwork.simulate

    properties (Access=public) % Settings
        % Solver of the MATLAB ode object (Solver property of ode).
        % The DAE of the network has a singular mass matrix, so it needs a solver for DAEs
        % (ode15s, ode23t).
        Solver         matlab.ode.SolverID = "ode15s"

        % Options of the solver (SolverOptions property of ode), e.g.
        % MaxStep or InitialStep. Its class must match Solver.
        SolverOptions  matlab.ode.Options  = matlab.ode.options.ODE15s

        % Relative error tolerance of the integration (RelativeTolerance of ode, RelTol of odeset).
        % Name-Value option Tolerance.
        RelativeTolerance   (1,1) double {mustBePositive, mustBeBetween(RelativeTolerance,1e-15,1e-3, "closed")} = 1e-4

        % Absolute error tolerance of the integration (AbsoluteTolerance of ode, AbsTol of odeset).
        % Name-Value option AbsoluteTolerance.
        AbsoluteTolerance   (1,1) double {mustBePositive, mustBeBetween(AbsoluteTolerance,1e-15,1e-3, "closed")} = 1e-6

        % SeparateComplexParts property of the ode object.
        SeparateComplexParts matlab.lang.OnOffSwitchState = "off"

        % Progress display during the integration.
        % "dialog" (a waitbar), "disp" (a text bar in the Command Window) or "none". Name-Value
        % option Progress, which also accepts true ("dialog") and false ("none").
        Progress            (1,1) string {mustBeMember(Progress,["none","disp","dialog"])} = "dialog"

        % [s] Limit of the computation (wall-clock) time of the whole run, checked at each solver step.
        % When it is exceeded, the simulation stops at the time reached, and the result has flag =
        % 0 ("stopped by TimeLimit"). Inf for no limit.
        TimeLimit           (1,1) double {mustBePositive} = Inf

        % Print the phases before the integration and the outcome (output.message) after it.
        Verbose             (1,1) logical = false

        % Call result.Plot() after each simulation.
        Plot                (1,1) logical = false
    end

    properties (Constant) % Settings
        % Name-Value options of net.simulate and the solver property each one sets.
        % Input of tools.resolve_options. Solver, Tolerance, TimeLimit, Progress, Verbose and Plot are common names; Tolerance is
        % the relative tolerance. AbsoluteTolerance, SolverOptions and SeparateComplexParts keep
        % the names of the MATLAB ode object.
        % <@Type> struct
        OptionMap = struct( ...
            "Solver",               "Solver", ...
            "SolverOptions",        "SolverOptions", ...
            "Tolerance",            "RelativeTolerance", ...
            "AbsoluteTolerance",    "AbsoluteTolerance", ...
            "SeparateComplexParts", "SeparateComplexParts", ...
            "TimeLimit",            "TimeLimit", ...
            "Progress",             {{"Progress", @(v) ODEsolver.progress_mode(v)}}, ...
            "Verbose",              "Verbose", ...
            "Plot",                 "Plot")
    end

    properties (Dependent, Hidden) % Compatibility
        Reporter                                    % COMPAT(v3) old name of Progress (v3_ode_reporter)
    end

    properties (SetAccess=private, Hidden) % Version
        % Version of this class.
        Ver (1,1) double = 2.0
    end

    methods
        function obj = ODEsolver()
        % Create a time simulation solver with the defaults of GUILDA.config("TimeSimulation").
        %
        % A network creates its own (net.solver_ODE); net.reset_solver() replaces it with a
        % new one.
            sct = GUILDA.config("TimeSimulation");
            obj.AbsoluteTolerance   = sct.AbsoluteTolerance.Value;
            obj.RelativeTolerance   = sct.RelativeTolerance.Value;
            obj.SeparateComplexParts= sct.SeparateComplexParts.Value;
            obj.Progress            = sct.Progress.Value;
            val = sct.TimeLimit.Value;
            if isnumeric(val) && val>0
                obj.TimeLimit = val;
            else
                obj.TimeLimit = inf;
            end
        end

        function v = get.Reporter(obj), v = obj.Progress; end                              % COMPAT(v3)
        function set.Reporter(obj, v), obj.Progress = v3_ode_reporter(v); end               % COMPAT(v3)

        function s_options = get_options(obj, nv)
        % Get the effective settings of one run as a struct.
        %
        % Every stored setting of the solver, with the Name-Value overrides of the call applied. The solver itself is not changed.
        % A name that is not in OptionMap stops with GUILDA:resolve_options:UnknownName;
        % an invalid value stops with the validation error of the option.
            arguments
                obj % Solver holding the defaults (net.solver_ODE).
                nv (1,:) cell = {} % Name-Value overrides: Solver, SolverOptions, Tolerance, AbsoluteTolerance, SeparateComplexParts, TimeLimit, Progress, Verbose, Plot.
            end
            arguments (Output)
                s_options % One field per setting (Solver, SolverOptions, RelativeTolerance, AbsoluteTolerance, SeparateComplexParts, Progress, TimeLimit, Verbose, Plot).
            end
            s_given = tools.resolve_options(obj, ODEsolver.OptionMap, nv);
            validate_options(nv{:});

            mc = metaclass(obj);
            a_prop = mc.PropertyList(~[mc.PropertyList.Constant] & ~[mc.PropertyList.Dependent] & ...
                                     ~[mc.PropertyList.Hidden] & strcmp({mc.PropertyList.SetAccess}, 'public'));
            s_options = struct();
            for str_prop = string({a_prop.Name})
                if isfield(s_given, str_prop)
                    s_options.(str_prop) = s_given.(str_prop);
                else
                    s_options.(str_prop) = obj.(str_prop);
                end
            end
        end

        function [result, flag, output] = solve(obj, net, time, c_events, s_options)
        % Integrate the network DAE with the given settings.
        %
        % Runs the time simulation of net over time with the events c_events and the
        % effective settings s_options, and returns the trajectories as an
        % ODEresult. The solver is only read: nothing is written back into it.
        % The simulation working data of the models (iv_odeX, iv_odeU, iv_odeY, iv_odeI) is
        % rebuilt for this run. Called by net.simulate; calling it directly is for advanced
        % use. Like net.simulate, it first builds out-of-date f_* handles and stops with the
        % error GUILDA:PowerNetwork:EquilibriumStale when net.initialize() is needed.
        % flag is 1 when the simulation reached the end time, 0 when it stopped because the
        % run exceeded TimeLimit, and -1 when the solver stopped before the end time or could
        % not solve a phase (output.message has the reason; output.exception has the error
        % when there was one). In the last two cases the result holds the trajectories up to
        % the time reached (output.tEnd), with no time points when the first phase could not
        % be solved. An error of other code during a phase, such as an input function or a
        % model, stops with an error (GUILDA:ODEsolver:PhaseFailed, the original as cause).
            arguments
                obj % Solver (net.solver_ODE).
                net % Network initialized by net.initialize.
                time      (:,1) double = [] % [s] Simulation time [t0, tend] (or [] for the time span of the events).
                c_events  cell = {} % Events of the run.
                s_options (1,1) struct = obj.get_options() % Effective settings (output of get_options).
            end
            arguments (Output)
                result % Trajectories of the buses and components.
                flag % 1 completed, 0 stopped by TimeLimit, -1 stopped by the solver.
                output % Details: message, tEnd, phases (time table of the phases), nPhases, nPhasesDone, isSparse (false when the run fell back to dense matrices), exception (MException of a phase that could not be solved, with the original as cause; otherwise empty).
            end
            t0 = tic;
            net.require_equilibrium();    % build out-of-date f_*; error if net.initialize() is needed

            % Without events, add an empty event so that ODEevent.table is dispatched.
            if isempty(c_events)
                t_start = 0;
                if ~isempty(time)
                    t_start = time(1);
                end
                c_events = {ODEevent("NoAction", net, "TimeSpan", t_start)};
            end

            [tab_phase, c_odeEvnt] = table(c_events{:}, "time", time, "net", net);
            c_open = ODEsolver.get_open_branches(tab_phase, c_odeEvnt);
            check_islands(net, c_open, tab_phase);
            ODEsolver.initialize_index(net);
            c_restore = onCleanup(@() ODEsolver.restore_working_data(net));

            ctx = struct();
            ctx.net     = net;
            ctx.l_sparse = true;              % until the solver rejects the sparse matrices (see use_dense)
            ctx.Ybus    = net.get_admittance_matrix.Variables;   % complex, all branches closed
            ctx.sv_open = strings(0,1);       % open branches of ctx.Ymat (see set_admittance)
            ctx         = ODEsolver.set_admittance(ctx, strings(0,1), true);
            ctx.rv_odeV = cell2mat(tools.cellfun(@(b) b.iv_odeX, net.a_Bus));
            ctx.iv_busV = reshape(ctx.rv_odeV, [], 1);
            ctx.iv_busI = reshape(cell2mat(tools.cellfun(@(b) b.iv_odeI, net.a_Bus)), [], 1);
            ctx.l_GC    = ~isempty(net.a_GlobalController);
            ctx.c_unit  = ODEsolver.get_units(net);

            o = makeODE(s_options);
            options = odeset("RelTol", o.RelativeTolerance, "AbsTol", o.AbsoluteTolerance);
            np   = size(tab_phase,1);
            x0   = [];
            Mass = [];

            % Set reporter
            str_evt = string(tab_phase.Properties.VariableNames(3:end));
            ts = tab_phase{  1,"t1"};
            te = tab_phase{end,"t2"};
            if s_options.Verbose
                print_phases(tab_phase, str_evt);
            end
            odeProg  = ODEprogress( s_options.Progress, [ts,te], s_options.TimeLimit);
            o.SolverOptions.OutputFcn = odeProg.OutputFcn;
            o.EventDefinition = odeEvent("EventFcn", @(t,x) odeProg.Events(), "Response", "stop");

            c_phase = cell(1,0);
            flag    = 1;
            me_stop = [];       % error of a phase that could not be solved
            tp      = 1;
            while tp <= np

                % Retrieving events related to ground faults and circuit tripping.
                TT = tab_phase(tp,:);

                odeEvents = c_odeEvnt( TT{:,3:end} );

                % A tripped global controller gives no output (TripUnit names it)
                str_trip = cellfun(@(e) e.TripUnit, odeEvents, 'UniformOutput', false);
                ODEsolver.set_gc_connect(net, vertcat(strings(0,1), str_trip{:}));

                t1 = TT{1, 't1'};
                t2 = TT{1, 't2'};

                % Y of the phase: without the branches opened in it (OpenBranch)
                ctx = ODEsolver.set_admittance(ctx, c_open{tp}, false);

                setEventCondition(odeEvents{:}, "TimePhase", [t1,t2], "Iteration", tp);

                [EM, RM, lv_FBorTC, x0, Mass] = getInitialCondition(odeEvents{:}, "x0", x0, "M0", Mass);

                if ~ctx.l_sparse
                    Mass = full(Mass);
                end

                o.InitialValue = x0;
                o = ODEsolver.set_equations(o, ctx, RM, EM, ~lv_FBorTC, Mass);
                if isfield(s_options, "PhaseProbe")     % test hook: compare Jacobian and right-hand side
                    s_options.PhaseProbe(o);
                end

                % update reporter
                odeProg.timeoffset = t1;
                odeProg.message  = "|";
                if tp~=np
                    str_evti = str_evt( tab_phase{tp+1,3:end} );
                    str_evti = str_evti(~contains(str_evti,"NoAction"));
                    if ~isempty(str_evti)
                        odeProg.message  = "|("+join(str_evti,",")+": t="+t2+")";
                    end
                end

                % The warning of the solver (e.g. why it stopped) goes into output.message
                [str_warn0, id_warn0] = lastwarn();
                lastwarn("");
                str_phase = {num2str(tp), num2str(t1), num2str(t2)};

                % Consistent initial condition: the differential states keep their values at
                % the start of the phase and only the algebraic variables are solved again.
                % Without differential states the solver stops on the mass matrix.
                try
                    x0_ic = x0;  xp0_ic = zeros(0,1);  l_failed = false;
                    if nnz(Mass) > 0
                        [x0_ic, xp0_ic, l_failed, str_why, me_ic] = CalculateInitialCondition(o, options);
                    end
                catch me
                    odeProg.OutputFcn([],[],"break");
                    ME = MException('GUILDA:ODEsolver:PhaseFailed', '%s', ...
                                    msg('GUILDA:ODEsolver:PhaseFailed', str_phase{:}, me.message));
                    throw(ME.addCause(me))
                end
                if l_failed
                    odeProg.OutputFcn([],[],"break");
                    me_stop = MException('GUILDA:ODEsolver:InitialConditionFailed', '%s', ...
                                         msg('GUILDA:ODEsolver:InitialConditionFailed', str_phase{:}, str_why));
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

                        if ODEsolver.is_false_index_error(ctx, me)
                            [ctx, o] = ODEsolver.use_dense(ctx, o, x0, RM, EM, ~lv_FBorTC, s_options.Verbose, Mass);
                            continue
                        end

                        odeProg.OutputFcn([],[],"break");
                        % NeedBetterY0: the solver did not accept the consistent initial condition
                        str_id = 'GUILDA:ODEsolver:PhaseFailed';
                        if endsWith(string(me.identifier), ":NeedBetterY0")
                            str_id = 'GUILDA:ODEsolver:UnfeasibleDAE';
                        end
                        ME = MException(str_id, '%s', msg(str_id, str_phase{:}, me.message));
                        ME = ME.addCause(me);
                        if ~ODEsolver.is_numerical_failure(me, o)
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
                    str_why = sprintf("the solver moved the differential states by up to %g at the start of the phase.", ...
                                      max(abs(sol.Solution(lv_dif,1) - x0_ic(lv_dif))));
                    me_stop = MException('GUILDA:ODEsolver:InitialConditionFailed', '%s', ...
                                         msg('GUILDA:ODEsolver:InitialConditionFailed', str_phase{:}, str_why));
                end
                if ~isempty(me_stop)
                    flag = -1;
                    break
                end
                str_warn = lastwarn();
                if isempty(str_warn)
                    lastwarn(str_warn0, id_warn0);
                end

                c_phase{tp} = Event2State( odeEvents{:}, "ODEResults", struct('Time', (sol.Time + t1)', 'Solution', (EM * sol.Solution).'), "ODEYmatrix", ctx.Ymat );
                if sol.Time(end) < (t2-t1)
                    if odeProg.ToBeContinue
                        flag = -1;
                    else
                        flag = 0;
                    end
                    break;
                end

                [x0, Mass] = ODEsolver.getNextPhase(ctx, reshape(sol.Solution(:,end),[],1), Mass, RM, EM);

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
                                             "Increase TimeLimit (Inf for no limit).", output.tEnd, te, tp, s_options.TimeLimit);
                otherwise
                    if ~isempty(me_stop)
                        output.message = sprintf("The simulation stopped at t = %g s of %g s. %s\n" + ...
                                                 "Try a smaller Tolerance, other SolverOptions, or check the model and the events.", ...
                                                 output.tEnd, te, me_stop.message);
                    elseif isempty(str_warn)
                        str_warn = "(no message from the solver)";
                    end
                    if isempty(me_stop)
                        output.message = sprintf("The solver stopped at t = %g s of %g s in phase %d (t = [%g, %g] s). " + ...
                                                 "Solver (time from the start of the phase): %s\n" + ...
                                                 "Try a smaller Tolerance, other SolverOptions, or check the model.", ...
                                                 output.tEnd, te, tp, tab_phase{tp,"t1"}, tab_phase{tp,"t2"}, strtrim(str_warn));
                    end
            end
            if s_options.Verbose
                disp(output.message)
            end

            result = ODEresult(net, obj, s_options, flag, output, t0, c_phase);
        end
    end

    methods (Static, Hidden)
        function str = progress_mode(val)
        % Value of the Name-Value option Progress: true -> "dialog", false -> "none"
            if islogical(val) || isnumeric(val)
                if val
                    str = "dialog";
                else
                    str = "none";
                end
            else
                str = string(val);
            end
        end
    end

    methods (Static, Access=private)

        function initialize_index(net)
            % Method for assigning state variable numbers to each device and bus.
            % Execute this before performing analysis using the ODE solver.         
            
            % Global controllers must not read the indices of a component outside the network.
            for k = 1:numel(net.a_GlobalController)
                gcon = net.a_GlobalController{k};
                for idx = 1:numel(gcon.controlledUnits)
                    unit = gcon.controlledUnits{idx};
                    if isempty(unit.a_Bus) || ~isequal(unit.a_Bus.a_PowerNetwork, net)
                        error(msg("GUILDA:ODEsolver:ForeignControlledUnit", char(gcon.str_tag), char(unit.str_tag), char(net.str_tag)))
                    end
                end
            end

            a_bus = net.a_Bus;

            idx_TGT = 0;                       
            
            for i=1:numel(a_bus)
                a_comp = a_bus{i}.a_Component;

                for j=1:numel(a_comp)                    
                    % The component, then its local controllers depth first (get_variable_map)
                    set_idx(a_comp{j});                                                                            
                    set_idx_controllers(a_comp{j});
                end
            end

            % Global controllers: states after the components, in the order of a_GlobalController.
            % Their inputs are states of the controlled units and their outputs are inputs of them.
            a_gcon = net.a_GlobalController;
            for k = 1:numel(a_gcon)
                gcon = a_gcon{k};
                nxgc = length(gcon.sv_x);
                gcon.iv_odeX = idx_TGT + (1:nxgc)';
                idx_TGT = idx_TGT + nxgc;

                nConUnit = gcon.controlledUnits;
                gcon.iv_odeU = zeros(numel(nConUnit),1);
                gcon.iv_odeY = zeros(numel(nConUnit),1);
                for idx = 1:numel(nConUnit)
                    gcon.iv_odeU(idx) = nConUnit{idx}.iv_odeX( nConUnit{idx}.sv_x==gcon.sv_u );
                    gcon.iv_odeY(idx) = nConUnit{idx}.iv_odeU( nConUnit{idx}.sv_u==gcon.sv_y );
                end
            end

            for i=1:numel(a_bus)
                a_bus{i}.iv_odeX = idx_TGT + (1:2).';
                idx_TGT = idx_TGT + 2;
                a_bus{i}.iv_odeI = idx_TGT + (1:2).';                
                idx_TGT = idx_TGT + 2;                
            end

            function set_idx_controllers(parent)
                % Each controller under parent and the controllers nested in it, depth first
                for k_con = 1:numel(parent.a_LocalController)
                    con = parent.a_LocalController{k_con};
                    set_idx(con);
                    % iv_odeY(k): the input of the parent driven by the output sv_y(k), by name
                    [~, iv_y] = ismember(con.sv_y, parent.sv_u);
                    con.iv_odeY = parent.iv_odeU(iv_y);
                    set_idx_controllers(con);
                end
            end

            function set_idx(OBJ)
                % The inputs driven by the outputs of the controllers under OBJ, by name
                % (their outputs stacked in the order of a_LocalController; disjoint names)
                if OBJ.l_hasController
                    c_y = cellfun(@(c) reshape(string(c.sv_y),[],1), OBJ.a_LocalController, 'UniformOutput', false);
                    [OBJ.lv_odeUfromLC, OBJ.iv_odeYtoU] = ismember(OBJ.sv_u, vertcat(strings(0,1), c_y{:}));
                end

                nx = length(OBJ.sv_x);
                nu = length(OBJ.sv_u);

                OBJ.iv_odeX = idx_TGT + (1:nx)';    
                idx_TGT = idx_TGT + nx;

                OBJ.iv_odeU = idx_TGT + (1:nu)';
                idx_TGT = idx_TGT + nu;                
            end
            
        end

                

        function c_open = get_open_branches(tab_phase, c_odeEvnt)
            % Tags of the branches open in each phase (OpenBranch of its active events)
            c_open = cell(height(tab_phase), 1);
            for tp = 1:height(tab_phase)
                c_ev = c_odeEvnt(tab_phase{tp,3:end});
                c_br = cellfun(@(e) e.OpenBranch, c_ev, 'UniformOutput', false);
                c_open{tp} = unique(vertcat(strings(0,1), c_br{:}));
            end
        end

        function ctx = set_admittance(ctx, sv_open, l_force)
            % ctx.Ymat (real 2n x 2n, I = Y*V) and ctx.absYmat with the branches sv_open
            % left out of the bus admittance matrix. Rebuilt only when the set changes.
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

        function o = set_equations(o, ctx, RM, EM, lg, Mass)
            % The mass matrix, right-hand side and Jacobian of a phase. They hold a copy of ctx.
            % A mass matrix that is not diagonal (e.g. of a controller) is made the identity on the
            % differential variables, by solving the differential equations with its block:
            % M*x' = f becomes x'(d) = M(rd,d) \ f(rd), 0 = f(ra). The solutions are the same, and
            % for a diagonal mass matrix the consistency step of the solver changes only the
            % algebraic variables, while for a sparse one that is not diagonal it moves all of
            % them (see CalculateInitialCondition).
            lv_dif = full(any(Mass ~= 0, 1)).';
            lv_eqD = full(any(Mass ~= 0, 2));
            if ~isdiag(Mass) && nnz(lv_dif) == nnz(lv_eqD)
                dMd = decomposition(Mass(lv_eqD, lv_dif));
                Mass = diag(double(lv_dif));
                if ctx.l_sparse
                    Mass = sparse(Mass);
                end
                to_dif = @(f) ODEsolver.solve_differential(f, dMd, lv_dif, lv_eqD);
                o.ODEFcn   = @(t,x) to_dif(ODEsolver.getODEFunction(ctx,t,x,RM,EM,lg));
                o.Jacobian = @(t,x) to_dif(ODEsolver.getODEJacobian(ctx,t,x,RM,EM,lg));
            else
                o.ODEFcn   = @(t,x) ODEsolver.getODEFunction(ctx,t,x,RM,EM,lg);
                o.Jacobian = @(t,x) ODEsolver.getODEJacobian(ctx,t,x,RM,EM,lg);
            end
            o.MassMatrix = Mass;
        end

        function g = solve_differential(f, dMd, lv_dif, lv_eqD)
            % Rows of f (a vector or a Jacobian) for the identity mass matrix (see set_equations)
            g = f;
            g(lv_dif,:)  = dMd \ f(lv_eqD,:);
            g(~lv_dif,:) = f(~lv_eqD,:);
        end

        function l = is_false_index_error(ctx, me)
            % With sparse matrices, the index check of the solver can fail for a DAE of index 1:
            % condest of the sparse algebraic block can be far above the true condition number
            % (daeic12 tests eps*nnz(J)*condest(J) > 1). A DAE of a higher index fails with
            % dense matrices too, and that error is reported.
            l = ctx.l_sparse && endsWith(string(me.identifier), ":IndexGTOne");
        end

        function l = is_numerical_failure(me, o)
            % The errors with which the solver gives up on a phase. ode.solve rethrows the errors
            % of the right-hand side without its stack, so only the identifier tells them from
            % the errors of input functions and models: any other identifier is not one of these.
            % The mass matrix error is checked against the phase, as an input function may
            % call an ode solver of its own.
            str_id = string(me.identifier);
            l = ismember(str_id, ["MATLAB:daeic12:NeedBetterY0", "MATLAB:daeic12:IndexGTOne", ...
                                  "MATLAB:daeic3:NeedBetterY0", "MATLAB:daeic3:IndexGTOne", ...
                                  "MATLAB:decic:IndexGTOne", "MATLAB:decic:ConvergenceFail"]) ...
                || (ismember(str_id, ["MATLAB:ode15s:MassMatrixAllZero", "MATLAB:ode23t:MassMatrixAllZero"]) ...
                    && nnz(o.MassMatrix.MassMatrix) == 0);
        end

        function [ctx, o] = use_dense(ctx, o, x0, RM, EM, lg, l_verbose, Mass)
            % Solve the current phase again and the next phases with dense matrices.
            ctx.l_sparse = false;
            ctx.Ymat     = full(ctx.Ymat);
            ctx.absYmat  = full(ctx.absYmat);
            o.InitialValue = x0;
            o.InitialSlope = zeros(0,1);
            o = ODEsolver.set_equations(o, ctx, RM, EM, lg, full(Mass));
            lastwarn("");
            if l_verbose
                disp("The solver rejected the sparse matrices: using dense matrices.")
            end
        end

        function c_unit = get_units(net)
            % What getODEFunction reads for each component, fixed during a run
            c_comp = tools.cellfun(@(b) b.a_Component, net.a_Bus);
            c_comp = vertcat(cell(0,1), c_comp{:});
            c_unit = cell(size(c_comp));
            for i = 1:numel(c_comp)
                cj = c_comp{i};
                c_unit{i} = struct("ue", cj.rv_Uequilibrium, "idx_U", cj.iv_odeU, ...
                                   "idx_V", cj.a_Bus.iv_odeX, "idx_I", cj.a_Bus.iv_odeI);
                c_unit{i}.comp = cj;           % not an argument of struct: Component overloads it
            end
        end

        function restore_working_data(net)
            % Put the working data set during a run back to its initial values,
            % also after an error, so that the analysis leaves the model unchanged.
            ODEsolver.set_gc_connect(net, strings(0,1));
            a_bus = net.a_Bus;
            for i = 1:numel(a_bus)
                a_bus{i}.l_isFault = false;
                a_Comp = a_bus{i}.a_Component;
                for j = 1:numel(a_Comp)
                    a_Comp{j}.l_isConnect = true;
                    a_Comp{j}.rv_Xoffset = [];
                    a_Comp{j}.rv_Uoffset = [];
                end
            end
        end

        function set_gc_connect(net, str_trip)
            % Global controllers named in str_trip are tripped (l_isConnect = false),
            % the others connected. Components are set by ODEevent.
            a_GCs = net.a_GlobalController;
            for k = 1:numel(a_GCs)
                a_GCs{k}.l_isConnect = ~ismember(a_GCs{k}.str_tag, str_trip);
            end
        end

        function odeX = getODEFunction(ctx, t, x, RM, EM, lg) %#ok
            % Method for retrieving the DAE system to be analyzed.            
            
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

                odeX(a_GC.iv_odeX) = a_GC.f_dx(t,x_GC,[],[],u_connect*u_GC);                
                y_GC(a_GC.iv_odeY) = y_GC(a_GC.iv_odeY) + a_GC.f_Y(t,x_GC,[],[],u_connect*u_GC);
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

                odeX = get_dx_algebraic(unit.comp, t, x, x(unit.idx_V), x(unit.idx_I), ue, odeX);
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

        function odeJac = getODEJacobian(ctx, t, x, RM, EM, lg) %#ok
            % Method for obtaining the Jacobian of the DAE system under analysis.

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

                % [Axx_GC, Bxu_GC, Bxv_GC, Bxi_GC, Cyx_GC, Dyu_GC, Dyv_GC, Dyi_GC, ~, ~, ~, ~] = getSubJacobian(a_GC, t, x_GC, [], [], u_GC);                
                [Axx_GC, Bxv_GC, Bxi_GC, Bxu_GC] = a_GC.f_JacobiDx(t,x_GC,[],[],u_GC);
                [Cyx_GC, Dyv_GC, Dyi_GC, Dyu_GC] = a_GC.f_JacobiY(t,x_GC,[],[],u_GC);                                              

                odeJac(lv_GC, lh_GC) = odeJac(lv_GC, lh_GC) + [  Axx_GC,   Bxv_GC,   Bxu_GC,  Bxi_GC;
                                                                -Cyx_GC,  -Dyv_GC,  -Dyu_GC, -Dyi_GC];
                               
            end

            for i=1:numel(a_bus)                
                cm = a_bus{i}.a_Component;

                idx_V = a_bus{i}.iv_odeX;
                idx_I = a_bus{i}.iv_odeI;

                Vi = x(idx_V);
                Ii = x(idx_I);

                for j=1:numel(cm)
                    cj = cm{j};

                    idx_X = cj.iv_odeX;
                    idx_U = cj.iv_odeU;
                    idx_Y = cj.iv_odeY;

                    xi = x(idx_X);        
                    ui = x(idx_U);                 

                    % [Axx, Bxu, Bxv, Bxi, Cyx, Dyu, Dyv, Dyi, Cix, Diu, Div, Dii] = getSubJacobian(cj,t,xi,Vi,Ii,ui);
                    [Axx, Bxv, Bxi, Bxu] = cj.f_JacobiDx(t,xi,Vi,Ii,ui);
                    [Cix, Div, Dii, Diu] = cj.f_JacobiI(t,xi,Vi,Ii,ui);
                    [Cyx, Dyv, Dyi, Dyu] = cj.f_JacobiY(t,xi,Vi,Ii,ui);

                    rh = [idx_X; idx_U; idx_V; idx_I];
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
                            odeJac(con.iv_odeU(lv_Y), rh) = odeJac(con.iv_odeU(lv_Y), rh) ...
                                                          + [-Cyx(iv_y,:), -Dyu(iv_y,:), -Dyv(iv_y,:), -Dyi(iv_y,:)];
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

                        [Axx_LC, Bxv_LC, Bxi_LC, Bxu_LC] = con.f_JacobiDx(t,xi_LC,Vi,Ii,ui_LC);
                        [Cyx_LC, Dyv_LC, Dyi_LC, Dyu_LC] = con.f_JacobiY(t,xi_LC,Vi,Ii,ui_LC);

                        % Its outputs drive the inputs of its parent (rows idx_Y_LC)
                        rh_LC = [idx_X_LC; idx_U_LC; idx_V; idx_I];
                        rv_LC = [idx_X_LC; idx_Y_LC];

                        odeJac(rv_LC, rh_LC) = odeJac(rv_LC, rh_LC) + [ Axx_LC,  Bxu_LC,  Bxv_LC,  Bxi_LC; ...
                                                                       -Cyx_LC, -Dyu_LC, -Dyv_LC, -Dyi_LC];

                        odeJac(idx_U_LC,idx_U_LC) = odeJac(idx_U_LC,idx_U_LC) + eye(length(idx_U_LC));
                    end
            
                    % A tripped unit gives no current (see get_dx_algebraic)
                    l_c = double(cj.l_isConnect);
                    odeJac(rv,rh) = odeJac(rv,rh) + [ Axx,  Bxu,  Bxv,  Bxi;...                                                     
                                                     -l_c*Cix, -l_c*Diu, -l_c*Div, -l_c*Dii]; 

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
                
        

        function [x0, M0] = getNextPhase(ctx, x0, M0, RM, EM) %#ok
            a_bus  = ctx.net.a_Bus;            

            x0 = EM * x0;
            M0 = EM * M0 * EM.';

            for i=1:numel(a_bus)
                a_Comp = a_bus{i}.a_Component;                

                b_idx_V = a_bus{i}.iv_odeX;
                b_idx_I = a_bus{i}.iv_odeI;

                for j=1:numel(a_Comp)
                    if isa(a_Comp{j}, 'component.generator.abstract') && ~a_Comp{j}.l_isConnect
                        c_idx = a_Comp{j}.iv_odeX;
                        b_idx = a_bus{i}.iv_odeX;
                        x0(c_idx) = a_Comp{j}.get_equilibrium([1,1j]*x0(b_idx), 0, 0, 0);                         
                        
                        % Its local controllers restart from their equilibrium too
                        c_LC = controllers_depth_first(a_Comp{j});
                        for k = 1:numel(c_LC)
                            v_LC = c_LC{k}.iv_odeX;
                            x0(v_LC) = c_LC{k}.rv_Xequilibrium;
                            M0(v_LC, v_LC) = tools.read_mass(c_LC{k});
                        end

                        M0(c_idx, c_idx) = tools.read_mass(a_Comp{j});
                    end
                end

                if a_bus{i}.l_isFault
                    x0([b_idx_V;b_idx_I]) = [real(a_bus{i}.c_Vequilibrium);
                                             imag(a_bus{i}.c_Vequilibrium);
                                             real(a_bus{i}.c_Iequilibrium);
                                             imag(a_bus{i}.c_Iequilibrium)];
                end
            end

            % A global controller tripped in the phase just solved restarts from its
            % equilibrium, like a tripped generator (EM left its states and mass at zero)
            a_GCs = ctx.net.a_GlobalController;
            for k = 1:numel(a_GCs)
                if ~a_GCs{k}.l_isConnect
                    idx_GC = a_GCs{k}.iv_odeX;
                    x0(idx_GC) = a_GCs{k}.rv_Xequilibrium;
                    M0(idx_GC, idx_GC) = tools.read_mass(a_GCs{k});
                end
            end
        end
    end
end

function c_LC = controllers_depth_first(parent)
% The local controllers under parent and the controllers nested in them, depth first
% (the order of the state vector, see initialize_index)
    c_LC = cell(0,1);
    for k = 1:numel(parent.a_LocalController)
        con  = parent.a_LocalController{k};
        c_LC = [c_LC; {con}; controllers_depth_first(con)]; %#ok<AGROW>
    end
end

function validate_options(opt)
% Value checks of the Name-Value options (names are already checked by resolve_options)
    arguments
        opt.Solver               (1,1) matlab.ode.SolverID
        opt.SolverOptions        (1,1) matlab.ode.Options
        opt.Tolerance            (1,1) double {mustBePositive, mustBeBetween(opt.Tolerance,1e-15,1e-3,"closed")}
        opt.AbsoluteTolerance    (1,1) double {mustBePositive, mustBeBetween(opt.AbsoluteTolerance,1e-15,1e-3,"closed")}
        opt.SeparateComplexParts (1,1) matlab.lang.OnOffSwitchState
        opt.TimeLimit            (1,1) double {mustBePositive}
        opt.Progress             {mustBeProgress}
        opt.Verbose              (1,1) logical
        opt.Plot                 (1,1) logical
    end
end

function mustBeProgress(val)
    if (islogical(val) || isnumeric(val)) && isscalar(val)
        return
    end
    mustBeMember(string(val), ["none","disp","dialog"]);
end

function check_islands(net, c_open, tab_phase)
% Each set of open branches must leave every bus connected to a component: nothing sets
% the voltages of a part of the network without components (with no shunt either, the
% DAE is singular). Checked for all phases before the integration starts.
    sv_bus = string(net.a_Bus);
    sv_br  = string(net.a_Branch);
    iv_bus = zeros(numel(sv_br), 2);
    for k = 1:numel(sv_br)
        [~, iv_bus(k,:)] = ismember(string(net.a_Branch{k}.a_Bus), sv_bus);
    end
    lv_comp = cellfun(@(b) ~isempty(b.a_Component), net.a_Bus);
    for tp = 1:numel(c_open)
        if isempty(c_open{tp})
            continue
        end
        lv_on   = ~ismember(sv_br, c_open{tp});
        G       = graph(iv_bus(lv_on,1), iv_bus(lv_on,2), [], numel(sv_bus));
        iv_part = conncomp(G);
        lv_dead = ~ismember(iv_part, iv_part(lv_comp(:).'));
        if any(lv_dead)
            error(msg("GUILDA:ODEsolver:OpenBranchIsland", num2str(tp), num2str(tab_phase{tp,"t1"}), ...
                      num2str(tab_phase{tp,"t2"}), char(join(c_open{tp}, ", ")), char(join(sv_bus(lv_dead), ", "))));
        end
    end
end

function print_phases(tab_phase, str_evt)
% Verbose: one line per integration phase with its active events
    fprintf("Time simulation: %d phase(s)\n", height(tab_phase));
    for k = 1:height(tab_phase)
        sv = str_evt(tab_phase{k,3:end});
        sv = sv(~contains(sv,"NoAction"));
        if isempty(sv)
            sv = "-";
        end
        fprintf("  phase %2d: t = [%g, %g]  events: %s\n", k, tab_phase{k,"t1"}, tab_phase{k,"t2"}, join(sv, ", "));
    end
end

function [Axx, Bxu, Bxv, Bxi, Cyx, Dyu, Dyv, Dyi, Cix, Diu, Div, Dii] = getSubJacobian(OBJ, t, xi, Vi, Ii, ui)
                
    Axx = OBJ.JacobiAxx(t,xi,Vi,Ii,ui);
    Bxv = OBJ.JacobiBxv(t,xi,Vi,Ii,ui);
    Bxi = OBJ.JacobiBxi(t,xi,Vi,Ii,ui);                         
    Bxu = OBJ.JacobiBxu(t,xi,Vi,Ii,ui);                         

    Cyx = OBJ.JacobiCyx(t,xi,Vi,Ii,ui);
    Dyv = OBJ.JacobiDyv(t,xi,Vi,Ii,ui);
    Dyi = OBJ.JacobiDyi(t,xi,Vi,Ii,ui);
    Dyu = OBJ.JacobiDyu(t,xi,Vi,Ii,ui);

    Cix = OBJ.JacobiCix(t,xi,Vi,Ii,ui);
    Div = OBJ.JacobiDiv(t,xi,Vi,Ii,ui);
    Dii = OBJ.JacobiDii(t,xi,Vi,Ii,ui);
    Diu = OBJ.JacobiDiu(t,xi,Vi,Ii,ui);
end