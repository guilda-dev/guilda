function [rm_pf, flag, output] = initialize(obj, varargin)
% Bring every layer of the network up to date: the power flow, the equilibria and the function handles.
%
% Only initialize brings the layers up to date (LayerPackage `sct_stale`); the analyses
% that need the equilibrium (simulate, get_sys, the continuation power flow)
% only check them. It is one of the few analysis methods that change the model. Steps:
%
% 1. The operating point is solved when Method is given ("powerflow", "OPF" or
%    "FixedInput"; always
%    solved then) or when the power flow of the network is stale (net.sct_stale.powerflow:
%    edits of baseMVA, the topology, bus and branch parameters, the slack bus or the
%    powerflow parameters of the components; also before the first initialize). It is
%    written with Bus.set_equilibrium, which sets the equilibria of the components and
%    their local controllers.
% 2. Every bus initializes its components: stale handles are rebuilt, and an equilibrium
%    that is still stale (an edit of dynamics or of the local controllers) is recomputed
%    from the held V and I. Then each global controller rebuilds its stale handles and
%    computes its equilibrium.
%
% Each layer decides from its own stale tags, so a dynamics-only edit does not solve the
% power flow again, and a Hz edit (net.sct_stale.odefcn) only rebuilds the handles. With
% nothing stale, initialize changes nothing but the equilibria of the global controllers,
% which are always recomputed. The stale tags of the network are cleared at the end.
%
% Inputs edited with Component.set_input (net.sct_stale.input) are kept only by
% Method="FixedInput". Without Method, or with Method="equilibrium", initialize stops with
% GUILDA:PowerNetwork:InputEdited; Method="powerflow" or "OPF" replaces them with the
% values of the solution (INFO GUILDA:PowerNetwork:InputOverwritten).
%
% The first output is the operating point that was set, for every Method: an n-by-4 complex
% double with one row per bus (net.a_Bus order) and the columns V, I (complex phasors of
% the voltage and the current injection), P, Q (real injections into the network) [pu]
% (for "OPF", those of the AC OPF solution). It is the array initialize writes with
% Bus.set_equilibrium, so it costs nothing extra. Without a solve it is the held
% equilibrium. For a result object, call net.calculate_powerflow or
% net.calculate_optimal_powerflow.
%
% Name-Value options:
%
% - `Method` — How the operating point is obtained when it is solved. Default:
%   "powerflow".
%   - "powerflow": net.calculate_powerflow (settings of GUILDA.setting).
%   - "OPF": net.calculate_optimal_powerflow with Method="AC OPF" (OptimalPowerFlow section of GUILDA.setting;
%     the AC formulation gives a complete AC operating point).
%   - "FixedInput": the equilibrium with the inputs of the components held
%     (rv_Uequilibrium, edited with Component.set_input): the states, the bus voltages,
%     the currents and the Pmech of the first generator of the slack bus are solved
%     (the slack bus angle is 0; its V and Varg settings and the powerflow settings of the
%     components are not used). The controllers are not in the equations: they take
%     their equilibria afterwards. Always solved. Options: Solver ("newton" (default),
%     "levenberg-marquardt", "fsolve"), Tolerance and MaxIteration (default: the
%     PowerFlowCalculation section of GUILDA.setting), Verbose and WarmStart (true: from
%     the held equilibrium; false, or a component without one: from a power flow that is
%     not written). Every component must hold its inputs
%     (GUILDA:PowerNetwork:InitializeInputNotSet), the slack bus needs a generator, and a
%     network split into islands stops.
%   - "equilibrium": never solved; the equilibria the components already hold (from an
%     earlier initialize) are kept, and buses without components get the voltage of
%     Y*V = I. A stale power flow stops with an error: use net.initialize().
% - `WarmStart` — true starts the power flow or the "AC OPF" from the last solution of the
%   network (kept by net.solver_PF or net.solver_OPF); false from the flat start. Default:
%   the WarmStart of the PowerFlowCalculation or OptimalPowerFlow section of GUILDA.setting.
%   Passed to calculate_powerflow or calculate_optimal_powerflow like the other options.
% - Other options go unchanged to calculate_powerflow ("powerflow") or
%   calculate_optimal_powerflow ("OPF") and are validated there (an unknown name stops with the
%   error of that analysis); "equilibrium" takes no other option. Format is not an option
%   of initialize (GUILDA:PowerNetwork:InitializeFormat, with every Method). `Solver`
%   chooses the algorithm of that analysis, e.g. Solver="levenberg-marquardt" for the
%   power flow (default: the Solver of the PowerFlowCalculation section of GUILDA.setting)
%   or Solver="fmincon" for the OPF.
%
% When the analysis does not succeed (no convergence, an infeasible OPF, or stored
% equilibria that do not satisfy the network equations), initialize stops with an error
% naming the remedy, and the network keeps its previous equilibrium and stale state (a
% slack bus set by calculate_powerflow is released again). When a later step fails, or
% the point does not satisfy Y*V = I, the power flow is left stale, and analyses stop
% (e.g. GUILDA:PowerNetwork:SimulateStale) until initialize succeeds.
%
% A network split into islands is a valid equilibrium when the power of each island
% balances, so a successful initialize only warns (GUILDA:PowerNetwork:NetworkIsland). A
% failed power flow or OPF on such a network names the islands in its error.
%
% The models are evaluated at the point that was set, with every Method. A state or input of the wrong size, a model function that returns the wrong size
% and a model function that stops are errors naming the model, and the power flow is left
% stale. A
% residual of a component, local controller or global controller of 1e-6 or more only
% warns (GUILDA:PowerNetwork:EquilibriumResidual), because such a model can still be run:
% its states then move without a disturbance.
%
% <@Examples>
% ```matlab
% net = network.IEEE9bus();
% net.initialize();                                % power flow
% net.a_Bus{1}.a_Component{1}.tab_parameter.dynamics.D = 0.1;
% net.initialize();                                % only the edited generator
% net.initialize(Method="equilibrium");            % never solves the power flow
% pf  = net.initialize(Method="powerflow");          % n-by-4 V, I, P, Q of the point
% V   = pf(:,1);                                   % complex bus voltages
% pf  = net.initialize(Method="OPF", Solver="fmincon");   % V, I, P, Q of the AC OPF point
% res = net.calculate_powerflow();                 % ResultPF of the held network data
% ```
%
% See also PowerNetwork.calculate_powerflow, PowerNetwork.calculate_optimal_powerflow, PowerNetwork.simulate
%
% <@Group> Initialize
    arguments (Input)
        obj
    end
    arguments (Input, Repeating)
        varargin   % Name-Value options.
    end
    arguments (Output)
        rm_pf    % [pu] Operating point: n-by-4 complex double, one row per bus (net.a_Bus order); columns V, I (complex phasors), P, Q (real injections into the network).
        flag     % Success flag of the analysis (positive; a failure stops with an error).
        output   % Details of the analysis; output.message describes the outcome.
    end

    %% 1. Method and the options passed on to the analysis
    if mod(numel(varargin), 2) ~= 0
        error(msg("GUILDA:PowerNetwork:InitializePairs"))
    end
    sr_method = ["powerflow","OPF","FixedInput","equilibrium"];
    s_method  = "powerflow";
    l_given   = false;
    lv_method = false(size(varargin));
    for k = 1:2:numel(varargin)
        x = varargin{k};
        l_name = (ischar(x) && isrow(x)) || (isstring(x) && isscalar(x));
        if l_name && strcmpi(x, "Format")
            error(msg("GUILDA:PowerNetwork:InitializeFormat"))
        end
        if l_name && strcmpi(x, "Method")
            v = varargin{k+1};
            if ~((ischar(v) && isrow(v)) || (isstring(v) && isscalar(v))) || ~any(strcmpi(v, sr_method))
                error(msg("GUILDA:PowerNetwork:InitializeMethod", char(join('"' + sr_method + '"', ", "))))
            end
            s_method = sr_method(strcmpi(v, sr_method));
            l_given  = true;
            lv_method(k:k+1) = true;
        end
    end
    c_nv = varargin(~lv_method);

    tol    = 1e-6;   % [pu] largest max|Y*V - I| of an equilibrium, and largest model residual that does not warn
    f_list = @(sv) join([sv(1:min(end,3)); repmat("...", numel(sv) > 3, 1)], "; ");   % the first messages as one text
    sv_input = unique(obj.sct_stale.input, "stable");     % inputs edited with set_input
    if ~isempty(sv_input) && (~l_given || s_method == "equilibrium")
        error(msg("GUILDA:PowerNetwork:InputEdited", char(f_list(sv_input))))
    end
    l_solve = s_method ~= "equilibrium" && (l_given || ~isempty(obj.sct_stale.powerflow));

    %% 2. Operating point: solved, or built from the held equilibria
    n_Bus = numel(obj.a_Bus);
    c_PQ  = cell(n_Bus,1);   % [P Q] of the components of each bus when the analysis fixes them
    if l_solve
        l_slack = any(tools.vcellfun(@(b) b.l_isSlack, obj.a_Bus));
        try
            switch s_method
                case "powerflow"
                    [rm_pf, flag, output] = obj.calculate_powerflow(c_nv{:}, Format="powerflow(mat)");
                    if ~(flag > 0)
                        stop_analysis(obj, output.message, "GUILDA:PowerNetwork:InitializePowerflowFailed", "GUILDA:PowerNetwork:InitializePowerflowIsland")
                    end
                case "OPF"
                    [res, flag, output] = obj.calculate_optimal_powerflow(c_nv{:}, "Method", "AC OPF");
                    if ~res.l_success
                        stop_analysis(obj, output.message, "GUILDA:PowerNetwork:InitializeOPFFailed", "GUILDA:PowerNetwork:InitializeOPFIsland")
                    end
                case "FixedInput"
                    if ~l_slack   % selected as by calculate_powerflow
                        if n_Bus == 0
                            error(msg("GUILDA:PowerNetwork:NoBus", string(obj)))
                        end
                        i_bus = tools.slack_bus_index(obj);
                        if isempty(i_bus)
                            error(msg("GUILDA:PowerNetwork:NoSlackCandidate", string(obj)))
                        end
                        show_msg("info", "GUILDA:PowerNetwork:SlackSelected", string(obj.a_Bus{i_bus}))
                        obj.a_Bus{i_bus}.l_isSlack = true;
                    end
                    [n_island, s_island] = network_islands(obj);
                    if n_island > 1
                        error(msg("GUILDA:PowerNetwork:InitializeFixedInputIsland", string(obj), char(string(n_island)), char(s_island)))
                    end
                    [rm_pf, flag, output, sct_point] = solve_fixed_input(obj, c_nv);
                    if flag ~= 1
                        error(msg("GUILDA:PowerNetwork:InitializeFixedInputFailed", char(string(output.message))))
                    end
            end
        catch ME
            if ~l_slack   % release the slack bus selected for this solve
                for i_bus = 1:n_Bus
                    obj.a_Bus{i_bus}.l_isSlack = false;
                end
            end
            % building the OPF problem of a split network can stop with an internal error (it has an
            % identifier; GUILDA errors and the option errors of the arguments block are passed on)
            if s_method == "OPF" && ~isempty(ME.identifier) && network_islands(obj) > 1 ...
                    && ~startsWith(ME.identifier, ["GUILDA:","MATLAB:TooManyInputs","MATLAB:validators:","MATLAB:validation:"])
                stop_analysis(obj, ME.message, "GUILDA:PowerNetwork:InitializeOPFFailed", "GUILDA:PowerNetwork:InitializeOPFIsland")
            end
            rethrow(ME)
        end
        if s_method == "OPF"   % bus V, I, P, Q of the AC OPF solution, and the power of each component
            cv_S  = res.tab_bus.Vphasor .* conj(res.tab_bus.Iphasor);
            rm_pf = [res.tab_bus.Vphasor, res.tab_bus.Iphasor, real(cv_S), imag(cv_S)];
            for i_bus = 1:n_Bus
                a_Comp = obj.a_Bus{i_bus}.a_Component;
                if ~isempty(a_Comp)
                    c_PQ{i_bus} = real(res.tab_cub{string(a_Comp),["P","Q"]});
                end
            end
        end
    elseif s_method == "equilibrium"
        if ~isempty(c_nv)
            error(msg("GUILDA:PowerNetwork:InitializeEquilibriumOption", char(string(c_nv{1}))))
        end
        if ~isempty(obj.sct_stale.powerflow)
            error(msg("GUILDA:PowerNetwork:InitializeEquilibriumEdited", char(f_list(unique(obj.sct_stale.powerflow, "stable")))))
        end
    end
    if ~l_solve && (nargout > 0 || s_method == "equilibrium")
        [rm_pf, flag, output] = calculate_from_equilibrium(obj, tol);   % also checks Y*V = I
    end

    try
        %% 3. Write the point to the buses (they set the equilibria of their components and local controllers)
        if s_method == "FixedInput"   % states, inputs and powers as solved (get_equilibrium is not called)
            for i_bus = 1:n_Bus
                iv_k = find(sct_point.iv_bus == i_bus);
                c_V  = sct_point.cv_V(i_bus);
                cv_I = sct_point.cv_I(iv_k);
                cv_S = c_V .* conj(cv_I);
                rm_PQ = [real(cv_S), imag(cv_S)];
                c_XU  = [sct_point.c_X(iv_k), sct_point.c_U(iv_k)];
                if isempty(iv_k)
                    rm_PQ = [];
                    c_XU  = {};
                end
                obj.a_Bus{i_bus}.set_equilibrium(c_V, sum(cv_I), real(sum(cv_S)), imag(sum(cv_S)), "rm_PQ", rm_PQ, "c_XU", c_XU)
            end
        elseif l_solve   % c_PQ{i} = [] lets the bus distribute its power
            for i_bus = 1:n_Bus
                obj.a_Bus{i_bus}.set_equilibrium(rm_pf(i_bus,1), rm_pf(i_bus,2), real(rm_pf(i_bus,3)), real(rm_pf(i_bus,4)), "rm_PQ", c_PQ{i_bus})
            end
        end

        %% 4. Initialize the layers
        for i_bus = 1:n_Bus
            obj.a_Bus{i_bus}.initialize();
        end
        for i_br = 1:numel(obj.a_Branch)
            obj.a_Branch{i_br}.initialize();
        end
        for i_gc = 1:numel(obj.a_GlobalController)
            obj.a_GlobalController{i_gc}.initialize(true);   % may read the units just set
        end

        %% 5. Check the point: Kirchhoff's current law (only a solve writes V and I) and the models
        if l_solve
            sv_Bus  = string(obj.a_Bus);
            tab_Y   = obj.get_admittance_matrix;
            r_resid = max(abs(tab_Y{sv_Bus,sv_Bus}*obj.cv_Vequilibrium - obj.cv_Iequilibrium), [], "includenan");
            if ~(r_resid < tol)
                error(msg("GUILDA:PowerNetwork:InitializeNotEquilibrium", char(s_method), char(string(r_resid))))
            end
        end
        s_residual = model_residuals(obj, tol);   % sizes and failing model functions stop here
    catch ME
        % a partly written point is never used: the next initialize solves it again
        obj.sct_stale.powerflow(end+1,1) = obj.s_tag + ": the last initialize stopped before it finished";
        rethrow(ME)
    end

    %% 6. Up to date
    obj.sct_stale.powerflow = strings(0,1);
    obj.sct_stale.odefcn    = strings(0,1);
    obj.sct_stale.input     = strings(0,1);

    %% 7. Info and warnings
    if ~isempty(sv_input) && s_method ~= "FixedInput"
        show_msg("info", "GUILDA:PowerNetwork:InputOverwritten", char(s_method), char(f_list(sv_input)))
    end
    if s_residual ~= ""
        show_msg("warning", "GUILDA:PowerNetwork:EquilibriumResidual", char(string(tol)), char(s_residual))
    end
    [n_island, s_island] = network_islands(obj);
    if n_island > 1
        show_msg("warning", "GUILDA:PowerNetwork:NetworkIsland", string(obj), char(string(n_island)), char(s_island))
    end
