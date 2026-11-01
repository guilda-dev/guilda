function [result, flag, output] = initialize(obj, varargin)
% Compute the operating point of the network and set it as its equilibrium.
%
% The operating point is set as the equilibrium of the buses, components, local
% controllers and global controllers, and the edit log is reset, so the analyses that
% need the equilibrium (simulate, linearize, get_sys) can run. initialize is one of the
% few analysis methods that change the model.
%
% Name-Value options:
%
% - `Method` — How the operating point is obtained. Default: "powerflow".
%   - "powerflow": net.calculate_powerflow (settings of net.solver_PF).
%   - "OPF": net.optimize_powerflow with Method="AC OPF" (settings of net.solver_OPF;
%     the AC formulation gives a complete AC operating point).
%   - "equilibrium": the equilibria the components already hold (from an earlier
%     initialize); buses without components get the voltage of Y*V = I. The states
%     and inputs are recomputed from the held V and I, so this follows edits of
%     dynamics parameters. Other edits that change the equilibrium (powerflow and
%     base parameters, topology, slack bus) stop with an error: use net.initialize().
% - Other options go unchanged to calculate_powerflow ("powerflow") or
%   optimize_powerflow ("OPF") and are validated there (unknown names stop with
%   GUILDA:resolve_options:UnknownName); "equilibrium" takes no other option. The
%   formulation of that analysis (its own Method) is not set here: use
%   net.solver_PF.Method for the power flow.
%
% When the analysis does not succeed (no convergence, an infeasible OPF, or stored
% equilibria that do not satisfy the network equations), initialize stops with an error
% naming the remedy, and the network keeps its previous equilibrium and edit log (a
% slack bus set by calculate_powerflow is released again). When setting the operating
% point fails afterwards, or the point does not satisfy Y*V = I, the equilibrium is left
% out of date, and analyses stop with GUILDA:PowerNetwork:EquilibriumStale until
% initialize succeeds.
%
% A network split into islands is a valid equilibrium when the power of each island
% balances, so a successful initialize only warns (GUILDA:PowerNetwork:NetworkIsland). A
% failed power flow or OPF on such a network names the islands in its error.
%
% The models are evaluated at the point that was set, with every Method. A state or input
% of the wrong size, a model function that returns the wrong size and a model function
% that stops are errors naming the model, and the equilibrium is left out of date. A
% residual of a component, local controller or global controller of 1e-6 or more only
% warns (GUILDA:PowerNetwork:EquilibriumResidual), because such a model can still be run:
% its states then move without a disturbance.
%
% <@Examples>
% ```matlab
% net = network.IEEE9bus();
% net.initialize();                                % power flow
% net.initialize(Method="equilibrium");            % re-set the stored equilibria
% res = net.initialize(Method="OPF", Solver="fmincon");
% res.r_cost                                       % cost of the OPF operating point
% ```
%
% See also PowerNetwork.calculate_powerflow, PowerNetwork.optimize_powerflow, PowerNetwork.simulate
    arguments (Output)
        result   % PowerFlowResult for "powerflow" and "equilibrium" (str_solver = "equilibrium", no branch flows), OPFResult for "OPF"; result.tab_bus is the bus equilibrium.
        flag     % Success flag of the analysis (positive; a failure stops with an error).
        output   % Details of the analysis; output.message describes the outcome.
    end

    varargin = v3_initialize_args(varargin);                  % COMPAT(v3)
    [str_method, c_nv] = take_method(varargin);

    obj.check_edit();    % rebuild f_* handles made stale by edits

    switch str_method
        case "powerflow"
            lv_slack = tools.vcellfun(@(b) b.l_isSlack, obj.a_Bus);
            try
                [result, flag, output] = obj.calculate_powerflow(c_nv{:});
                l_ok = result.l_success;
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
                error('GUILDA:PowerNetwork:InitializePowerflowFailed', '%s', ...
                      failure_message(obj, "InitializePowerflowFailed", "InitializePowerflowIsland", output))
            end
        case "OPF"
            try
                [result, flag, output] = obj.optimize_powerflow(c_nv{:}, "Method", "AC OPF");
            catch ME
                % building the OPF problem of a split network can stop with an internal error
                if ~startsWith(ME.identifier, "GUILDA:") && network_islands(obj) > 1
                    error('GUILDA:PowerNetwork:InitializeOPFFailed', '%s', ...
                          failure_message(obj, "InitializeOPFFailed", "InitializeOPFIsland", struct("message", ME.message)))
                end
                rethrow(ME)
            end
            if ~result.l_success
                error('GUILDA:PowerNetwork:InitializeOPFFailed', '%s', ...
                      failure_message(obj, "InitializeOPFFailed", "InitializeOPFIsland", output))
            end
        case "equilibrium"
            if ~isempty(c_nv)
                error('GUILDA:resolve_options:UnknownName', '%s', ...
                      msg('GUILDA:PowerNetwork:InitializeEquilibriumOption', char(string(c_nv{1}))))
            end
            check_edit_for_equilibrium(obj);
            [result, flag, output] = calculate_from_equilibrium(obj);
    end
    tab_PFsol = result.tab_bus;
    c_PQ      = component_power(obj, str_method, result);

    % stays set if a step below fails, so a partly written point is never used
    obj.l_staleEquilibrium = true;

    for i_gc = 1:numel(obj.a_GlobalController)
        a_GC = obj.a_GlobalController{i_gc};
        [a_GC.rv_Xequilibrium, a_GC.rv_Uequilibrium] = a_GC.get_equilibrium();
    end

    % distribute Qcomponent
    for i_bus = 1:numel(obj.a_Bus)
        rr_PFsol = tab_PFsol{i_bus,["Vphasor","Iphasor","P","Q"]};
        c_Vbus = rr_PFsol(1);
        c_Ibus = rr_PFsol(2);
        r_Pbus = rr_PFsol(3);
        r_Qbus = rr_PFsol(4);
        obj.a_Bus{i_bus}.set_equilibrium(c_Vbus,c_Ibus,r_Pbus,r_Qbus,"rm_PQ",c_PQ{i_bus})
    end

    % the point that was set must satisfy Kirchhoff's current law at every bus
    str_Bus = string(obj.a_Bus);
    tab_Y   = obj.get_admittance_matrix;
    r_resid = max(abs(tab_Y{str_Bus,str_Bus}*obj.cv_Vequilibrium - obj.cv_Iequilibrium), [], "includenan");
    if ~(r_resid < equilibrium_tolerance())
        error('GUILDA:PowerNetwork:InitializeNotEquilibrium', '%s', ...
              msg('GUILDA:PowerNetwork:InitializeNotEquilibrium', char(str_method), char(string(r_resid))))
    end

    % the models must hold the point; sizes stop here, while the equilibrium is out of date
    str_residual = large_model_residuals(obj);

    % reset log
    obj.reset_edit()

    if str_residual ~= ""
        warning('GUILDA:PowerNetwork:EquilibriumResidual', '%s', ...
                msg('GUILDA:PowerNetwork:EquilibriumResidual', char(string(equilibrium_tolerance())), char(str_residual)))
    end

    [n_island, str_island] = network_islands(obj);
    if n_island > 1
        warning('GUILDA:PowerNetwork:NetworkIsland', '%s', ...
                msg('GUILDA:PowerNetwork:NetworkIsland', string(obj), char(string(n_island)), char(str_island)))
    end
