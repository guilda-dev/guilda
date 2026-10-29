classdef (Sealed = true) odeSimulator < auxiliary
% <@Desc>
% Solver of the time simulation (net.simulate). net.solver_ODE holds one; its properties
% are the stored defaults of net.simulate and are kept between runs. Name-Value options of
% a call override them for that call only (see OptionMap and get_options). The solver holds
% settings only: the network, the event time table and the trajectories of a run are local
% to solve, and the result is returned as an odeSimulationResult.
% The DAE of the network is integrated phase by phase: a phase is a time interval in which
% the set of active events (odeEventSet) does not change. Each phase is solved with the
% MATLAB ode object (Solver, SolverOptions, RelativeTolerance, AbsoluteTolerance).
% <@Role> Class Category
% <@Constructor>
% obj = odeSimulator()
% Reads the defaults from GUILDA.config("TimeSimulation").

    properties (Access=public)
        % <@Desc> Solver of the MATLAB ode object (Solver property of ode). The DAE of the
        % network has a singular mass matrix, so it needs a solver for DAEs (ode15s, ode23t).
        % <@Role> Settings
        % <@Type> matlab.ode.SolverID
        % <@Size> 1x1
        Solver         matlab.ode.SolverID = "ode15s"

        % <@Desc> Options of the solver (SolverOptions property of ode), e.g. MaxStep or
        % InitialStep. Its class must match Solver.
        % <@Role> Settings
        % <@Type> matlab.ode.Options
        % <@Size> 1x1
        SolverOptions  matlab.ode.Options  = matlab.ode.options.ODE15s

        % <@Desc> Relative error tolerance of the integration (RelativeTolerance of ode,
        % RelTol of odeset). Name-Value option Tolerance.
        % <@Role> Settings
        % <@Type> double
        % <@Size> 1x1
        RelativeTolerance   (1,1) double {mustBePositive, mustBeBetween(RelativeTolerance,1e-15,1e-3, "closed")} = 1e-4

        % <@Desc> Absolute error tolerance of the integration (AbsoluteTolerance of ode,
        % AbsTol of odeset). Name-Value option AbsoluteTolerance.
        % <@Role> Settings
        % <@Type> double
        % <@Size> 1x1
        AbsoluteTolerance   (1,1) double {mustBePositive, mustBeBetween(AbsoluteTolerance,1e-15,1e-3, "closed")} = 1e-6

        % <@Desc> SeparateComplexParts property of the ode object.
        % <@Role> Settings
        % <@Type> matlab.lang.OnOffSwitchState
        % <@Size> 1x1
        SeparateComplexParts matlab.lang.OnOffSwitchState = "off"

        % <@Desc> Progress display during the integration: "dialog" (a waitbar), "disp"
        % (a text bar in the Command Window) or "none". Name-Value option Progress, which
        % also accepts true ("dialog") and false ("none").
        % <@Role> Settings
        % <@Type> string
        % <@Size> 1x1
        Progress            (1,1) string {mustBeMember(Progress,["none","disp","dialog"])} = "dialog"

        % <@Desc> Limit of the computation (wall-clock) time [s] of each integration phase.
        % When it is exceeded, the simulation stops at the time reached, and the result has
        % flag = 0 ("stopped by TimeLimit"). Inf for no limit.
        % <@Role> Settings
        % <@Type> double
        % <@Size> 1x1
        TimeLimit           (1,1) double {mustBePositive} = 10

        % <@Desc> Print the phases before the integration and the outcome (output.message)
        % after it.
        % <@Role> Settings
        % <@Type> logical
        % <@Size> 1x1
        Verbose             (1,1) logical = false

        % <@Desc> Call result.Plot() after each simulation.
        % <@Role> Settings
        % <@Type> logical
        % <@Size> 1x1
        Plot                (1,1) logical = false
    end

    properties (Constant)
        % <@Desc> Name-Value options of net.simulate and the solver property each one sets
        % (input of tools.resolve_options). Solver, Tolerance, TimeLimit, Progress, Verbose
        % and Plot are common names; Tolerance is the relative tolerance.
        % AbsoluteTolerance, SolverOptions and SeparateComplexParts keep the names of the
        % MATLAB ode object.
        % <@Role> Settings
        % <@Type> struct
        % <@Size> 1x1
        OptionMap = struct( ...
            "Solver",               "Solver", ...
            "SolverOptions",        "SolverOptions", ...
            "Tolerance",            "RelativeTolerance", ...
            "AbsoluteTolerance",    "AbsoluteTolerance", ...
            "SeparateComplexParts", "SeparateComplexParts", ...
            "TimeLimit",            "TimeLimit", ...
            "Progress",             {{"Progress", @(v) odeSimulator.progress_mode(v)}}, ...
            "Verbose",              "Verbose", ...
            "Plot",                 "Plot")
    end

    properties (Dependent, Hidden)
        Reporter                                    % COMPAT(v3) old name of Progress (v3_ode_reporter)
    end

    properties (SetAccess=private, Hidden)
        % Version of this class
        Ver (1,1) double = 2.0
    end

    methods
        function obj = odeSimulator()
            sct = GUILDA.config("TimeSimulation");
            obj.AbsoluteTolerance   = sct.AbsoluteTolerance.Value;
            obj.RelativeTolerance   = sct.RelativeTolerance.Value;
            obj.SeparateComplexParts= sct.SeparateComplexParts.Value;
            obj.Progress            = sct.Reporter.Value;
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
        % <@Desc>
        % Effective settings of one run: every stored setting of the solver, with the
        % Name-Value overrides of the call applied. The solver itself is not changed.
        % A name that is not in OptionMap stops with GUILDA:resolve_options:UnknownName;
        % an invalid value stops with the validation error of the option.
        % <@Role> Settings
        % <@Summary> Stored settings + call-time overrides, as a struct.
        % <@Signatures>
        % [
        %   "s_options = get_options(obj)",
        %   "s_options = get_options(obj, {Name1, Value1, ...})"
        % ]
        % <@Parameters>
        % [
        %   {"Name": "obj", "Type": "odeSimulator", "Description": "Solver holding the defaults (net.solver_ODE).", "Required": true, "Default": "-"},
        %   {"Name": "nv", "Type": "cell", "Description": "Name-Value overrides: Solver, SolverOptions, Tolerance, AbsoluteTolerance, SeparateComplexParts, TimeLimit, Progress, Verbose, Plot.", "Required": false, "Default": "{}"}
        % ]
        % <@Returns>
        % [
        %   {"Name": "s_options", "Type": "struct", "Description": "One field per setting (Solver, SolverOptions, RelativeTolerance, AbsoluteTolerance, SeparateComplexParts, Progress, TimeLimit, Verbose, Plot)."}
        % ]
            arguments
                obj
                nv (1,:) cell = {}
            end
            s_given = tools.resolve_options(obj, odeSimulator.OptionMap, nv);
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
        % <@Desc>
        % Runs the time simulation of net over time with the events c_events and the
        % effective settings s_options, and returns the trajectories as an
        % odeSimulationResult. The solver is only read: nothing is written back into it.
        % The simulation working data of the models (iv_odeX, iv_odeU, iv_odeY, iv_odeI) is
        % rebuilt for this run. Called by net.simulate, which also checks that the
        % equilibrium is up to date; calling it directly is for advanced use.
        % flag is 1 when the simulation reached the end time, 0 when it stopped because a
        % phase exceeded TimeLimit, and -1 when the solver stopped before the end time
        % (output.message has the reason). In the last two cases the result holds the
        % trajectories up to the time reached (output.tEnd).
        % <@Role> Analysis
        % <@Summary> Integrate the network DAE with the given settings.
        % <@Signatures>
        % [
        %   "[result, flag, output] = solve(obj, net, time)",
        %   "[result, flag, output] = solve(obj, net, time, c_events, s_options)"
        % ]
        % <@Parameters>
        % [
        %   {"Name": "obj", "Type": "odeSimulator", "Description": "Solver (net.solver_ODE).", "Required": true, "Default": "-"},
        %   {"Name": "net", "Type": "PowerNetwork", "Description": "Network initialized by net.initialize.", "Required": true, "Default": "-"},
        %   {"Name": "time", "Type": "double vector", "Description": "Simulation time [t0, tend] (or [] for the time span of the events).", "Required": true, "Default": "-"},
        %   {"Name": "c_events", "Type": "cell of odeEventSet", "Description": "Events of the run.", "Required": false, "Default": "{}"},
        %   {"Name": "s_options", "Type": "struct", "Description": "Effective settings (output of get_options).", "Required": false, "Default": "obj.get_options()"}
        % ]
        % <@Returns>
        % [
        %   {"Name": "result", "Type": "odeSimulationResult", "Description": "Trajectories of the buses and components."},
        %   {"Name": "flag", "Type": "double", "Description": "1 completed, 0 stopped by TimeLimit, -1 stopped by the solver."},
        %   {"Name": "output", "Type": "struct", "Description": "Details: message, tEnd, phases (time table of the phases), nPhases, nPhasesDone."}
        % ]
            arguments
                obj
                net
                time      (:,1) double = []
                c_events  cell = {}
                s_options (1,1) struct = obj.get_options()
            end
            t0 = tic;

            % Without events, add an empty event so that odeEventSet.table is dispatched.
            if isempty(c_events)
                t_start = 0;
                if ~isempty(time)
                    t_start = time(1);
                end
                c_events = {odeEventSet("NoAction", net, "TimeSpan", t_start)};
            end

            [tab_phase, c_odeEvnt] = table(c_events{:}, "time", time);
            odeSimulator.initialize_index(net);

            ctx = struct();
            ctx.net     = net;
            ctx.Ymat    = tools.complex2matrix(net.get_admittance_matrix.Variables);
            ctx.rv_odeV = cell2mat(tools.cellfun(@(b) b.iv_odeX, net.a_Bus));

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
            odeProg  = odeProgress( s_options.Progress, [ts,te], s_options.TimeLimit);
            o.SolverOptions.OutputFcn = odeProg.OutputFcn;
            o.EventDefinition = odeEvent("EventFcn", @(t,x) odeProg.Events(), "Response", "stop");

            c_phase = cell(1,0);
            flag    = 1;
            tp      = 1;
            while tp <= np

                % Retrieving events related to ground faults and circuit tripping.
                TT = tab_phase(tp,:);

                odeEvents = c_odeEvnt( TT{:,3:end} );

                t1 = TT{1, 't1'};
                t2 = TT{1, 't2'};

                setEventCondition(odeEvents{:}, "TimePhase", [t1,t2], "Iteration", tp);

                [EM, RM, lv_FBorTC, x0, Mass] = getInitialCondition(odeEvents{:}, "x0", x0, "M0", Mass);

                o.InitialValue = x0;
                o.MassMatrix   = Mass;
                o.ODEFcn       = @(t,x) odeSimulator.getODEFunction(ctx,t,x,RM,EM,~lv_FBorTC);
                o.Jacobian     = @(t,x) odeSimulator.getODEJacobian(ctx,t,x,RM,EM,~lv_FBorTC);

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

                try
                    % When solving the equation, specify [0, duration of each phase]
                    sol = solve(o, 0, t2-t1);
                catch me

                    splitMSG = strsplit(me.identifier,':');

                    if isequal(splitMSG{end},'NeedBetterY0')
                        [ODEfcn, x0, ~, options] = CalculateInitialCondition(o, options);
                    else
                        odeProg.OutputFcn([],[],"break")
                        throw(me)
                    end


                    % After performing error bundling, solve the DAE system again.
                    try
                        [t,y] = ode15s(ODEfcn, [0,t2-t1], x0, options);
                        sol = struct('Time', t.', 'Solution', y.');

                    catch
                        odeProg.OutputFcn([],[],"break")
                        error(msg('GUILDA:odeSimulator:UnfeasibleDAE'))
                    end
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

                [x0, Mass] = odeSimulator.getNextPhase(ctx, reshape(sol.Solution(:,end),[],1), o.MassMatrix.MassMatrix, RM, EM);

                tp = tp + 1;
            end

            output = struct();
            output.tEnd        = c_phase{end}.t{end,1};
            output.nPhases     = np;
            output.nPhasesDone = numel(c_phase) - (flag ~= 1);
            output.phases      = tab_phase;
            switch flag
                case 1
                    output.message = sprintf("The simulation reached t = %g s (%d phases).", output.tEnd, np);
                case 0
                    output.message = sprintf("The simulation stopped at t = %g s of %g s: phase %d exceeded TimeLimit = %g s. " + ...
                                             "Increase TimeLimit (Inf for no limit).", output.tEnd, te, tp, s_options.TimeLimit);
                otherwise
                    output.message = sprintf("The solver stopped at t = %g s of %g s in phase %d (see the warning of the solver). " + ...
                                             "Try a smaller Tolerance, other SolverOptions, or check the model.", output.tEnd, te, tp);
            end
            if s_options.Verbose
                disp(output.message)
            end

            result = odeSimulationResult(net, obj, s_options, flag, output, t0, c_phase);
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
            
            a_bus = net.a_Bus;

            idx_TGT = 0;                       
            
            for i=1:numel(a_bus)
                a_comp = a_bus{i}.a_Component;

                for j=1:numel(a_comp)                    
                    set_idx(a_comp{j});                                                                            

                    if ~isempty(a_comp{j}.a_LocalController)
                        a_LC1 = a_comp{j}.a_LocalController{1};
                        set_idx(a_LC1);                                                

                        a_LC1.iv_odeY = a_comp{j}.iv_odeU( a_comp{j}.sv_u==a_LC1.sv_y );                        

                        if ~isempty(a_LC1.a_LocalController)
                            a_LC2 = a_LC1.a_LocalController{1};
                            set_idx(a_LC2);                                      

                            a_LC2.iv_odeY = a_LC1.iv_odeU( a_LC1.sv_u==a_LC2.sv_y );
                            a_comp{j}.iv_odeY = a_LC2.iv_odeU;
                        end
                    end                    
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

            function set_idx(OBJ)
                nx = length(OBJ.sv_x);
                nu = length(OBJ.sv_u);

                OBJ.iv_odeX = idx_TGT + (1:nx)';    
                idx_TGT = idx_TGT + nx;

                OBJ.iv_odeU = idx_TGT + (1:nu)';
                idx_TGT = idx_TGT + nu;                
            end
            
        end

                

        function odeX = getODEFunction(ctx, t, x, RM, EM, lg) %#ok
            % Method for retrieving the DAE system to be analyzed.            
            
            x = EM*x; 

            odeX = zeros(size(x));
            odeV = x(ctx.rv_odeV);

            I = ctx.Ymat*odeV;
            
            a_bus = ctx.net.a_Bus;

            % Outputs of all global controllers, at the indices of the component inputs they drive
            y_GC = zeros(size(x), 'like', x);
            a_GCs = ctx.net.a_GlobalController;
            for k = 1:numel(a_GCs)
                a_GC = a_GCs{k};

                x_GC = x(a_GC.iv_odeX);
                u_GC = x(a_GC.iv_odeU);

                u_connect = tools.dcellfun(@(CU) CU.l_isConnect, a_GC.controlledUnits);

                odeX(a_GC.iv_odeX) = a_GC.f_dx(t,x_GC,[],[],u_connect*u_GC);                
                y_GC(a_GC.iv_odeY) = y_GC(a_GC.iv_odeY) + a_GC.f_Y(t,x_GC,[],[],u_connect*u_GC);
            end

            for i=1:numel(a_bus)
                a_comp = a_bus{i}.a_Component;

                idx_V = a_bus{i}.iv_odeX;
                idx_I = a_bus{i}.iv_odeI;

                Vi = x(idx_V);                                                                                             
                Ii = x(idx_I);                                                                                             

                for j=1:numel(a_comp)
                    cj = a_comp{j};
                    ue = cj.rv_Uequilibrium;       
                    ue = ue + y_GC( cj.iv_odeU );     % zero for inputs no global controller drives
                    ue = ue + cj.rv_Uoffset(t);
                    
                    odeX = get_dx_algebraic(cj, t, x, Vi, Ii, ue, odeX);
                end                

                odeX([idx_V;idx_I]) = odeX([idx_V;idx_I]) + [Ii;Ii - I([-1;0]+2*i)];
                
            end                    

            odeX = odeX(lg); 

        end

        function odeJac = getODEJacobian(ctx, t, x, RM, EM, lg) %#ok
            % Method for obtaining the Jacobian of the DAE system under analysis.

            x = EM*x;
            
            a_bus = ctx.net.a_Bus;

            odeJac = zeros(numel(x), numel(x));

            rv_Bus_V = zeros(0,1);
            rv_Bus_I = zeros(0,1);

            a_GCs = ctx.net.a_GlobalController;
            for k = 1:numel(a_GCs)
                a_GC = a_GCs{k};
                
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
                    
                    if ~isempty(cj.a_LocalController)
                        a_LC1 = cj.a_LocalController{1};                                            

                        if ~isempty(a_LC1.a_LocalController)
                            a_LC2 = a_LC1.a_LocalController{1};

                            idx_X_LC2 = a_LC2.iv_odeX;
                            idx_U_LC2 = a_LC2.iv_odeU;
                            idx_Y_LC2 = a_LC2.iv_odeY;

                            xi_LC2 = x(idx_X_LC2);                            
                            ui_LC2 = x(idx_U_LC2);                                                        

                            % [Axx_LC2, Bxu_LC2, Bxv_LC2, Bxi_LC2, Cyx_LC2, Dyu_LC2, Dyv_LC2, Dyi_LC2, ~, ~, ~, ~] = getSubJacobian(a_LC2, t, xi_LC2, Vi, Ii, ui_LC2);                                                                            
                            % [Cix, Div, Dii, Diu] = cj.f_JacobiI(t,xi,Vi,Ii,ui);         
                            [Axx_LC2, Bxv_LC2, Bxi_LC2, Bxu_LC2] = a_LC2.f_JacobiDx(t,xi_LC2,Vi,Ii,ui_LC2);
                            [Cyx_LC2, Dyv_LC2, Dyi_LC2, Dyu_LC2] = a_LC2.f_JacobiY(t,xi_LC2,Vi,Ii,ui_LC2);                                              
                            
                            rh_LC2 = [idx_X_LC2; idx_U_LC2; idx_V; idx_I];
                            rv_LC2 = [idx_X_LC2; idx_Y_LC2];

                            odeJac(rv_LC2, rh_LC2) = odeJac(rv_LC2, rh_LC2) + [ Axx_LC2,  Bxu_LC2,  Bxv_LC2,  Bxi_LC2; ...
                                                                               -Cyx_LC2, -Dyu_LC2, -Dyv_LC2, -Dyi_LC2];                            

                            
                            odeJac(idx_U_LC2,idx_U_LC2) = odeJac(idx_U_LC2,idx_U_LC2) + eye(length(idx_U_LC2));

                            odeJac(idx_Y, rh) = odeJac(idx_Y, rh) + [-Cyx, -Dyu, -Dyv, -Dyi];
                            
                        end 

                        idx_X_LC1 = a_LC1.iv_odeX;
                        idx_U_LC1 = a_LC1.iv_odeU;
                        idx_Y_LC1 = a_LC1.iv_odeY;


                        xi_LC1 = x(idx_X_LC1);
                        ui_LC1 = x(idx_U_LC1);                                      

                        % [Axx_LC1, Bxu_LC1, Bxv_LC1, Bxi_LC1, Cyx_LC1, Dyu_LC1, Dyv_LC1, Dyi_LC1, ~, ~, ~, ~] = getSubJacobian(a_LC1, t, xi_LC1, Vi, Ii, ui_LC1);                                                
                        [Axx_LC1, Bxv_LC1, Bxi_LC1, Bxu_LC1] = a_LC1.f_JacobiDx(t,xi_LC1,Vi,Ii,ui_LC1);
                        [Cyx_LC1, Dyv_LC1, Dyi_LC1, Dyu_LC1] = a_LC1.f_JacobiY(t,xi_LC1,Vi,Ii,ui_LC1);                                              
                        
                        rh_LC1 = [idx_X_LC1; idx_U_LC1; idx_V; idx_I];
                        rv_LC1 = [idx_X_LC1; idx_Y_LC1];

                        odeJac(rv_LC1, rh_LC1) = odeJac(rv_LC1, rh_LC1) + [ Axx_LC1,  Bxu_LC1,  Bxv_LC1,  Bxi_LC1; ...                                                                                   
                                                                           -Cyx_LC1, -Dyu_LC1, -Dyv_LC1, -Dyi_LC1];

                        odeJac(idx_U_LC1,idx_U_LC1) = odeJac(idx_U_LC1,idx_U_LC1) + eye(length(idx_U_LC1));
                        
                    end                                                                                                                                    
            
                    odeJac(rv,rh) = odeJac(rv,rh) + [ Axx,  Bxu,  Bxv,  Bxi;...                                                     
                                                     -Cix, -Diu, -Div, -Dii]; 

                    odeJac(idx_U,idx_U) = odeJac(idx_U,idx_U) + eye(length(idx_U));

                end

                rv_Bus_V(2*i+[-1;0]) = idx_V; 
                rv_Bus_I(2*i+[-1;0]) = idx_I; 
            end                               
                   
            odeJac(rv_Bus_I,rv_Bus_V) = odeJac(rv_Bus_I,rv_Bus_V) - ctx.Ymat;

            odeJac([rv_Bus_V; rv_Bus_I], rv_Bus_I) = odeJac([rv_Bus_V; rv_Bus_I], rv_Bus_I) + [eye(2*i); eye(2*i)];
            
            odeJac = odeJac(lg,lg);            

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
                        [x0(c_idx), u_equilibrium] = a_Comp{j}.get_equilibrium([1,1j]*x0(b_idx), 0+1j*0);                         
                        
                        if ~isempty(a_Comp{j}.a_LocalController)
                            a_LC1 = a_Comp{j}.a_LocalController{1};

                            v_LC1 = a_LC1.iv_odeX;                            
                            [x0(v_LC1), ~] = a_LC1.get_equilibrium([1,1j]*x0(b_idx), u_equilibrium);                         

                            M0(v_LC1, v_LC1) = a_LC1.f_Mass([], [], [], [],[]);
                            
                            if ~isempty(a_LC1.a_LocalController)
                                a_LC2 = a_LC1.a_LocalController{1};

                                v_LC2 = a_LC2.iv_odeX;                                
                                [x0(v_LC2), ~] = a_LC2.get_equilibrium([1,1j]*x0(b_idx), []);                         

                                M0(v_LC2, v_LC2) = a_LC2.f_Mass([], [], [], [],[]);
                            end
                        end

                        M0(c_idx, c_idx) = a_Comp{j}.f_Mass([], [], [], [], []);
                    end
                end

                if a_bus{i}.l_isFault
                    x0([b_idx_V;b_idx_I]) = [real(a_bus{i}.c_Vequilibrium);
                                             imag(a_bus{i}.c_Vequilibrium);
                                             real(a_bus{i}.c_Iequilibrium);
                                             imag(a_bus{i}.c_Iequilibrium)];
                end
            end            
        end
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