end


function stop_analysis(obj, s_reason, s_idFailed, s_idIsland)
% Error of a failed power flow or OPF; on a split network it names the islands instead of the solver settings
    [n_island, s_island] = network_islands(obj);
    s_reason = char(string(s_reason));
    if n_island > 1
        error(msg(s_idIsland, s_reason, string(obj), char(string(n_island)), char(s_island)))
    end
    error(msg(s_idFailed, s_reason))
end


function [n_island, s_island] = network_islands(obj)
% Number of the parts of the network that branches connect, and their bus tags as text
    n_show  = 10;   % islands, and buses per island, that the text lists
    sv_Bus  = string(obj.a_Bus);
    sv_Bus  = sv_Bus(:);
    n_Br    = numel(obj.a_Branch);
    im_edge = zeros(n_Br,2);
    for i_br = 1:n_Br
        [~, im_edge(i_br,:)] = ismember(string(obj.a_Branch{i_br}.a_Bus), sv_Bus);
    end
    rv_bin   = conncomp(graph(im_edge(:,1), im_edge(:,2), [], numel(sv_Bus)));
    n_island = max([0, rv_bin]);

    sv = strings(1, min(n_island, n_show));
    for i_island = 1:numel(sv)
        sv_bus = sv_Bus(rv_bin == i_island);
        if numel(sv_bus) > n_show
            sv_bus = [sv_bus(1:n_show); "... (" + numel(sv_bus) + " buses)"];
        end
        sv(i_island) = "[" + join(sv_bus, ", ") + "]";
    end
    s_island = join(sv, ", ");
    if n_island > n_show
        s_island = s_island + ", ...";
    end