end


function [str_method, c_nv] = take_method(c_in)
% Separates Method (of initialize) from the options passed to the analysis
    sv_method = ["powerflow","OPF","equilibrium"];
    if mod(numel(c_in), 2) ~= 0
        error('GUILDA:resolve_options:InvalidPairs', '%s', msg('GUILDA:PowerNetwork:InitializePairs'))
    end
    str_method = "powerflow";
    lv_method  = false(size(c_in));
    for k = 1:2:numel(c_in)
        x = c_in{k};
        if ((ischar(x) && isrow(x)) || (isstring(x) && isscalar(x))) && strcmpi(x, "Method")
            lv_method(k:k+1) = true;
            v = c_in{k+1};
            l_text = (ischar(v) && isrow(v)) || (isstring(v) && isscalar(v));
            if ~l_text || ~any(strcmpi(v, sv_method))
                error('GUILDA:PowerNetwork:InitializeMethod', '%s', ...
                      msg('GUILDA:PowerNetwork:InitializeMethod', char(join('"' + sv_method + '"', ", "))))
            end
            str_method = sv_method(strcmpi(v, sv_method));
        end
    end
    c_nv = c_in(~lv_method);
end


function str = failure_message(obj, str_connected, str_split, output)
% Message of a failed analysis: names the islands of a split network instead of the solver settings
    [n_island, str_island] = network_islands(obj);
    str_reason = char(string(output.message));
    if n_island > 1
        str = msg("GUILDA:PowerNetwork:" + str_split, str_reason, string(obj), char(string(n_island)), char(str_island));
    else
        str = msg("GUILDA:PowerNetwork:" + str_connected, str_reason);
    end
