classdef ResultCPF < ResultBase
% Result of net.calculate_continuation_powerflow.
%
% Holds the load parameter lambda and the bus voltages at each point of the traced path,
% and the nose point (maximum loading). The loads of options.LoadBus are scaled by
% (1 + lambda). It holds computed values only; the settings of the buses and components
% stay with the network. plot_pvcurve draws the PV curves, get_point gives the operating
% point of a step. export writes the path as a table (CSV, Excel): tab_path.
%
% With the option Limits (see SolverCPF), `tab_switch` lists the PV buses switched to PQ
% at Qmin/Qmax of their generators: lambda and Step (index in rv_lambda) of the switch
% point, Bus, Limit ("Qmin"/"Qmax") and Bound (the fixed Q [pu]). `tab_stop` has one row
% when a "V" or "S" limit ended the path: lambda and Step of the last point, Class ("Bus"
% or "Branch"), Object (tag), Limit ("Vmin", "Vmax", "Smax") and Bound [pu]. Both have 0
% rows otherwise. When the path stops before the nose, r_lambdaMax is the lambda of the
% stop.
%
% The operating point of every step is kept for the network diagram, the spring-mass model
% and the linearization along the path: `tab_variable` and `rm_variable` have the layout of
% ResultODE (the rows x, Vre, Vim, u, uc of net.get_variable_map(); row k of rm_variable is
% step k, the index in rv_lambda as r_noseStep), `cm_Icomponent` the current of each
% component and `sct_network` a snapshot struct(net, false). get_point(Step) returns a
% point for net.get_sys, so net.get_sys({result, [1 result.r_noseStep]}) linearizes at the
% first point and at the nose (one section per step). At each step the bus injection is
% split to the components as net.initialize splits a power flow solution
% (tools.distribute_power: the components inject their CPF powers, the loads of LoadBus
% scaled by (1 + lambda); the free P of the slack bus and the free Q go to the components
% with Q = NaN, so a bus switched to PQ keeps its fixed Q), and (x, u) of each component
% and (x, uc) of its local controllers are their get_equilibrium values for that split
% (with UseInternalState, x of a component is its CPF state and u its rv_Uequilibrium).
% The local controllers get the state x of the component at the step as the fourth
% argument of get_equilibrium, and an input observed on the component takes the value of
% the component at the step. Their design (e.g. the gain K of local-LQR and pss-retrofit,
% with the equilibrium it was designed at) stays as net.initialize made it, so for such
% controllers the point of a later step is not exactly an equilibrium of the controller
% (see their help). The global controllers keep their equilibrium values. Values of
% a model whose get_equilibrium stops at a step (a limit of its range) are NaN at that
% step. Step 1 is the equilibrium of net.initialize.
%
% Voltage stability: `rv_sigmaMin` is the smallest singular value of the power flow
% Jacobian with respect to the unknowns (without the lambda column) at each step; it goes
% to 0 at the nose. `tab_weakbus` ranks the buses at the nose: Participation is |V| of each
% bus in the right singular vector of that singular value (largest 1), dVdLambda the
% average d|V|/dlambda [pu] from the first point to the nose (NaN when the nose is the
% first point). `r_marginP` [pu] is r_lambdaMax times the initial active power of every
% component actually scaled by (1 + lambda) (power drawn minus power generated): the
% components of LoadBus, and with UseInternalState every component. With
% UseInternalState the CPF scales every component, the generators included, so the sum
% is the power drawn minus the power generated over the whole network, which is minus
% the network losses: r_marginP is then usually negative. With UseInternalState, x of a
% component at a step is its CPF state and u is its equilibrium input rv_Uequilibrium
% (the CPF equations hold u fixed).
%
% Plots of the steps: every plot below takes the steps as its samples (rv_t = 1 ...
% n_step, named "Step", with the text "Step k (λ = ...)"; lambda is not monotonic past the
% nose), so G1.link(G2) keeps them in step with each other and with
% net.get_sys({result, steps}).plot_eigenvalue / plot_eigenvalue_path (the sections of
% that ResultLIN are the step numbers). G.set_time(k) shows step k; on a curve against
% lambda it puts a marker at step k. G.animate() and G.export_video(file) play one frame
% per step.
%
% - plot_pvcurve: |V| of the buses against lambda, the nose marked.
% - plot_diagram: network diagram (GraphNetDiagram) of each step from cm_Vbus,
%   cm_Icomponent and sct_network.
% - plot_spring_model: spring-mass picture (GraphSpring2D/3D) of each step from
%   tab_variable, rm_variable, cm_Icomponent and sct_network.
% - plot_stability_index: rv_sigmaMin against lambda, and the participation of the weak
%   buses at the nose (tab_weakbus).
% - plot_generator: P, Q or the Q margin (to the nearer of Qmin, Qmax) of the generators
%   (components with Q = NaN in powerflow) against lambda, the switches of tab_switch
%   marked.
% - plot_branch: P, |S|, loading |S|/Smax or the loss of the branches (or the total loss)
%   against lambda.
%
% The plots other than plot_pvcurve read the data of the steps; a result without it (a
% ResultCPF built by hand) stops with GUILDA:ResultCPF:NoStepData.
%
% `rm_x` is the CPF_Result.x_sol of v3: its rows are [|V|; angle V] of each bus (followed
% by the component states when options.UseInternalState is true), and lambda in the last
% row. `rm_xPredicted` is the CPF_Result.x_prd of v3 in the same layout.
%
% <@Examples>
% ```matlab
% net = network.IEEE14bus();
% net.initialize();
% [result, flag] = net.calculate_continuation_powerflow(LoadBus=["B009","B014"]);
% result.r_lambdaMax       % maximum loading (nose of the PV curve)
% result = net.calculate_continuation_powerflow(LoadBus=["B009","B014"], Limits="all");
% result.tab_switch        % PV buses switched to PQ at their Q limits
% result.tab_stop          % voltage or branch limit that ended the path
% result.tab_nose          % bus voltages at the nose
% result.tab_weakbus       % buses ranked by their participation at the nose
% x = result.get_point(result.r_noseStep);          % point for net.get_sys(x)
% lin = net.get_sys({result, [1 result.r_noseStep]});   % one section per step
% result.plot_pvcurve(Bus="all");  % PV curves of every bus
% G = result.plot_diagram();        % network diagram of each step
% G.link(result.plot_pvcurve());    % markers on the PV curves follow the diagram
% G.set_time(result.r_noseStep);    % both at the nose
% result.plot_generator(Quantity="Qmargin");
% lin.plot_eigenvalue_path();       % eigenvalues over the two steps
% result.export("cpf.csv");
% ```
%
% See also SolverCPF, ResultBase

    properties (SetAccess=private) % Result
        sv_bus (:,1) string = strings(0,1)  % Bus tags, in the order of the rows of cm_Vbus.
        rv_lambda double = zeros(1,0)       % Load parameter lambda at each point of the path (the first point is the equilibrium).
        cm_Vbus double = zeros(0,0)         % [pu] Bus voltage phasors at each point of the path, one row per bus.
        r_lambdaMax (1,1) double = NaN      % Largest lambda on the path (the nose of the PV curve: maximum loading).
        r_noseStep (1,1) double = NaN       % Index of the nose point in rv_lambda and the columns of cm_Vbus.
        rm_x double = zeros(0,0)            % Full variable vector at each point of the path, lambda in the last row (see the class help).
        rm_xPredicted double = zeros(0,0)   % Predicted points of the predictor-corrector method, in the layout of rm_x (first column NaN).
        tab_switch table = table()          % PV buses switched to PQ by Limits "Q", one row per switch: lambda, Step, Bus, Limit, Bound (see the class help).
        tab_stop table = table()            % Limit of Limits "V" or "S" that ended the path (0 or 1 row): lambda, Step, Class, Object, Limit, Bound (see the class help).
        tab_variable table = table()        % Variable map at the calculation (rows x, Vre, Vim, u, uc of net.get_variable_map()): its rows are the columns of rm_variable. <@Type> table ((n_x + n_v + n_u + n_uc) x 8)
        rm_variable double = zeros(0,0)     % Operating point of each step: row k at step k (index in rv_lambda), column m the variable tab_variable(m,:). <@Type> double (n_step x (n_x + n_v + n_u + n_uc))
        cm_Icomponent double = zeros(0,0)   % [pu] Current each component injects into its bus at each step: one row per component (network order: sv_bus, then a_Component), one column per step. <@Type> complex double (n_component x n_step)
        sct_network struct = struct()       % Snapshot of the network at the calculation: struct(net, false).
        rv_sigmaMin double = zeros(1,0)     % Smallest singular value of the power flow Jacobian (unknowns, without lambda) at each step: voltage stability index, 0 at the nose.
        tab_weakbus table = table()         % Weak buses at the nose, one row per bus sorted by Participation (descending): Bus, Participation (largest 1), dVdLambda [pu] (see the class help).
        r_marginP (1,1) double = NaN        % [pu] Loading margin: r_lambdaMax times the initial active power of every component scaled by (1 + lambda); with UseInternalState that power is minus the network losses, so it is usually negative (see the class help).
    end

    properties (Dependent) % Result
        tab_nose                            % Bus voltages at the nose point, one row per bus: V [pu], Varg [rad], Vphasor [pu]. <@Type> table (n_bus x 3)
        tab_path                            % The path, one row per point: lambda, then V_<bus> [pu] and Varg_<bus> [rad] of each bus. <@Type> table (n_step x (1 + 2 n_bus))
    end

    methods
        function obj = ResultCPF(net, solver, options, flag, output, elapsed, sv_bus, rv_lambda, cm_Vbus, rm_x, rm_xPredicted, tab_switch, tab_stop, sct_point)
        % Create a continuation power flow result.
        %
        % Stores the computed values of a continuation power flow.
            arguments (Input)
                net                  = []            % Analysed network; see ResultBase.
                solver               = "SolverCPF"   % Solver object or its class name; see ResultBase.
                options       struct = struct()      % Effective settings; see ResultBase.
                flag                 = false         % Success or convergence flag; see ResultBase.
                output        struct = struct()      % Solver details; see ResultBase.
                elapsed              = NaN           % [s] Elapsed time or tic value; see ResultBase.
                sv_bus        string = strings(0,1)  % Bus tags (rows of cm_Vbus).
                rv_lambda     double = zeros(1,0)    % lambda along the path.
                cm_Vbus       double = zeros(0,0)    % [pu] Bus voltages along the path.
                rm_x          double = zeros(0,0)    % Full variable vector along the path.
                rm_xPredicted double = zeros(0,0)    % Predicted points.
                tab_switch    table  = table()       % Switches to PQ (see tab_switch).
                tab_stop      table  = table()       % Limit that ended the path (see tab_stop).
                sct_point     struct = struct()      % Operating points and stability information: fields tab_variable, rm_variable, cm_Icomponent, sct_network, rv_sigmaMin, tab_weakbus, r_marginP (missing ones keep their defaults).
            end
            arguments (Output)
                obj  % The result object.
            end
            obj@ResultBase(net, solver, options, flag, output, elapsed);
            obj.sv_bus        = sv_bus(:);
            obj.rv_lambda     = reshape(rv_lambda, 1, []);
            obj.cm_Vbus       = cm_Vbus;
            obj.rm_x          = rm_x;
            obj.rm_xPredicted = rm_xPredicted;
            obj.tab_switch    = tab_switch;
            obj.tab_stop      = tab_stop;
            for s_name = ["tab_variable","rm_variable","cm_Icomponent","sct_network","rv_sigmaMin","tab_weakbus","r_marginP"]
                if isfield(sct_point, s_name)
                    obj.(s_name) = sct_point.(s_name);
                end
            end
            if ~isempty(obj.rv_lambda)
                [obj.r_lambdaMax, obj.r_noseStep] = max(obj.rv_lambda);
            end
        end

        function tab = get.tab_nose(obj)
            if isnan(obj.r_noseStep)
                cv_V = complex(zeros(numel(obj.sv_bus),1));
            else
                cv_V = obj.cm_Vbus(:, obj.r_noseStep);
            end
            tab = table(abs(cv_V), angle(cv_V), cv_V, ...
                        'VariableNames', ["V","Varg","Vphasor"], 'RowNames', cellstr(obj.sv_bus));
        end

        function tab = get.tab_path(obj)
            rm_V = [abs(obj.cm_Vbus); angle(obj.cm_Vbus)].';
            sr_name = ["V_" + obj.sv_bus; "Varg_" + obj.sv_bus].';
            tab = [table(obj.rv_lambda(:), 'VariableNames', "lambda"), ...
                   array2table(rm_V, 'VariableNames', sr_name)];
        end

        rv = get_point(obj, Step, tab_map)
        G = plot_pvcurve(obj, opt)
        G = plot_diagram(obj, opt)
        G = plot_spring_model(obj, opt)
        G = plot_stability_index(obj, opt)
        G = plot_generator(obj, opt)
        G = plot_branch(obj, opt)
        s_file = export(obj, filename)
    end
end