end


function [rm_pf, flag, output] = calculate_from_equilibrium(obj, tol)
% The bus point from the equilibria the components hold: V of the bus, the sum of their I.
% Buses without components inject no current; their voltage is solved from Y*V = I.
    sv_Bus  = string(obj.a_Bus);
    n_Bus   = numel(sv_Bus);
    tab_Y   = obj.get_admittance_matrix;
    cm_Y    = tab_Y{sv_Bus,sv_Bus};

    cv_Vbus  = nan(n_Bus,1);
    cv_Ibus  = zeros(n_Bus,1);
    lv_known = false(n_Bus,1);
    for i_bus = 1:n_Bus
        a_Comp = obj.a_Bus{i_bus}.a_Component;
        for i_comp = 1:numel(a_Comp)
            comp = a_Comp{i_comp};
            if isempty(comp.c_Vequilibrium) || isempty(comp.c_Iequilibrium)
                error(msg("GUILDA:PowerNetwork:InitializeNoEquilibrium", char(string(comp))))
            end
            cv_Vbus(i_bus)  = comp.c_Vequilibrium;
            cv_Ibus(i_bus)  = cv_Ibus(i_bus) + comp.c_Iequilibrium;
            lv_known(i_bus) = true;
        end
    end
    if any(~lv_known)
        cv_Vbus(~lv_known) = - cm_Y(~lv_known,~lv_known) \ (cm_Y(~lv_known,lv_known)*cv_Vbus(lv_known));
    end

    r_resid = max(abs(cm_Y*cv_Vbus - cv_Ibus));
    if r_resid >= tol
        error(msg("GUILDA:PowerNetwork:InitializeEquilibriumFailed", char(string(r_resid))))
    end
    flag   = 1;
    output = struct("residual", r_resid, ...
                    "message", "The equilibria of the components satisfy the network equations.");
    cv_S  = cv_Vbus .* conj(cv_Ibus);
    rm_pf = [cv_Vbus, cv_Ibus, real(cv_S), imag(cv_S)];