end


function [n_island, str_island] = network_islands(obj)
% Number of the parts of the network that branches connect, and their bus tags as text
    n_show  = 10;   % islands, and buses per island, that the text lists
    str_Bus = string(obj.a_Bus);
    str_Bus = str_Bus(:);
    n_Br    = numel(obj.a_Branch);
    im_edge = zeros(n_Br,2);
    for i_br = 1:n_Br
        [~, im_edge(i_br,:)] = ismember(string(obj.a_Branch{i_br}.a_Bus), str_Bus);
    end
    rv_bin   = conncomp(graph(im_edge(:,1), im_edge(:,2), [], numel(str_Bus)));
    n_island = max([0, rv_bin]);

    sv = strings(1, min(n_island, n_show));
    for i_island = 1:numel(sv)
        sv_bus = str_Bus(rv_bin == i_island);
        if numel(sv_bus) > n_show
            sv_bus = [sv_bus(1:n_show); "... (" + numel(sv_bus) + " buses)"];
        end
        sv(i_island) = "[" + join(sv_bus, ", ") + "]";
    end
    str_island = join(sv, ", ");
    if n_island > n_show
        str_island = str_island + ", ...";
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


function str_list = large_model_residuals(obj)
% The models above the tolerance and their residuals, as text ("" for none)
    n_show = 10;   % models that the text lists
    [sv_tag, rm_resid] = model_residuals(obj);
    lv_large = ~(max(rm_resid, [], 2, "includenan") < equilibrium_tolerance());
    str_list = "";
    if any(lv_large)
        rm_large = rm_resid(lv_large,:);
        sv_line  = compose("'%s': |dx| = %.3g, |I - Iequilibrium| = %.3g, |u - source| = %.3g", ...
                           sv_tag(lv_large), rm_large(:,1), rm_large(:,2), rm_large(:,3));
        if numel(sv_line) > n_show
            sv_line = [sv_line(1:n_show); "... (" + numel(sv_line) + " models)"];
        end
        str_list = join(sv_line, newline);
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
    I = [real(c_I); imag(c_I)];

    dx  = model_value(comp, "fcn_dx", numel(comp.sv_x), @() comp.f_dx(0, x, V, I, u));
    c_Ic = model_value(comp, "fcn_I", 1, @() comp.f_I(0, x, V, I, u));

    c_row = cell(0,1);
    rv_source = u;
    if ~isempty(comp.a_LocalController)
        y = model_value(comp, "fcn_Y", numel(comp.sv_y), @() comp.f_Y(0, x, V, I, u));
        [rv_source, c_row] = nested_outputs(comp, rv_source, x, y, V, I);
    end
    c_row = [{{string(comp.str_tag), [largest(dx), abs(c_Ic - c_I), largest(u - rv_source)]}}; c_row];
end


