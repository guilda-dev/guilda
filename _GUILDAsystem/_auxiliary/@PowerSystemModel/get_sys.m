function [sys, flag, output] = get_sys(obj, point, opt)
% Linearize the layer and return its linear model.
%
% One method for every layer with a linear model: PowerNetwork, Bus, Component (with
% its local controllers), LocalController and GlobalController (Branch has none:
% GUILDA:PowerSystemModel:NoLinearModel). Each model object gives its own linear block
% (get_linear_block) and the layer its inputs and outputs (get_linear_port);
% SolverLIN.solve connects the blocks along the variable map. The linearization needs no
% toolbox, and the model is not changed.
%
% | Layer | Inputs | Outputs | Bus voltages |
% |---|---|---|---|
% | PowerNetwork | inputs u of the components | outputs y and yc | algebraic: 0 = Y v - I of the components, reduced by Method |
% | Bus, Component (Port "V2I") | V, u, uc | I, y, yc | inputs |
% | Bus, Component (Port "I2V") | I, u, uc | V, y, yc | algebraic, eliminated |
% | LocalController | V of its bus, its inputs | its outputs | inputs |
% | GlobalController | V of all buses, its inputs | its outputs | inputs |
%
% The names are the Labels of the variable map (get_variable_map; for a controller, the
% map of its component or network); the states follow its order. The current of a
% component is the component tag with Ire, Iim; that of a bus the bus tag. An input is
% the sum of its sources in the connection map plus the external input of that name.
%
% point, the first argument, gives the point: [] (the equilibrium set by net.initialize,
% the default), a vector of the variables of the layer in the order of the leading rows of
% obj.get_variable_map() (x, Vre, Vim, then u; for a controller x, Vre, Vim, then uc),
% or {sim, t} (or {sim, t, "before"}) for the state of a simulation result at time t
% (PowerNetwork, Bus and Component). The inputs of the controllers at the point are the
% sums of their sources (outputs and states of what they observe, outputs of nested
% controllers; an input without a source keeps its equilibrium). The point sets the variables only: the
% admittance matrix stays the one of the model, also inside a fault (reported with an
% INFO message and output.sv_faultBus).
%
% The layer stops with GUILDA:PowerSystemModel:Stale when net.initialize() is needed: an
% edited dynamics always, an edited network, power flow or equilibrium when the point is the
% equilibrium; with GUILDA:PowerSystemModel:InputEdited when the inputs were edited.
% A point with NaN or Inf stops with GUILDA:SolverLIN:PointNotFinite, and a model that is
% not finite at the point with GUILDA:SolverLIN:JacobianNotFinite.
%
% Format chooses the form of sys: "GUILDAorigin" (default) is the ResultLIN of the
% linearization, also when flag is false; its properties A, B, C, D, E, StateName,
% InputName and OutputName hold the model of Method with the selected Input and Output.
% "struct" is a struct with these eight fields and "ss" a descriptor state-space model
% (dss, Control System Toolbox): they stop with the error of ResultLIN.get_ss when flag
% is false (except "DAE" with a singular Avv).
%
% <@Examples>
% ```matlab
% res = net.get_sys();                          % ResultLIN of the network (Method of GUILDA.setting)
% eig(res.A, res.E)
% sct = net.get_sys(Method="DAE", Format="struct");
% resV = net.get_sys(Output="V");               % bus voltages as outputs
% sys = net.a_Bus{1}.a_Component{1}.get_sys(Format="ss");   % component, V to I
% res2 = net.get_sys({sim, 1.5});               % at a time of a simulation result
% res3 = net.get_sys(res.rv_point);             % at a vector in the order of net.get_variable_map()
% ```
%
% See also ResultLIN, SolverLIN, PowerNetwork.get_variable_map
%
% <@Group> Linearization
    arguments (Input)
        obj
        point = []                    % Point: [] (the equilibrium), a vector in the order of get_variable_map(), {sim, t} or {sim, t, Side}.
        opt.Port (1,1) string {mustBeMember(opt.Port, ["V2I","I2V"])}   % Ports of a Component or Bus: "V2I" (V to I) or "I2V". Default: "V2I".
        opt.Method (1,1) string {mustBeMember(opt.Method, ["Kron","DAE"])}   % Form of the model of the network: "Kron" (eliminate the bus voltages) or "DAE". Default: GUILDA.setting.
        opt.Coordinate (1,1) string {mustBeMember(opt.Coordinate, ["theta&V","theta&rho","Vre&Vim"])}   % Bus variables of "DAE". Default: GUILDA.setting.
        opt.PlotFcn                   % Live display: "none" (draw the eigenvalue map with result.plot_eigenvalue()). Default: GUILDA.setting.
        opt.Input (1,:) string        % Inputs of the model: "u" or Labels (see ResultLIN.get_ss). Default: all inputs.
        opt.Output (1,:) string       % Outputs of the model: "x", "V", "I", "y" or names (see ResultLIN.get_ss). Default: as in get_ss.
        opt.Format (1,1) string {mustBeMember(opt.Format, ["GUILDAorigin","struct","ss"])} = "GUILDAorigin"   % Form of sys: GUILDAorigin (a ResultLIN), struct or ss (dss).
    end
    arguments (Output)
        sys      % Linear model in the form of Format, with state, input and output names.
        flag     % True when the result is usable: all entries are finite and Avv is invertible.
        output   % message, s_issue ("", "NotFinite" or "SingularAvv"), l_equilibrium, n_x, n_v, n_u, rcond_Avv, sv_faultBus, s_layer; result (the ResultLIN).
    end
    t0 = tic;
    SolverLIN.check_point(point);
    l_port = isa(obj, "Component") || isa(obj, "Bus");
    if isfield(opt, "Port") && ~l_port
        error(msg("GUILDA:PowerSystemModel:PortNotApplicable", class(obj)))
    end
    if ~isfield(opt, "Port")
        opt.Port = "V2I";
    end
    sct_cfg = GUILDA.config("Linearization");
    for s = ["Method","Coordinate","PlotFcn"]
        if ~isfield(opt, s)
            opt.(s) = string(sct_cfg.(s).Value);
        end
    end
    tools.check_plotfcn(opt.PlotFcn, "get_sys");
    l_eq = isempty(point) && ~iscell(point);

    % The layer: its network, objects (blocks in the order of the variable map) and maps
    [net, a_obj, tab, tab_c] = layer_maps(obj);
    check_stale(obj, net, a_obj, l_eq);
    rv_point = SolverLIN.point_vector(obj, point);
    n_lin = numel(rv_point);

    % The blocks at the point, and the currents of the components
    c_block = blocks(obj, a_obj, tab, tab_c, rv_point);
    sct_port = obj.get_linear_port(opt.Port);
    a_comp = a_obj(cellfun(@(o) isa(o, "Component"), a_obj));
    sct_port.tab_current = current_table(a_comp);
    if isa(obj, "PowerNetwork")
        solver = obj.solver_LIN;
    else
        solver = SolverLIN();
    end
    [sct_sys, output] = solver.solve(c_block, tab, tab_c, sct_port);

    % Messages
    sv_layer = ["PowerNetwork","Bus","Component","LocalController","GlobalController"];
    s_layer = sv_layer(find(arrayfun(@(s) isa(obj, s), sv_layer), 1));
    s_what = layer_text(obj);
    if l_eq
        output.message = "Linearized " + s_what + " at the equilibrium.";
    else
        output.message = "Linearized " + s_what + " at the given point.";
    end
    if output.s_issue == "NotFinite"
        output.message = output.message + " Some Jacobian entries are not finite.";
    elseif output.s_issue == "SingularAvv"
        if isa(obj, "PowerNetwork")
            n_x = output.n_x;
            output.message = output.message + sprintf(" Avv is singular (rcond = %g): the current balance does not determine %s.", ...
                output.rcond_Avv, list_labels(singular_voltages(sct_sys.A(n_x+1:end, n_x+1:end), sct_port.sv_algebraic)));
        else
            % I2V of a component or bus: the current does not determine the voltage
            error(msg("GUILDA:PowerSystemModel:NoI2V", char(s_what)))
        end
    end
    flag = output.s_issue == "";
    output.sv_faultBus = strings(0,1);
    if isa(obj, "PowerNetwork")
        cv_V = tools.vec2complex(rv_point(tab.Kind(1:n_lin) == "Vre" | tab.Kind(1:n_lin) == "Vim"));
        sct_sys.cm_Y = sct_port.cm_Y;
        sct_sys.cv_V = cv_V;
        sct_sys.sv_I = reshape([sct_port.tab_bus.Ire, sct_port.tab_bus.Iim].', [], 1);
        % A voltage below this is zero (a ground fault sets it to exactly 0)
        r_voltageMin = 1e-8;
        output.sv_faultBus = sct_port.tab_bus.Bus(abs(cv_V) < r_voltageMin);
        if ~isempty(output.sv_faultBus)
            s_list = char(list_labels(output.sv_faultBus));
            output.message = output.message + " " + msg("GUILDA:PowerSystemModel:GroundFault", s_list);
            show_msg("info", "GUILDA:PowerSystemModel:GroundFault", s_list)
        end
    end
    output.l_equilibrium = l_eq;
    output.s_layer = s_layer;

    sct_options = struct("Method", opt.Method, "Coordinate", opt.Coordinate, "PlotFcn", opt.PlotFcn, "Point", {point});
    if l_port
        sct_options.Port = opt.Port;
    end
    c_channel = cell(1,0);
    for s = ["Input","Output"]
        if isfield(opt, s)
            sct_options.(s) = opt.(s);
            c_channel = [c_channel, {s, opt.(s)}]; %#ok<AGROW>
        end
    end
    result = ResultLIN(net, solver, sct_options, flag, output, t0, tab(1:n_lin,:), rv_point, sct_sys);

    if opt.Format == "GUILDAorigin"
        sys = result;
        if flag && ~isempty(c_channel)
            result.get_ss(opt.Method, c_channel{:}, Format="struct");   % stops with the reason, if any
        end
    else
        sys = result.get_ss(opt.Method, c_channel{:}, Format=opt.Format);
    end
    output.result = result;
end


function [net, a_obj, tab, tab_c] = layer_maps(obj)
% Network of the layer, its model objects in the order of the variable map, the variable
% map (rows x, Vre, Vim, u or uc first) and the connection map
    if isa(obj, "PowerNetwork")
        net = obj;
        [tab, ~, ~, tab_c] = obj.get_variable_map();
        a_obj = [comp_objects(obj.a_Bus); obj.a_GlobalController(:)];
    elseif isa(obj, "Bus")
        net = obj.a_PowerNetwork;
        [tab, ~, tab_c] = obj.get_variable_map();
        a_obj = comp_objects({obj});
    elseif isa(obj, "Component")
        net = obj.a_Bus.a_PowerNetwork;
        [tab, tab_c] = obj.get_variable_map();
        a_obj = [{obj}; all_controllers(obj)];
    elseif isa(obj, "LocalController")
        comp = obj.a_Component;
        while isa(comp, "LocalController")
            comp = comp.a_Component;
        end
        net = comp.a_Bus.a_PowerNetwork;
        tab = controller_map(comp.get_variable_map(), string(obj.s_tag));
        tab_c = empty_connections();
        a_obj = {obj};
    elseif isa(obj, "GlobalController")
        net = obj.a_PowerNetwork;
        tab = controller_map(net.get_variable_map(), string(obj.s_tag));
        tab_c = empty_connections();
        a_obj = {obj};
    else
        obj.get_linear_port("V2I");     % NoLinearModel
    end
end


function tab = controller_map(tab_parent, s_tag)
% Rows of a controller: its x, the bus voltages (of the parent map), its uc and yc
    lv_own = tab_parent.Owner == s_tag;
    iv = [find(lv_own & tab_parent.Kind == "x"); find(tab_parent.Kind == "Vre" | tab_parent.Kind == "Vim"); ...
          find(lv_own & tab_parent.Kind == "uc"); find(lv_own & tab_parent.Kind == "yc")];
    tab = tab_parent(iv,:);
    tab.Index = (1:height(tab))';
end


function tab_c = empty_connections()
    tab_c = table(zeros(0,1), strings(0,1), strings(0,1), strings(0,1), zeros(0,1), zeros(0,1), ...
                  VariableNames=["Index","Kind","Source","Target","SourceIndex","TargetIndex"]);
end


function check_stale(obj, net, a_obj, l_eq)
% net.initialize() is needed: edited inputs, an edited dynamics, or (at the equilibrium) an
% edited network, power flow or equilibrium
    if ~isempty(net.sct_stale.input)   % edited inputs: initialize(Method="FixedInput")
        sv_in = unique(net.sct_stale.input, "stable");
        error(msg("GUILDA:PowerSystemModel:InputEdited", char(layer_text(obj)), char(string(net.s_tag)), ...
                  char(join(sv_in(1:min(end,3)), "; "))))
    end
    sv = net.sct_stale.odefcn;
    if l_eq
        sv = [net.sct_stale.powerflow; sv];
    end
    for k = 1:numel(a_obj)
        if l_eq
            sv = [sv; a_obj{k}.sct_stale.equilibrium]; %#ok<AGROW>
        end
        sv = [sv; a_obj{k}.sct_stale.odefcn]; %#ok<AGROW>
    end
    if ~isempty(sv)
        sv = unique(sv, "stable");
        s_reason = join(sv(1:min(end,3)), "; ");
        if numel(sv) > 3
            s_reason = s_reason + "; ...";
        end
        error(msg("GUILDA:PowerSystemModel:Stale", char(layer_text(obj)), char(s_reason)))
    end
end


function c_block = blocks(obj, a_obj, tab, tab_c, rv_point)
% Linear blocks of the objects at the point. The values of the signals: the outputs y of
% the components, then the inputs uc and outputs yc of the controllers (the deepest local
% controllers first), each input the sum of its sources ("global" excluded)
    n_lin = numel(rv_point);
    val = [rv_point; zeros(height(tab) - n_lin, 1)];
    c_block = cell(numel(a_obj),1);
    if isa(obj, "LocalController") || isa(obj, "GlobalController")
        S = obj.get_linear_block(val(tab.Kind == "x"), val(tab.Kind == "Vre" | tab.Kind == "Vim"), val(tab.Kind == "uc"));
        S.Owner = layer_text(obj);
        c_block{1} = S;
        return
    end
    lv_V = tab.Kind == "Vre" | tab.Kind == "Vim";
    rows = @(o, s_kind) tab.Kind == s_kind & tab.Owner == string(o.s_tag);
    V_of = @(c) val(lv_V & tab.Bus == string(c.a_Bus.s_tag));
    % the components: outputs y
    lv_comp = cellfun(@(o) isa(o, "Component"), a_obj);
    for k = reshape(find(lv_comp), 1, [])
        c = a_obj{k};
        iv_y = find(rows(c, "y"));
        if ~isempty(iv_y)
            val(iv_y) = reshape(c.f_Y(0, val(rows(c, "x")), V_of(c)), [], 1);
        end
    end
    % the local controllers, deepest first (a nested controller follows its parent)
    lv_lc = cellfun(@(o) isa(o, "LocalController"), a_obj);
    for k = reshape(flip(find(lv_lc)), 1, [])
        con = a_obj{k};
        comp = root_component(con);
        iv_uc = find(rows(con, "uc"));
        val(iv_uc) = input_values(con, iv_uc, val, tab_c);
        iv_yc = find(rows(con, "yc"));
        if ~isempty(iv_yc)
            val(iv_yc) = reshape(con.f_Y(0, val(rows(con, "x")), V_of(comp), val(iv_uc)), [], 1);
        end
    end
    % the global controllers: their inputs observe the components
    for k = reshape(find(cellfun(@(o) isa(o, "GlobalController"), a_obj)), 1, [])
        gc = a_obj{k};
        iv_uc = find(rows(gc, "uc"));
        val(iv_uc) = input_values(gc, iv_uc, val, tab_c);
    end
    % the blocks
    for k = 1:numel(a_obj)
        o = a_obj{k};
        if isa(o, "Component")
            S = o.get_linear_block(val(rows(o, "x")), V_of(o), val(rows(o, "u")));
        elseif isa(o, "LocalController")
            S = o.get_linear_block(val(rows(o, "x")), V_of(root_component(o)), val(rows(o, "uc")));
        else
            S = o.get_linear_block(val(rows(o, "x")), val(lv_V), val(rows(o, "uc")));
        end
        S.Owner = layer_text(o);
        c_block{k} = S;
    end
end


function rv = input_values(con, iv_uc, val, tab_c)
% Inputs of a controller at the point: the sum of the sources of each input; an
% "equilibrium" row keeps the equilibrium of the input
    rv = zeros(numel(iv_uc),1);
    rv_eq = reshape(con.rv_Uequilibrium, [], 1);
    for m = 1:numel(iv_uc)
        tab_m = tab_c(tab_c.TargetIndex == iv_uc(m) & tab_c.Kind ~= "global", :);
        for r = 1:height(tab_m)
            if tab_m.Kind(r) == "equilibrium"
                rv(m) = rv(m) + rv_eq(m);
            else
                rv(m) = rv(m) + val(tab_m.SourceIndex(r));
            end
        end
    end
end


function tab = current_table(a_comp)
% Currents of the components: Label, Bus, Name (Ire or Iim)
    n = numel(a_comp);
    sv_label = strings(2*n,1);
    sv_bus   = strings(2*n,1);
    for k = 1:n
        sv_label(2*k-1:2*k) = reshape(string(a_comp{k}.attach_tag(["Ire";"Iim"])), [], 1);
        sv_bus(2*k-1:2*k)   = string(a_comp{k}.a_Bus.s_tag);
    end
    tab = table(sv_label, sv_bus, repmat(["Ire";"Iim"], n, 1), VariableNames=["Label","Bus","Name"]);
end


function a_obj = comp_objects(a_bus)
% Components with their local controllers (depth first), bus by bus
    a_obj = cell(0,1);
    for i = 1:numel(a_bus)
        for j = 1:numel(a_bus{i}.a_Component)
            c = a_bus{i}.a_Component{j};
            a_obj = [a_obj; {c}; all_controllers(c)]; %#ok<AGROW>
        end
    end
end


function list = all_controllers(parent)
    list = cell(0,1);
    for k = 1:numel(parent.a_LocalController)
        con  = parent.a_LocalController{k};
        list = [list; {con}; all_controllers(con)]; %#ok<AGROW>
    end
end


function comp = root_component(con)
    comp = con.a_Component;
    while isa(comp, "LocalController")
        comp = comp.a_Component;
    end
end


function str = layer_text(o)
% "component B001SG1 at bus B001", "the network IEEE14", ... for the messages
    s_tag = string(o.s_tag);
    if isa(o, "PowerNetwork")
        str = "the network " + s_tag;
    elseif isa(o, "Bus")
        str = "the bus " + s_tag;
    elseif isa(o, "Component")
        str = "the component " + s_tag + " at bus " + string(o.a_Bus.s_tag);
    elseif isa(o, "LocalController")
        str = "the local controller " + s_tag + " at bus " + string(root_component(o).a_Bus.s_tag);
    else
        str = "the global controller " + s_tag;
    end
end


function sv = singular_voltages(Avv, sv_v)
% Bus voltages in the null space of Avv
    [~, S, W] = svd(Avv);
    rv_s = diag(S);
    rv_w = vecnorm(W(:, rv_s <= max(rv_s(end), 1e-12*rv_s(1))), 2, 2);
    sv = sv_v(rv_w > 0.1*max(rv_w));
end


function str = list_labels(sv)
% Labels for a message, at most 8
    n = numel(sv);
    str = join(sv(1:min(n,8)), ", ");
    if n > 8
        str = str + sprintf(" and %d more", n-8);
    end
end