end


function s_list = model_residuals(obj, tol)
% The models whose residual at the point is tol or more, as text ("" for none). The residual
% is max|dx|, |I - Iequilibrium| and the largest difference between an input and what drives
% it in a simulation.
    n_show = 10;   % models that the text lists
    c_row = cell(0,1);
    for i_bus = 1:numel(obj.a_Bus)
        a_Comp = obj.a_Bus{i_bus}.a_Component;
        for i_comp = 1:numel(a_Comp)
            c_row = [c_row; component_residuals(a_Comp{i_comp})]; %#ok<AGROW>
        end
    end
    for i_gc = 1:numel(obj.a_GlobalController)
        c_row = [c_row; global_controller_residual(obj.a_GlobalController{i_gc})]; %#ok<AGROW>
    end
    sv_tag   = strings(numel(c_row),1);
    rm_resid = zeros(numel(c_row),3);
    for k = 1:numel(c_row)
        sv_tag(k)     = c_row{k}{1};
        rm_resid(k,:) = c_row{k}{2};
    end

    lv_large = ~(max(rm_resid, [], 2, "includenan") < tol);
    s_list   = "";
    if any(lv_large)
        rm_large = rm_resid(lv_large,:);
        sv_line  = compose("'%s': |dx| = %.3g, |I - Iequilibrium| = %.3g, |u - source| = %.3g", ...
                           sv_tag(lv_large), rm_large(:,1), rm_large(:,2), rm_large(:,3));
        if numel(sv_line) > n_show
            sv_line = [sv_line(1:n_show); "... (" + numel(sv_line) + " models)"];
        end
        s_list = join(sv_line, newline);
    end