function [rv_source, c_row] = nested_outputs(parent, rv_source, x_obs, y_obs, V, I)
% Replaces the inputs of parent driven by its local controllers with their outputs, as in
% get_dx_algebraic, and adds the rows of those controllers
    c_row = cell(0,1);
    for k = 1:numel(parent.a_LocalController)
        con = parent.a_LocalController{k};
        [y_con, c_con] = controller_residuals(con, x_obs, y_obs, V, I);
        c_row = [c_row; c_con]; %#ok<AGROW>
        [lv_u, iv_y] = ismember(reshape(string(parent.sv_u),[],1), reshape(string(con.sv_y),[],1));
        rv_source(lv_u) = y_con(iv_y(lv_u));
    end
end


function [y, c_row] = controller_residuals(con, x_obs, y_obs, V, I)
% Rows of the local controller and of its nested controllers, and its outputs
    check_point_size(con, numel(con.sv_u));
    x = con.rv_Xequilibrium;
    u = con.rv_Uequilibrium;

    dx = model_value(con, "fcn_dx", numel(con.sv_x), @() con.f_dx(0, x, V, I, u));
    y  = model_value(con, "fcn_y", numel(con.sv_y), @() con.f_Y(0, x, V, I, u));

    rv_source = u;
    lv_Y = con.iv_obsY > 0;
    lv_X = con.iv_obsX > 0;
    rv_source(lv_Y) = y_obs(con.iv_obsY(lv_Y));
    rv_source(lv_X) = x_obs(con.iv_obsX(lv_X));
    [rv_source, c_row] = nested_outputs(con, rv_source, x_obs, y_obs, V, I);
    c_row = [{{string(con.str_tag), [largest(dx), 0, largest(u - rv_source)]}}; c_row];
end


function c_row = global_controller_residual(gc)
% Row of the global controller. Its inputs are the states of its controlled units, and its
% outputs add to their inputs, so an output other than zero moves them.
    check_point_size(gc, numel(gc.controlledUnits)*numel(gc.sv_u));   % sv_u is read on each unit
    x = gc.rv_Xequilibrium;
    a_unit = gc.controlledUnits;
    c_u = cell(numel(a_unit),1);
    for k = 1:numel(a_unit)
        c_u{k} = reshape(a_unit{k}.rv_Xequilibrium(ismember(a_unit{k}.sv_x, gc.sv_u)), [], 1);
    end
    u = vertcat(zeros(0,1), c_u{:});

    dx = model_value(gc, "fcn_dx", numel(gc.sv_x), @() gc.f_dx(0, x, zeros(2,1), zeros(2,1), u));
    y  = gc.f_Y(0, x, zeros(2,1), zeros(2,1), u);
    c_row = {{string(gc.str_tag), [largest(dx), 0, largest(y)]}};
end


function check_point_size(model, n_uExpected)
% A state or input of the wrong size fails later in simulate with a generic size error
    n_x = numel(model.rv_Xequilibrium);
    n_u = numel(model.rv_Uequilibrium);
    if n_x ~= numel(model.sv_x) || n_u ~= n_uExpected
        error('GUILDA:PowerNetwork:InitializeEquilibriumSize', '%s', ...
              msg('GUILDA:PowerNetwork:InitializeEquilibriumSize', char(string(model.str_tag)), ...
                  char(string(n_x)), char(string(numel(model.sv_x))), char(string(n_u)), char(string(n_uExpected))))
    end
end


function val = model_value(model, str_fcn, n, f)
% Value of a model function at the point, which must have n elements
    str_tag = char(string(model.str_tag));
    try
        val = f();
    catch ME
        error('GUILDA:PowerNetwork:InitializeModelFailed', '%s', ...
              msg('GUILDA:PowerNetwork:InitializeModelFailed', str_tag, char(str_fcn), ME.message))
    end
    if numel(val) ~= n
        error('GUILDA:PowerNetwork:InitializeModelSize', '%s', ...
              msg('GUILDA:PowerNetwork:InitializeModelSize', str_tag, char(str_fcn), ...
                  char(join(string(size(val)), "x")), char(string(n))))
    end
    val = reshape(full(val), [], 1);
