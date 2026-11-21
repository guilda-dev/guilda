function [sys, flag, output] = get_sys(obj, point, opt)
% Linearize the layer and return its linear model.
%
% One method for every layer with a linear model: PowerNetwork, Bus, Component (with
% its local controllers), LocalController and GlobalController (Branch has none:
% GUILDA:PowerSystemModel:NoLinearModel). Each model object gives its own linear block
% (get_linear_matrix); get_sys takes the inputs and outputs of the layer (its port) from
% the variable map, and SolverLIN.solve connects the blocks along it. The linearization needs no
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
% obj.get_variable_map() (x, Vre, Vim, u, uc; for a controller x, Vre, Vim, uc), or
% {sim, t} (or {sim, t, "before"}) for the state of a simulation result at time t
% (PowerNetwork, Bus and Component).
% Time sections: {sim, rv_t} with several times, or a matrix with one point per column,
% linearizes the layer at each of them; the result holds one section per time or column
% (ResultLIN.rv_t: the times, or 1:n for a matrix; ResultLIN.Index chooses the section),
% and flag is true only when every section is usable (output.lv_flag of each section). Every value of the point is used as given: the
% inputs u of the components and uc of the controllers, whether the connection map drives
% them or holds them at a setpoint (Vref of an AVR, Pref of a governor). The outputs y and
% yc are evaluated at the point. The point sets the variables only: the
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
% ResultLIN.get_ss when flag is false (except "DAE" with a singular Avv). With several
% sections, "struct" is a 1 x n_t struct array and "ss" an ss array (sys(:,:,k) is
% section k). The ResultLIN of the network (Format "GUILDAorigin") keeps a snapshot of it,
% sct_network = struct(net, false).
%
% Type chooses the model of the network: "DAE" is the connected model, with the bus
% voltages as algebraic variables (E is singular on their rows), each bus written as the
% port of Port (see ResultLIN.get_ss); "ODE" is the model with the bus voltages eliminated (SolverLIN.reduce).
% The result keeps the DAE, so res.Type switches between them later.
%
% Form chooses the view of A ... E (ResultLIN.Form): "descriptor" (default; E holds the
% time constants), "absorbed" (E^-1 multiplied into the state rows) or "hessian", the
% energy-function form of the network: get_sys calls get_hessian of every component, local
% controller and global controller at the point of each section, and SolverLIN.solve
% assembles E_h dz/dt = H z over z = [x; theta; V] with E_h = -blkdiag(inv(R), 0) and
% H = [Hxx Hxv; Hvx Hvv + Hvv_net] (see ResultLIN). A class without the form stops with
% its GUILDA:<layer>:HessianNotSupported (the Static AVR and governor have empty blocks).
% "hessian" needs the network (GUILDA:PowerSystemModel:HessianNetworkOnly) and Port "PI"
% or "PQ" (GUILDA:PowerSystemModel:HessianPort). The result keeps the descriptor DAE too.
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
% res4 = net.get_sys({sim, [0.5, 1, 2]});       % three time sections; res4.Index = 2 shows t = 1
% sct4 = net.get_sys({sim, [0.5, 1, 2]}, Format="struct");   % 1 x 3 struct array
% resH = net.get_sys(Type="DAE", Port="PI", Form="hessian");  % energy-function form
% ```
%
% See also ResultLIN, SolverLIN, PowerNetwork.get_variable_map
%
% <@Group> Linearization
    arguments (Input)
        obj
        point = []                                               % Point: [] (the equilibrium), a vector in the order of get_variable_map(), a matrix (one point per column), {sim, rv_t} or {sim, rv_t, Side}.
        opt.Type (1,1) string {mustBeMember(opt.Type, ["ODE","DAE"])} = GUILDA.config("ApproximateLinearization", "Type")  % Model of the network: "ODE" (the bus voltages eliminated) or "DAE" (the connected model).
        opt.Port (1,1) string {mustBeMember(opt.Port, ["PI","PQ","I"])} = GUILDA.config("ApproximateLinearization", "Port")  % Bus port of "DAE" (v, w): "PI" ([theta,V], [P,Q/V]), "PQ" ([theta,rho], [P,Q]) or "I" ([Vre,Vim], [-Iim,Ire]).
        opt.PlotFcn = GUILDA.config("ApproximateLinearization", "PlotFcn")  % Live display: "none" (checked by tools.check_plotfcn; draw the eigenvalue map with result.plot_eigenvalue()).
        opt.Input (1,:) string                                   % Inputs of the model: "u" or Labels (see ResultLIN.get_ss). Default: all inputs.
        opt.Output (1,:) string                                  % Outputs of the model: "x", "V", "I", "y" or names (see ResultLIN.get_ss). Default: as in get_ss.
        opt.Format (1,1) string {mustBeMember(opt.Format, ["GUILDAorigin","struct","ss"])} = "GUILDAorigin"  % Form of sys: GUILDAorigin (a ResultLIN), struct or ss (dss).
        opt.Form (1,1) string {mustBeMember(opt.Form, ["descriptor","absorbed","hessian"])} = "descriptor"  % View of A ... E: "descriptor" (E holds the time constants), "absorbed" (E^-1 in A and B) or "hessian" (the energy-function form; network, Port PI or PQ).
    end
    arguments (Output)
        sys     % Linear model in the form of Format, with state, input and output names (1 x n_t struct or ss array for several sections).
        flag    % True when the result is usable: all entries are finite and Avv is invertible, in every section.
        output  % message, s_issue ("", "NotFinite" or "SingularAvv"), l_equilibrium, n_x, n_v, n_u, rcond_Avv, sv_faultBus, s_layer; per section lv_flag, sv_issue, sv_message, rv_rcond_Avv; result (the ResultLIN).
    end
    t0 = tic;
    SolverLIN.check_point(point);
    % The options of the call, with the defaults of GUILDA.setting; PlotFcn checked once
    opt.PlotFcn = tools.check_plotfcn(opt.PlotFcn, "get_sys");
    l_eq = isempty(point) && ~iscell(point);

    % The layer: its network, its model objects in the order of the variable map, the
    % variable map (rows x, Vre, Vim, u, uc first) and the connection map (none for a
    % controller: the sources of its inputs are not rows of its map)
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
    else   % Branch and any other layer
        error(msg("GUILDA:PowerSystemModel:NoLinearModel", class(obj), char(string(obj.s_tag))))
    end
    check_stale(obj, net, a_obj, l_eq);
    l_hessian = opt.Form == "hessian";
    if l_hessian && ~isa(obj, "PowerNetwork")
        error(msg("GUILDA:PowerSystemModel:HessianNetworkOnly", char(layer_text(obj))))
    elseif l_hessian && opt.Port == "I"
        error(msg("GUILDA:PowerSystemModel:HessianPort"))
    end
    [rm_point, rv_t] = SolverLIN.point_vector(obj, point);
    [n_lin, n_t] = size(rm_point);
    tab_p = tab(1:n_lin,:);

    % The port of the layer (sct_port of SolverLIN.solve), from its variable map tab:
    %
    % | Layer | sv_input | sv_output | sv_algebraic |
    % |---|---|---|---|
    % | PowerNetwork | u | y, yc | Vre, Vim (with cm_Y, the admittance matrix) |
    % | Bus, Component | V, u, uc | I of the layer, y, yc | none |
    % | LocalController, GlobalController | V, uc | yc | none |
    %
    % tab_bus has one row per bus of the layer (Bus, Vre, Vim, Ire, Iim); its currents are
    % those of the bus, or of the component for a component. tab_current holds the currents
    % of the components and, for the network, tab_stamp the parts of cm_Y.
    lab  = @(s_kind) tab.Label(tab.Kind == s_kind);
    sv_V = tab.Label(tab.Kind == "Vre" | tab.Kind == "Vim");
    if isa(obj, "PowerNetwork")
        a_bus = obj.a_Bus(:);
    elseif isa(obj, "GlobalController")
        a_bus = obj.a_PowerNetwork.a_Bus(:);
    elseif isa(obj, "LocalController")
        a_bus = {root_component(obj).a_Bus};
    elseif isa(obj, "Component")
        a_bus = {obj.a_Bus};
    else
        a_bus = {obj};
    end
    if isa(obj, "Bus") || isa(obj, "Component")
        sv_I = reshape(string(obj.attach_tag(["Ire";"Iim"])), [], 1);   % the current of the layer
    else
        sv_I = reshape(string(tools.vcellfun(@(b) reshape(string(b.attach_tag(["Ire";"Iim"])), [], 1), a_bus)), [], 1);
    end
    sv_tag  = reshape(string(tools.vcellfun(@(b) string(b.s_tag), a_bus)), [], 1);
    tab_bus = table(sv_tag, sv_V(1:2:end), sv_V(2:2:end), sv_I(1:2:end), sv_I(2:2:end), ...
                    VariableNames=["Bus","Vre","Vim","Ire","Iim"]);
    sv_algebraic = strings(0,1);
    cm_Y = zeros(0);
    if isa(obj, "PowerNetwork")
        sv_input  = lab("u");
        sv_output = [lab("y"); lab("yc")];
        sv_algebraic = sv_V;
        cm_Y = obj.get_admittance_matrix.Variables;
    elseif isa(obj, "Bus") || isa(obj, "Component")
        sv_input  = [sv_V; lab("u"); lab("uc")];
        sv_output = [sv_I; lab("y"); lab("yc")];
    else
        sv_input  = [sv_V; lab("uc")];
        sv_output = lab("yc");
    end
    sct_port = struct("sv_input", sv_input, "sv_output", sv_output, "sv_algebraic", sv_algebraic, ...
                      "cm_Y", cm_Y, "tab_bus", tab_bus);
    % the currents of the components: Label, Bus, Name (Ire or Iim)
    a_comp = a_obj(cellfun(@(o) isa(o, "Component"), a_obj));
    n_comp = numel(a_comp);
    sv_label = strings(2*n_comp,1);
    sv_bus   = strings(2*n_comp,1);
    for k = 1:n_comp
        sv_label(2*k-1:2*k) = reshape(string(a_comp{k}.attach_tag(["Ire";"Iim"])), [], 1);
        sv_bus(2*k-1:2*k)   = string(a_comp{k}.a_Bus.s_tag);
    end
    sct_port.tab_current = table(sv_label, sv_bus, repmat(["Ire";"Iim"], n_comp, 1), VariableNames=["Label","Bus","Name"]);
    if isa(obj, "PowerNetwork")
        % the admittance stamps, which sum to cm_Y: the 2-by-2 matrix of each branch at its
        % two buses, and the shunt Gshunt + j*Bshunt of each bus
        n_br  = numel(obj.a_Branch);
        n_bus = numel(obj.a_Bus);
        sv_owner = strings(n_br + n_bus, 1);
        c_bus = cell(n_br + n_bus, 1);
        c_Y   = cell(n_br + n_bus, 1);
        for i = 1:n_br
            br = obj.a_Branch{i};
            sv_owner(i) = string(br.s_tag);
            c_bus{i} = reshape(string(br.a_Bus), 1, []);
            c_Y{i}   = br.get_admittance_matrix();
        end
        for i = 1:n_bus
            b = obj.a_Bus{i};
            para = b.a_Parameter{cellfun(@(p) p.s_tag == "dynamics", b.a_Parameter)}.tab_parameter;
            sv_owner(n_br+i) = string(b.s_tag);
            c_bus{n_br+i} = string(b.s_tag);
            c_Y{n_br+i}   = [para.Gshunt, para.Bshunt]*[1; 1j];
        end
        sct_port.tab_stamp = table(sv_owner, c_bus, c_Y, VariableNames=["Owner","Bus","Y"]);
    end

    if isa(obj, "PowerNetwork")
        solver = obj.solver_LIN;
    else
        solver = SolverLIN();
    end
    % The classes of the owners of the terms: the model objects and, for the network, its
    % buses and branches (for a bus, the bus)
    if isa(obj, "PowerNetwork")
        a_own = [a_obj(:); obj.a_Bus(:); obj.a_Branch(:)];
    elseif isa(obj, "Bus")
        a_own = [a_obj(:); {obj}];
    else
        a_own = a_obj;
    end
    sv_ownTag   = strings(numel(a_own),1);
    sv_ownClass = strings(numel(a_own),1);
    for k = 1:numel(a_own)
        sv_ownTag(k)   = string(a_own{k}.s_tag);
        sv_ownClass(k) = string(class(a_own{k}));
    end
    tab_owner = table(sv_ownTag, sv_ownClass, VariableNames=["Owner","Class"]);
    sv_layer = ["PowerNetwork","Bus","Component","LocalController","GlobalController"];
    s_layer = sv_layer(find(arrayfun(@(s) isa(obj, s), sv_layer), 1));
    s_what = layer_text(obj);
    % A voltage below this is zero (a ground fault sets it to exactly 0)
    r_voltageMin = 1e-8;

    % Each section: the linear blocks of the objects at its point, each at the values of
    % its rows (the inputs u and uc as given; each block evaluates its outputs there),
    % connected by SolverLIN.solve
    lv_V = tab_p.Kind == "Vre" | tab_p.Kind == "Vim";
    c_sys      = cell(1, n_t);
    sv_issue   = strings(1, n_t);
    sv_message = strings(1, n_t);
    rv_rcond   = NaN(1, n_t);
    sv_faultBus = strings(0,1);
    for i_t = 1:n_t
        rv_point = rm_point(:, i_t);
        c_block = cell(numel(a_obj),1);
        if isa(obj, "LocalController") || isa(obj, "GlobalController")
            S = obj.get_linear_matrix(rv_point(tab_p.Kind == "x"), rv_point(lv_V), rv_point(tab_p.Kind == "uc"));
            S.Owner = layer_text(obj);
            S.s_tag = string(obj.s_tag);
            c_block{1} = S;
        else
            val  = @(o, s_kind) rv_point(tab_p.Kind == s_kind & tab_p.Owner == string(o.s_tag));
            V_of = @(c) rv_point(lv_V & tab_p.Bus == string(c.a_Bus.s_tag));
            for k = 1:numel(a_obj)
                o = a_obj{k};
                if isa(o, "Component")
                    S = o.get_linear_matrix(val(o, "x"), V_of(o), val(o, "u"));
                elseif isa(o, "LocalController")
                    S = o.get_linear_matrix(val(o, "x"), V_of(root_component(o)), val(o, "uc"));
                else
                    S = o.get_linear_matrix(val(o, "x"), rv_point(lv_V), val(o, "uc"));
                end
                if l_hessian
                    % the energy-function blocks at the same values (HessianNotSupported
                    % stops a class without them)
                    if isa(o, "Component")
                        S.sct_hessian = o.get_hessian(val(o, "x"), V_of(o), val(o, "u"));
                    elseif isa(o, "LocalController")
                        S.sct_hessian = o.get_hessian(val(o, "x"), V_of(root_component(o)), val(o, "uc"));
                    else
                        S.sct_hessian = o.get_hessian(val(o, "x"), rv_point(lv_V), val(o, "uc"));
                    end
                end
                S.Owner = layer_text(o);
                S.s_tag = string(o.s_tag);
                c_block{k} = S;
            end
        end
        if l_hessian
            sct_port.cv_V = tools.vec2complex(rv_point(lv_V));
        end
        [sct_sys, output] = solver.solve(c_block, tab, tab_c, sct_port);
        sct_sys.tab_owner = tab_owner;

        % The message of the section
        if l_eq
            s_message = "Linearized " + s_what + " at the equilibrium.";
        elseif n_t == 1
            s_message = "Linearized " + s_what + " at the given point.";
        elseif iscell(point)
            s_message = "Linearized " + s_what + sprintf(" at t = %g s (section %d of %d).", rv_t(i_t), i_t, n_t);
        else
            s_message = "Linearized " + s_what + sprintf(" at point %d of %d.", i_t, n_t);
        end
        if output.s_issue == "NotFinite"
            s_message = s_message + " Some Jacobian entries are not finite.";
        elseif output.s_issue == "SingularAvv"   % only the network has algebraic voltages
            % the bus voltages in the null space of Avv
            n_x = output.n_x;
            [~, rm_S, rm_W] = svd(sct_sys.A(n_x+1:end, n_x+1:end));
            rv_s = diag(rm_S);
            rv_w = vecnorm(rm_W(:, rv_s <= max(rv_s(end), 1e-12*rv_s(1))), 2, 2);
            s_message = s_message + sprintf(" Avv is singular (rcond = %g): the current balance does not determine %s.", ...
                output.rcond_Avv, list_labels(sct_port.sv_algebraic(rv_w > 0.1*max(rv_w))));
        end
        if isa(obj, "PowerNetwork")
            cv_V = tools.vec2complex(rv_point(lv_V));
            sct_sys.cm_Y = sct_port.cm_Y;
            sct_sys.cv_V = cv_V;
            sct_sys.sv_I = reshape([sct_port.tab_bus.Ire, sct_port.tab_bus.Iim].', [], 1);
            sv_fault = sct_port.tab_bus.Bus(abs(cv_V) < r_voltageMin);
            if ~isempty(sv_fault)
                s_message = s_message + " " + msg("GUILDA:PowerSystemModel:GroundFault", char(list_labels(sv_fault)));
                sv_faultBus = [sv_faultBus; sv_fault]; %#ok<AGROW>
            end
        end
        c_sys{i_t}      = sct_sys;
        sv_issue(i_t)   = output.s_issue;
        sv_message(i_t) = s_message;
        rv_rcond(i_t)   = output.rcond_Avv;
    end

    % The output of the whole run (the fields of one section describe all of them) and of
    % each section
    lv_flag = sv_issue == "";
    flag = all(lv_flag);
    sv_faultBus = unique(sv_faultBus, "stable");
    if n_t == 1
        output.message = sv_message(1);
    else
        output.message = "Linearized " + s_what + sprintf(" at %d sections.", n_t);
        if ~flag
            output.message = output.message + " Not usable: " + join("section " + string(find(~lv_flag)) + " (" + sv_issue(~lv_flag) + ")", ", ") + ".";
        end
        if ~isempty(sv_faultBus)
            output.message = output.message + " " + msg("GUILDA:PowerSystemModel:GroundFault", char(list_labels(sv_faultBus)));
        end
    end
    if ~isempty(sv_faultBus)
        show_msg("info", "GUILDA:PowerSystemModel:GroundFault", char(list_labels(sv_faultBus)))
    end
    output.s_issue = "";
    if ~flag
        output.s_issue = sv_issue(find(~lv_flag, 1));
    end
    output.rcond_Avv = min(rv_rcond);
    output.sv_faultBus = sv_faultBus;
    output.l_equilibrium = l_eq;
    output.s_layer = s_layer;
    output.lv_flag = lv_flag;
    output.sv_issue = sv_issue;
    output.sv_message = sv_message;
    output.rv_rcond_Avv = rv_rcond;

    sct_options = struct("Type", opt.Type, "Port", opt.Port, "Form", opt.Form, "PlotFcn", opt.PlotFcn, "Point", {point});
    c_channel = cell(1,0);
    for s = ["Input","Output"]
        if isfield(opt, s)
            sct_options.(s) = opt.(s);
            c_channel = [c_channel, {s, opt.(s)}]; %#ok<AGROW>
        end
    end
    % the snapshot of the network for the result that get_sys returns (struct and ss,
    % used in loops such as the stability-constrained OPF, skip its cost)
    sct_network = struct();
    if isa(obj, "PowerNetwork") && opt.Format == "GUILDAorigin"
        sct_network = struct(obj, false);
    end
    result = ResultLIN(net, solver, sct_options, flag, output, t0, tab_p, rm_point, c_sys, rv_t, sct_network);

    if opt.Format == "GUILDAorigin"
        sys = result;
        i_ok = find(lv_flag, 1);
        if ~isempty(i_ok) && ~isempty(c_channel)
            result.get_ss(opt.Type, c_channel{:}, Index=i_ok, Format="struct");   % stops with the reason, if any
        end
    elseif n_t == 1
        sys = result.get_ss(opt.Type, c_channel{:}, Format=opt.Format);
    elseif opt.Format == "struct"
        c_ss = cell(1, n_t);
        for i_t = 1:n_t
            c_ss{i_t} = result.get_ss(opt.Type, c_channel{:}, Index=i_t, Format="struct");
        end
        sys = [c_ss{:}];
    else
        sys = result.get_ss(opt.Type, c_channel{:}, Index=1, Format="ss");
        for i_t = 2:n_t
            sys(:,:,i_t) = result.get_ss(opt.Type, c_channel{:}, Index=i_t, Format="ss");
        end
    end
    output.result = result;
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


function str = list_labels(sv)
% Labels for a message, at most 8
    n = numel(sv);
    str = join(sv(1:min(n,8)), ", ");
    if n > 8
        str = str + sprintf(" and %d more", n-8);
    end
end