end


function c_row = component_residuals(comp)
% Rows of the component and of its local controllers (depth first)
    check_point_size(comp, numel(comp.sv_u));
    x = comp.rv_Xequilibrium;
    u = comp.rv_Uequilibrium;
    V = [real(comp.c_Vequilibrium); imag(comp.c_Vequilibrium)];

    dx  = model_value(comp, "fcn_dx", numel(comp.sv_x), @() comp.f_dx(0, x, V, u));
    c_I = model_value(comp, "fcn_I", 1, @() comp.f_I(0, x, V, u));

    c_row = cell(0,1);
    rv_source = u;
    if ~isempty(comp.a_LocalController)
        y = model_value(comp, "fcn_Y", numel(comp.sv_y), @() comp.f_Y(0, x, V));
        [rv_source, c_row] = nested_outputs(comp, rv_source, x, y, V);
    end
    c_row = [residual_row(comp, dx, abs(c_I - comp.c_Iequilibrium), u - rv_source); c_row];
end


function [rv_source, c_row] = nested_outputs(parent, rv_source, x_obs, y_obs, V)
% Replaces the inputs of parent driven by its local controllers with their outputs (the
% "local" connections of net.get_variable_map), and adds the rows of those controllers
    c_row = cell(0,1);
    for k = 1:numel(parent.a_LocalController)
        con = parent.a_LocalController{k};
        [y_con, c_con] = controller_residuals(con, x_obs, y_obs, V);
        c_row = [c_row; c_con]; %#ok<AGROW>
        [lv_u, iv_y] = ismember(reshape(string(parent.sv_u),[],1), reshape(string(con.sv_y),[],1));
        rv_source(lv_u) = y_con(iv_y(lv_u));
    end
