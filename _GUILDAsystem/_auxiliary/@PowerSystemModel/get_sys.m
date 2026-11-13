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
% | PowerNetwork | inputs u of the components | outputs y and yc | algebraic: 0 = Y v - I of the components, eliminated for Type "ODE" |
% | Bus, Component | V, u, uc | I, y, yc | inputs |
% | LocalController | V of its bus, its inputs | its outputs | inputs |
% | GlobalController | V of all buses, its inputs | its outputs | inputs |
%
% The names are the Labels of the variable map of the layer (obj.get_variable_map); the
% states follow its order. The current of a
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
% InputName and OutputName hold the model of its Type (the Type of the call) with the
% selected Input and Output. "struct" is a struct with these eight fields and "ss" a
% descriptor state-space model (dss, Control System Toolbox): they stop with the error of
% ResultLIN.get_ss when flag is false (except "DAE" with a singular Avv).
%
% Type chooses the model of the network: "DAE" is the connected model, with the bus
% voltages as algebraic variables (E is singular on their rows), in the bus variables of
% Coordinate; "ODE" is the model with the bus voltages eliminated (SolverLIN.reduce).
% The result keeps the DAE, so res.Type switches between them later.
%
% <@Examples>
% ```matlab
% res = net.get_sys();                          % ResultLIN of the network (Type of GUILDA.setting)
% eig(res.A, res.E)
% sct = net.get_sys(Type="DAE", Format="struct");
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
        opt.Type (1,1) string {mustBeMember(opt.Type, ["ODE","DAE"])}   % Model of the network: "ODE" (the bus voltages eliminated) or "DAE" (the connected model). Default: GUILDA.setting.
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
    sct_cfg = GUILDA.config("Linearization");
    for s = ["Type","Coordinate","PlotFcn"]
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
    sct_port = obj.get_linear_port();
    a_comp = a_obj(cellfun(@(o) isa(o, "Component"), a_obj));
    sct_port.tab_current = current_table(a_comp);
    if isa(obj, "PowerNetwork")
        sct_port.tab_stamp = admittance_stamps(obj);   % the parts of cm_Y: branches, bus shunts
    end
    if isa(obj, "PowerNetwork")
        solver = obj.solver_LIN;
    else
        solver = SolverLIN();
    end
    [sct_sys, output] = solver.solve(c_block, tab, tab_c, sct_port);
    sct_sys.tab_owner = owner_table(obj, a_obj);   % the classes of the owners of the terms

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
    elseif output.s_issue == "SingularAvv"   % only the network has algebraic voltages
        n_x = output.n_x;
        output.message = output.message + sprintf(" Avv is singular (rcond = %g): the current balance does not determine %s.", ...
            output.rcond_Avv, list_labels(singular_voltages(sct_sys.A(n_x+1:end, n_x+1:end), sct_port.sv_algebraic)));
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

    sct_options = struct("Type", opt.Type, "Coordinate", opt.Coordinate, "PlotFcn", opt.PlotFcn, "Point", {point});
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
            result.get_ss(opt.Type, c_channel{:}, Format="struct");   % stops with the reason, if any
        end
    else
        sys = result.get_ss(opt.Type, c_channel{:}, Format=opt.Format);
    end
    output.result = result;
end


function [net, a_obj, tab, tab_c] = layer_maps(obj)
% Network of the layer, its model objects in the order of the variable map, the variable
% map (rows x, Vre, Vim, u or uc first) and the connection map (none for a controller:
% the sources of its inputs are not rows of its map)
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
        net = root_component(obj).a_Bus.a_PowerNetwork;
        tab = obj.get_variable_map();
        tab_c = empty_connections();
        a_obj = {obj};
    elseif isa(obj, "GlobalController")
        net = obj.a_PowerNetwork;
        tab = obj.get_variable_map();
        tab_c = empty_connections();
        a_obj = {obj};
    else
        obj.get_linear_port();     % NoLinearModel
    end
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
        S.s_tag = string(obj.s_tag);
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
        S.s_tag = string(o.s_tag);
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


function tab = admittance_stamps(net)
% Admittance stamps of the network, which sum to net.get_admittance_matrix(): the 2-by-2
% matrix of each branch at its two buses, and the shunt Gshunt + j*Bshunt of each bus
    n_br  = numel(net.a_Branch);
    n_bus = numel(net.a_Bus);
    sv_owner = strings(n_br + n_bus, 1);
    c_bus = cell(n_br + n_bus, 1);
    c_Y   = cell(n_br + n_bus, 1);
    for i = 1:n_br
        br = net.a_Branch{i};
        sv_owner(i) = string(br.s_tag);
        c_bus{i} = reshape(string(br.a_Bus), 1, []);
        c_Y{i}   = br.get_admittance_matrix();
    end
    for i = 1:n_bus
        b = net.a_Bus{i};
        para = b.a_Parameter{cellfun(@(p) p.s_tag == "dynamics", b.a_Parameter)}.tab_parameter;
        sv_owner(n_br+i) = string(b.s_tag);
        c_bus{n_br+i} = string(b.s_tag);
        c_Y{n_br+i}   = [para.Gshunt, para.Bshunt]*[1; 1j];
    end
    tab = table(sv_owner, c_bus, c_Y, VariableNames=["Owner","Bus","Y"]);
end


function tab = owner_table(obj, a_obj)
% Tag and class of each element of the layer: its model objects and, for the network, its
% buses and branches (for a bus, the bus)
    if isa(obj, "PowerNetwork")
        a_obj = [a_obj(:); obj.a_Bus(:); obj.a_Branch(:)];
    elseif isa(obj, "Bus")
        a_obj = [a_obj(:); {obj}];
    end
    sv_tag   = strings(numel(a_obj),1);
    sv_class = strings(numel(a_obj),1);
    for k = 1:numel(a_obj)
        sv_tag(k)   = string(a_obj{k}.s_tag);
        sv_class(k) = string(class(a_obj{k}));
    end
    tab = table(sv_tag, sv_class, VariableNames=["Owner","Class"]);
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