end


function r = largest(v)
% Largest magnitude; 0 for no elements and NaN when an element is NaN
    r = max([abs(v(:)); 0], [], "includenan");
end


function c_PQ = component_power(obj, str_method, result)
% [P Q] of the components of each bus when the analysis fixes them; [] lets Bus.set_equilibrium distribute
    n_Bus = numel(obj.a_Bus);
    c_PQ  = cell(n_Bus,1);
    for i_bus = 1:n_Bus
        a_Comp = obj.a_Bus{i_bus}.a_Component;
        if isempty(a_Comp)
            continue
        end
        switch str_method
            case "OPF"
                c_PQ{i_bus} = real(result.tab_cub{string(a_Comp),["P","Q"]});
            case "equilibrium"
                cv_S = cellfun(@(c) c.c_Vequilibrium*conj(c.c_Iequilibrium), a_Comp(:));
                c_PQ{i_bus} = [real(cv_S), imag(cv_S)];
        end
    end
end


function check_edit_for_equilibrium(obj)
% Stops when an edit since the last initialize would be lost by Method="equilibrium".
% Dynamics edits are not lost: the states and inputs are recomputed from the held V and I.
    if obj.str_editFlag == "unset"
        return
    end
    tab = obj.tab_editLog;
    [~, lv] = arrayfun(@(t, l) LayerPackage.edit_effect(t, l), string(tab.tag), string(tab.log));
    lv = lv & string(tab.tag) ~= "Parameter(dynamics)";
    if any(lv)
        str_edit = tab.ID(lv) + ": " + tab.log(lv);
        str_list = join(str_edit(1:min(end,3)), ", ");
        if numel(str_edit) > 3
            str_list = str_list + ", ...";
        end
        error('GUILDA:PowerNetwork:InitializeEquilibriumEdited', '%s', ...
              msg('GUILDA:PowerNetwork:InitializeEquilibriumEdited', char(str_list)))
    end
end


function [result, flag, output] = calculate_from_equilibrium(obj)
% Build the bus equilibrium from the equilibria stored in the components
%   Vbus : the voltage the components on the bus hold
%   Ibus : the sum of the currents the components on the bus inject
%   Buses without components inject no current; their voltage is solved from Y*V = I.

    t0      = tic;
    str_Bus = string(obj.a_Bus);
    n_Bus   = numel(str_Bus);
    tab_Y   = obj.get_admittance_matrix;
    cm_Y    = tab_Y{str_Bus,str_Bus};

    cv_Vbus  = nan(n_Bus,1);
    cv_Ibus  = zeros(n_Bus,1);
    lv_known = false(n_Bus,1);
    for i_bus = 1:n_Bus
        a_Comp = obj.a_Bus{i_bus}.a_Component;
        for i_comp = 1:numel(a_Comp)
            comp = a_Comp{i_comp};
            if isempty(comp.c_Vequilibrium) || isempty(comp.c_Iequilibrium)
                error('GUILDA:PowerNetwork:InitializeNoEquilibrium', '%s', ...
                      msg('GUILDA:PowerNetwork:InitializeNoEquilibrium', char(string(comp))))
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
        error('GUILDA:PowerNetwork:InitializeEquilibriumFailed', '%s', ...
              msg('GUILDA:PowerNetwork:InitializeEquilibriumFailed', char(string(r_resid))))
    end
    flag   = 1;
    output = struct("residual", r_resid, ...
                    "message", "The equilibria of the components satisfy the network equations.");

    cv_Sbus = cv_Vbus .* conj(cv_Ibus);
    tab_bus = array2table(...
        [angle(cv_Vbus),abs(cv_Vbus),real(cv_Sbus),imag(cv_Sbus),cv_Vbus,cv_Ibus], ...
        "VariableNames",["Varg","V","P","Q","Vphasor","Iphasor"],"RowNames",str_Bus);
    result  = PowerFlowResult(obj, "equilibrium", struct("Method","equilibrium","Tolerance",tol), ...
                              flag, output, t0, tab_bus);
end