end


function [y, c_row] = controller_residuals(con, x_obs, y_obs, V)
% Rows of the local controller and of its nested controllers, and its outputs
    check_point_size(con, numel(con.sv_u));
    x = con.rv_Xequilibrium;
    u = con.rv_Uequilibrium;

    dx = model_value(con, "fcn_dx", numel(con.sv_x), @() con.f_dx(0, x, V, u));
    y  = model_value(con, "fcn_y", numel(con.sv_y), @() con.f_Y(0, x, V, u));

    rv_source = u;
    lv_Y = con.iv_obsY > 0;
    lv_X = con.iv_obsX > 0;
    rv_source(lv_Y) = y_obs(con.iv_obsY(lv_Y));
    rv_source(lv_X) = x_obs(con.iv_obsX(lv_X));
    [rv_source, c_row] = nested_outputs(con, rv_source, x_obs, y_obs, V);
    c_row = [residual_row(con, dx, 0, u - rv_source); c_row];
end


function c_row = global_controller_residual(gc)
% Row of the global controller at the equilibrium. Its inputs are the outputs (or states)
% of its controlled units and its port the voltages of all buses, as in a simulation; its
% outputs add to inputs whose equilibrium is set, so an output other than zero moves them.
    check_point_size(gc, numel(gc.controlledUnits)*numel(gc.sv_u));   % sv_u is read on each unit
    x = gc.rv_Xequilibrium;
    a_unit = gc.controlledUnits;
    n_u = numel(gc.sv_u);
    u = zeros(numel(a_unit)*n_u, 1);
    for k = 1:numel(a_unit)
        unit = a_unit{k};
        iv_k = (k-1)*n_u + (1:n_u)';
        lv_Y = gc.iv_obsY(iv_k) > 0;
        lv_X = gc.iv_obsX(iv_k) > 0;
        if any(lv_Y)
            y_unit = model_value(unit, "fcn_Y", numel(unit.sv_y), @() unit.f_Y(0, unit.rv_Xequilibrium, ...
                                 [real(unit.c_Vequilibrium); imag(unit.c_Vequilibrium)]));
            u(iv_k(lv_Y)) = y_unit(gc.iv_obsY(iv_k(lv_Y)));
        end
        u(iv_k(lv_X)) = unit.rv_Xequilibrium(gc.iv_obsX(iv_k(lv_X)));
    end
    V = tools.vcellfun(@(b) [real(b.c_Vequilibrium); imag(b.c_Vequilibrium)], gc.a_PowerNetwork.a_Bus);

    dx = model_value(gc, "fcn_dx", numel(gc.sv_x), @() gc.f_dx(0, x, V, u));
    c_row = residual_row(gc, dx, 0, gc.f_Y(0, x, V, u));
