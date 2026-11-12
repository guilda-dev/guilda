function [result, flag, output] = initialize(obj, varargin)
% Bring every layer of the network up to date: the power flow, the equilibria and the function handles.
%
% Only initialize brings the layers up to date (LayerPackage `sct_stale`); the analyses
% that need the equilibrium (simulate, linearize, get_sys, the continuation power flow)
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
% Name-Value options:
%
% - `Method` — How the operating point is obtained when it is solved. Default:
%   "powerflow".
%   - "powerflow": net.calculate_powerflow (settings of GUILDA.setting).
%   - "OPF": net.optimize_powerflow with Method="AC OPF" (OptimalPowerFlow section of GUILDA.setting and conditions of net.solver_OPF;
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
% - `Format` — Form of the first output, with the values of calculate_powerflow. Default:
%   "powerflow(mat)" (calculate_powerflow: "GUILDAorigin").
%   - "powerflow(mat)": n-by-4 complex double; columns V, I (complex phasors), P, Q
%     (real injections into the network) [pu]; rows in net.a_Bus order. It is the array
%     initialize writes with Bus.set_equilibrium, so it costs nothing extra.
%   - "V": complex bus voltages of the operating point [pu], a column in net.a_Bus order.
%   - "powerflow(tab)": the same as a table with the variables V, I, P, Q; row names =
%     bus tags.
%   - "GUILDAorigin": the result object: ResultPF for "powerflow" ("FixedInput":
%     s_solver = "FixedInput"; without a solve: the held equilibrium, s_solver =
%     "equilibrium"), ResultOPF for "OPF".
%   The other values give the bus V, I, P, Q of the operating point for every Method
%   (for "OPF", those of the AC OPF solution). Internally, initialize requests the
%   "powerflow(mat)" array from calculate_powerflow; a table is built only for
%   "powerflow(tab)" and a ResultPF only for "GUILDAorigin".
% - `WarmStart` — true starts the power flow or the "AC OPF" from the last solution of the
%   network (kept by net.solver_PF or net.solver_OPF); false from the flat start. Default:
%   the WarmStart of the PowerFlowCalculation or OptimalPowerFlow section of GUILDA.setting.
%   Passed to calculate_powerflow or optimize_powerflow like the other options.
% - Other options go unchanged to calculate_powerflow ("powerflow") or
%   optimize_powerflow ("OPF") and are validated there (an unknown name stops with the
%   error of that analysis); "equilibrium" takes no other option. `Solver`
%   chooses the algorithm of that analysis, e.g. Solver="levenberg-marquardt" for the
%   power flow (default: the Solver of the PowerFlowCalculation section of GUILDA.setting)
%   or Solver="fmincon" for the OPF.
%
% When the analysis does not succeed (no convergence, an infeasible OPF, or stored
% equilibria that do not satisfy the network equations), initialize stops with an error
% naming the remedy, and the network keeps its previous equilibrium and stale state (a
% slack bus set by calculate_powerflow is released again). When a later step fails, or
% the point does not satisfy Y*V = I, the power flow is left stale, and analyses stop
% (e.g. GUILDA:SolverODE:Stale) until initialize succeeds.
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
% V   = net.initialize(Method="powerflow", Format="V");      % complex bus voltages
% tab = net.initialize(Method="powerflow", Format="powerflow(tab)");   % V, I, P, Q
% res = net.initialize(Method="OPF", Solver="fmincon", Format="GUILDAorigin");
% res.r_cost                                       % cost of the OPF operating point
% ```
%
% See also PowerNetwork.calculate_powerflow, PowerNetwork.optimize_powerflow, PowerNetwork.simulate
%
% <@Group> Initialize
    arguments (Input)
        obj
    end
    arguments (Input, Repeating)
        varargin   % Name-Value options.
    end
    arguments (Output)
        result   % Operating point in the form of Format: the n-by-4 array of V, I, P, Q (default), bus voltages, a table of V, I, P, Q, or the result object (ResultPF, or ResultOPF for "OPF").
        flag     % Success flag of the analysis (positive; a failure stops with an error).
        output   % Details of the analysis; output.message describes the outcome.
    end

    varargin = v3_initialize_args(varargin);                  % COMPAT(v3)
    [s_format, varargin] = take_format(varargin);
    [s_method, c_nv, l_given] = take_method(varargin);
    sv_input = unique(obj.sct_stale.input, "stable");     % inputs edited with set_input
    if ~isempty(sv_input) && (~l_given || s_method == "equilibrium")
        error(msg("GUILDA:PowerNetwork:InputEdited", char(stale_list(sv_input))))
    end

    l_solve = s_method ~= "equilibrium" && (l_given || ~isempty(obj.sct_stale.powerflow));
    switch s_method
        case "powerflow"
            if l_solve
                [result, flag, output, rm_pf] = solve_powerflow(obj, c_nv, s_format);
            end
        case "OPF"
            if l_solve
                [result, flag, output] = solve_opf(obj, c_nv);
                [rm_pf, c_PQ] = opf_point(obj, result);
                if s_format ~= "GUILDAorigin"
                    result = format_powerflow(s_format, string(obj.a_Bus), rm_pf, @() []);
                end
            end
        case "FixedInput"
            [result, flag, output, sct_point] = solve_fixed(obj, c_nv, s_format);
        case "equilibrium"
            if ~isempty(c_nv)
                error(msg("GUILDA:PowerNetwork:InitializeEquilibriumOption", char(string(c_nv{1}))))
            end
            if ~isempty(obj.sct_stale.powerflow)
                sv = unique(obj.sct_stale.powerflow, "stable");
                s_list = join(sv(1:min(end,3)), "; ");
                if numel(sv) > 3
                    s_list = s_list + "; ...";
                end
                error(msg("GUILDA:PowerNetwork:InitializeEquilibriumEdited", char(s_list)))
            end
    end
    if ~l_solve && (nargout > 0 || s_method == "equilibrium")
        [result, flag, output] = calculate_from_equilibrium(obj, s_format);   % also checks Y*V = I
    end
    try
        if s_method == "FixedInput"
            write_fixed_input(obj, sct_point);
        elseif s_method == "OPF" && l_solve
            write_powerflow(obj, rm_pf, c_PQ);
        elseif l_solve
            write_powerflow(obj, rm_pf, cell(numel(obj.a_Bus),1));
        end
        for i_bus = 1:numel(obj.a_Bus)
            obj.a_Bus{i_bus}.initialize();
        end
        for i_br = 1:numel(obj.a_Branch)
            obj.a_Branch{i_br}.initialize();
        end
        for i_gc = 1:numel(obj.a_GlobalController)
            obj.a_GlobalController{i_gc}.initialize(true);   % may read the units just set
        end

        % the point that was set must satisfy Kirchhoff's current law at every bus (only a
        % solve writes V and I; the other steps recompute from the held V and I)
        if l_solve
            sv_Bus  = string(obj.a_Bus);
            tab_Y   = obj.get_admittance_matrix;
            r_resid = max(abs(tab_Y{sv_Bus,sv_Bus}*obj.cv_Vequilibrium - obj.cv_Iequilibrium), [], "includenan");
            if ~(r_resid < equilibrium_tolerance())
                error(msg("GUILDA:PowerNetwork:InitializeNotEquilibrium", char(s_method), char(string(r_resid))))
            end
        end

        % the models must hold the point; sizes stop here
        s_residual = large_model_residuals(obj);
    catch ME
        % a partly written point is never used: the next initialize solves it again
        obj.sct_stale.powerflow(end+1,1) = obj.s_tag + ": the last initialize stopped before it finished";
        rethrow(ME)
    end
    obj.sct_stale.powerflow = strings(0,1);
    obj.sct_stale.odefcn    = strings(0,1);
    obj.sct_stale.input     = strings(0,1);
    if ~isempty(sv_input) && s_method ~= "FixedInput"
        show_msg("info", "GUILDA:PowerNetwork:InputOverwritten", char(s_method), char(stale_list(sv_input)))
    end

    if s_residual ~= ""
        show_msg("warning", "GUILDA:PowerNetwork:EquilibriumResidual", char(string(equilibrium_tolerance())), char(s_residual))
    end

    [n_island, s_island] = network_islands(obj);
    if n_island > 1
        show_msg("warning", "GUILDA:PowerNetwork:NetworkIsland", string(obj), char(string(n_island)), char(s_island))
    end
end


function [result, flag, output, rm_pf] = solve_powerflow(obj, c_nv, s_format)
% The power flow; a slack bus that calculate_powerflow set is released when it fails.
% calculate_powerflow is asked for the n-by-4 array rm_pf (V, I, P, Q), which initialize
% writes; only "GUILDAorigin" builds the ResultPF
    lv_slack = tools.vcellfun(@(b) b.l_isSlack, obj.a_Bus);
    s_request = "powerflow(mat)";
    if s_format == "GUILDAorigin"
        s_request = "GUILDAorigin";
    end
    try
        [result, flag, output] = obj.calculate_powerflow(c_nv{:}, Format=s_request);
        l_ok = flag > 0;
    catch ME
        l_ok = false;
    end
    if ~l_ok && ~any(lv_slack)
        release_slack(obj);
    end
    if exist("ME", "var")
        rethrow(ME)
    end
    if ~l_ok
        stop_powerflow(obj, output)
    end
    if s_format == "GUILDAorigin"
        tab_bus = result.tab_bus;
        rm_pf   = powerflow_matrix(tab_bus.Vphasor, tab_bus.Iphasor);
    else
        rm_pf   = result;
        result  = format_powerflow(s_format, string(obj.a_Bus), rm_pf, @() []);
    end
end


function [result, flag, output] = solve_opf(obj, c_nv)
% The AC OPF
    try
        [result, flag, output] = obj.optimize_powerflow(c_nv{:}, "Method", "AC OPF");
    catch ME
        % building the OPF problem of a split network can stop with an internal error:
        % those have an identifier, while error(msg(...)) of GUILDA has none
        if ~isempty(ME.identifier) && ~startsWith(ME.identifier, "GUILDA:") && network_islands(obj) > 1
            stop_opf(obj, struct("message", ME.message))
        end
        rethrow(ME)
    end
    if ~result.l_success
        stop_opf(obj, output)
    end
end


function write_powerflow(obj, rm_pf, c_PQ)
% Bus.set_equilibrium of every bus with the solved point (the components and their local
% controllers set theirs); c_PQ{i} is [P Q] of the components of bus i when the analysis
% fixes them, [] lets Bus.set_equilibrium distribute
    for i_bus = 1:numel(obj.a_Bus)
        obj.a_Bus{i_bus}.set_equilibrium(rm_pf(i_bus,1), rm_pf(i_bus,2), real(rm_pf(i_bus,3)), real(rm_pf(i_bus,4)), "rm_PQ", c_PQ{i_bus})
    end
end


function [rm_pf, c_PQ] = opf_point(obj, result)
% The bus V, I, P, Q of an "AC OPF" result, and [P Q] of the components of each bus
    tab_bus = result.tab_bus;
    rm_pf   = powerflow_matrix(tab_bus.Vphasor, tab_bus.Iphasor);
    n_Bus = numel(obj.a_Bus);
    c_PQ  = cell(n_Bus,1);
    for i_bus = 1:n_Bus
        a_Comp = obj.a_Bus{i_bus}.a_Component;
        if ~isempty(a_Comp)
            c_PQ{i_bus} = real(result.tab_cub{string(a_Comp),["P","Q"]});
        end
    end
end


function [result, flag, output, sct_point] = solve_fixed(obj, c_nv, s_format)
% The equilibrium with the held inputs (solve_fixed_input). A slack bus is selected as by
% calculate_powerflow and released again when the solve fails; a network split into
% islands stops before the solve
    lv_slack = tools.vcellfun(@(b) b.l_isSlack, obj.a_Bus);
    if ~any(lv_slack)
        if isempty(obj.a_Bus)
            error(msg("GUILDA:PowerNetwork:NoBus", string(obj)))
        end
        i_bus = tools.slack_bus_index(obj);
        if isempty(i_bus)
            error(msg("GUILDA:PowerNetwork:NoSlackCandidate", string(obj)))
        end
        show_msg("info", "GUILDA:PowerNetwork:SlackSelected", string(obj.a_Bus{i_bus}))
        obj.a_Bus{i_bus}.l_isSlack = true;
    end
    try
        [n_island, s_island] = network_islands(obj);
        if n_island > 1
            error(msg("GUILDA:PowerNetwork:InitializeFixedInputIsland", string(obj), char(string(n_island)), char(s_island)))
        end
        [result, flag, output, sct_point] = solve_fixed_input(obj, c_nv, s_format);
        if flag ~= 1
            error(msg("GUILDA:PowerNetwork:InitializeFixedInputFailed", char(string(output.message))))
        end
    catch ME
        if ~any(lv_slack)
            release_slack(obj);
        end
        rethrow(ME)
    end
end


function write_fixed_input(obj, sct_point)
% Bus.set_equilibrium of every bus with the solved voltage and the states, inputs and
% powers of its components (stored as solved: get_equilibrium is not called)
    for i_bus = 1:numel(obj.a_Bus)
        iv_k = find(sct_point.iv_bus == i_bus);
        c_V  = sct_point.cv_V(i_bus);
        cv_I = sct_point.cv_I(iv_k);
        cv_S = c_V .* conj(cv_I);
        c_XU = [sct_point.c_X(iv_k), sct_point.c_U(iv_k)];
        rm_PQ = [real(cv_S), imag(cv_S)];
        if isempty(iv_k)
            rm_PQ = [];
            c_XU  = {};
        end
        obj.a_Bus{i_bus}.set_equilibrium(c_V, sum(cv_I), real(sum(cv_S)), imag(sum(cv_S)), ...
                                         "rm_PQ", rm_PQ, "c_XU", c_XU)
    end
end


function [s_format, c_nv] = take_format(c_in)
% Separates Format (of initialize, default "powerflow(mat)") from the other options; checks its value
    s_format = "powerflow(mat)";
    c_nv     = c_in;
    if mod(numel(c_in), 2) ~= 0
        return              % take_method reports it
    end
    lv_format = false(size(c_in));
    for k = 1:2:numel(c_in)
        x = c_in{k};
        if ((ischar(x) && isrow(x)) || (isstring(x) && isscalar(x))) && strcmpi(x, "Format")
            lv_format(k:k+1) = true;
            s_format = check_format(c_in{k+1});
        end
    end
    c_nv = c_in(~lv_format);
end


function s_format = check_format(s_format)
% A value of Format, as the arguments block of calculate_powerflow checks it
    arguments (Input)
        s_format (1,1) string {mustBeMember(s_format, ["V","powerflow(mat)","powerflow(tab)","GUILDAorigin"])} % Format option.
    end
    arguments (Output)
        s_format (1,1) string % The same value.
    end
end


function [s_method, c_nv, l_given] = take_method(c_in)
% Separates Method (of initialize) from the options passed to the analysis; l_given is
% true when Method was given
    sr_method = ["powerflow","OPF","FixedInput","equilibrium"];
    if mod(numel(c_in), 2) ~= 0
        error(msg("GUILDA:PowerNetwork:InitializePairs"))
    end
    s_method   = "powerflow";
    l_given    = false;
    lv_method  = false(size(c_in));
    for k = 1:2:numel(c_in)
        x = c_in{k};
        if ((ischar(x) && isrow(x)) || (isstring(x) && isscalar(x))) && strcmpi(x, "Method")
            lv_method(k:k+1) = true;
            v = c_in{k+1};
            l_text = (ischar(v) && isrow(v)) || (isstring(v) && isscalar(v));
            if ~l_text || ~any(strcmpi(v, sr_method))
                error(msg("GUILDA:PowerNetwork:InitializeMethod", char(join('"' + sr_method + '"', ", "))))
            end
            s_method = sr_method(strcmpi(v, sr_method));
            l_given  = true;
        end
    end
    c_nv = c_in(~lv_method);
end


function stop_powerflow(obj, output)
% Error of a failed power flow: names the islands of a split network instead of the solver settings
    [n_island, s_island] = network_islands(obj);
    s_reason = char(string(output.message));
    if n_island > 1
        error(msg("GUILDA:PowerNetwork:InitializePowerflowIsland", s_reason, string(obj), char(string(n_island)), char(s_island)))
    end
    error(msg("GUILDA:PowerNetwork:InitializePowerflowFailed", s_reason))
end


function stop_opf(obj, output)
% Error of a failed OPF: names the islands of a split network instead of the solver settings
    [n_island, s_island] = network_islands(obj);
    s_reason = char(string(output.message));
    if n_island > 1
        error(msg("GUILDA:PowerNetwork:InitializeOPFIsland", s_reason, string(obj), char(string(n_island)), char(s_island)))
    end
    error(msg("GUILDA:PowerNetwork:InitializeOPFFailed", s_reason))
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


function s_list = stale_list(sv)
% The first messages of sv as one text
    s_list = join(sv(1:min(end,3)), "; ");
    if numel(sv) > 3
        s_list = s_list + "; ...";
    end
end


function release_slack(obj)
% Releases the slack bus that calculate_powerflow set because none was set
    for i_bus = 1:numel(obj.a_Bus)
        obj.a_Bus{i_bus}.l_isSlack = false;
    end
end


function tol = equilibrium_tolerance()
% Largest allowed max|Y*V-I| [pu] of an equilibrium, and largest model residual that does not warn
    tol = 1e-6;
end


function s_list = large_model_residuals(obj)
% The models above the tolerance and their residuals, as text ("" for none)
    n_show = 10;   % models that the text lists
    [sv_tag, rm_resid] = model_residuals(obj);
    lv_large = ~(max(rm_resid, [], 2, "includenan") < equilibrium_tolerance());
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


function [sv_tag, rm_resid] = model_residuals(obj)
% Residual of each model at the point that was set: max|dx|, |I - Iequilibrium| and the
% largest difference between an input and what drives it in a simulation
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
end


function c_row = component_residuals(comp)
% Rows of the component and of its local controllers (depth first)
    check_point_size(comp, numel(comp.sv_u));
    x = comp.rv_Xequilibrium;
    u = comp.rv_Uequilibrium;
    c_I = comp.c_Iequilibrium;
    V = [real(comp.c_Vequilibrium); imag(comp.c_Vequilibrium)];

    dx  = model_value(comp, "fcn_dx", numel(comp.sv_x), @() comp.f_dx(0, x, V, u));
    c_Ic = model_value(comp, "fcn_I", 1, @() comp.f_I(0, x, V, u));

    c_row = cell(0,1);
    rv_source = u;
    if ~isempty(comp.a_LocalController)
        y = model_value(comp, "fcn_Y", numel(comp.sv_y), @() comp.f_Y(0, x, V));
        [rv_source, c_row] = nested_outputs(comp, rv_source, x, y, V);
    end
    c_row = [{{string(comp.s_tag), [largest(dx), abs(c_Ic - c_I), largest(u - rv_source)]}}; c_row];
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
    c_row = [{{string(con.s_tag), [largest(dx), 0, largest(u - rv_source)]}}; c_row];
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
    y  = gc.f_Y(0, x, V, u);
    c_row = {{string(gc.s_tag), [largest(dx), 0, largest(y)]}};
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


function r = largest(v)
% Largest magnitude; 0 for no elements and NaN when an element is NaN
    r = max([abs(v(:)); 0], [], "includenan");
end


function [result, flag, output] = calculate_from_equilibrium(obj, s_format)
% Build the bus equilibrium from the equilibria stored in the components
%   Vbus : the voltage the components on the bus hold
%   Ibus : the sum of the currents the components on the bus inject
%   Buses without components inject no current; their voltage is solved from Y*V = I.

    t0      = tic;
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

    % voltage of the buses without components (zero injection)
    if any(~lv_known)
        cv_Vbus(~lv_known) = - cm_Y(~lv_known,~lv_known) \ (cm_Y(~lv_known,lv_known)*cv_Vbus(lv_known));
    end

    % consistency check: Kirchhoff's current law at every bus
    tol     = equilibrium_tolerance();
    r_resid = max(abs(cm_Y*cv_Vbus - cv_Ibus));
    if r_resid >= tol
        error(msg("GUILDA:PowerNetwork:InitializeEquilibriumFailed", char(string(r_resid))))
    end
    flag   = 1;
    output = struct("residual", r_resid, ...
                    "message", "The equilibria of the components satisfy the network equations.");

    rm_pf = powerflow_matrix(cv_Vbus, cv_Ibus);
    sct_solver = struct("solver", "equilibrium", "options", struct("Method","equilibrium","Tolerance",tol), ...
        "flag", flag, "output", output, "elapsed", toc(t0));
    result = format_powerflow(s_format, sv_Bus(:), rm_pf, ...
        @() ResultPF(powerflow_table(sv_Bus(:), rm_pf), cm_Y, struct(obj, false), sct_solver));
end