end


function c_row = residual_row(model, dx, r_I, du)
% Row of a model: its tag and max|dx|, |I - Iequilibrium|, max|du| (0 for no elements, NaN when one is NaN)
    c_row = {{string(model.s_tag), [max([abs(dx(:)); 0], [], "includenan"), r_I, max([abs(du(:)); 0], [], "includenan")]}};
end


function check_point_size(model, n_uExpected)
% A state or input of the wrong size fails later in simulate with a generic size error
    n_x = numel(model.rv_Xequilibrium);
    n_u = numel(model.rv_Uequilibrium);
    if n_x ~= numel(model.sv_x) || n_u ~= n_uExpected
        error(msg("GUILDA:PowerNetwork:InitializeEquilibriumSize", char(string(model.s_tag)), ...
                  char(string(n_x)), char(string(numel(model.sv_x))), char(string(n_u)), char(string(n_uExpected))))
    end
end


function val = model_value(model, s_fcn, n, f)
% Value of a model function at the point, which must have n elements
    s_tag = char(string(model.s_tag));
    try
        val = f();
    catch ME
        error(msg("GUILDA:PowerNetwork:InitializeModelFailed", s_tag, char(s_fcn), ME.message))
    end
    if numel(val) ~= n
        error(msg("GUILDA:PowerNetwork:InitializeModelSize", s_tag, char(s_fcn), ...
                  char(join(string(size(val)), "x")), char(string(n))))
    end
    val = reshape(full(val), [], 1);
end
