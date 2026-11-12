function con = add_global_controller(obj, Key, a_Unit, opt)
% Build a global controller from its model key, add it to the network and return it.
%
% `Key` is the model key of a global controller class (`keys(GUILDA.keymap("GlobalController"))`
% lists them). `a_Unit` gives the controlled components of this network, as
% Component objects (a cell array) or as tags. `parameter` gives the parameters of the
% constructor as a struct (or a one-row table) of Name=Value; omitted fields keep the
% class defaults. The controller tag is the class header, a number and the network tag,
% e.g. "AGC1IEEE9bus".
%
% Each controlled unit must have the inputs `sv_u` of the controller as outputs or states,
% and each output `sv_y` as an input of the unit or of one of its local controllers. Where
% each output goes is read from the connection map (net.get_variable_map, rows "global"):
% to every local controller of the unit (nested ones included) with an input of that
% name, otherwise to the input of the unit. An INFO message lists these connections
% (source -> target, by Label). The addition is a "Topology" edit of the controller: its
% own equilibrium and handles are stale until net.initialize(); the power flow is not.
%
% <@Examples>
% ```matlab
% agc = net.add_global_controller("agc-PI", ["SG1B001","SG1B002"], parameter=struct(kP=100, kI=500));
% g3  = net.a_Bus{3}.a_Component{1};
% agc = net.add_global_controller("agc-PI", {g3});
% ```
%
% See also PowerNetwork.remove_global_controller, GlobalController, controller.agc.broadcast_PI_AGC
%
% <@Group> Model building
    arguments (Input)
        obj
        Key           (1,:) char {tools.mustBeKeyOf(Key, "GlobalController")}   % Global controller model key, e.g. "agc-PI".
        a_Unit                                                          % Controlled components of this network: Component objects (cell array or one object) or tags.
        opt.parameter {mustBeA(opt.parameter, ["struct","table"])} = struct()   % Constructor parameters (struct or one-row table of Name=Value); omitted ones use the class defaults.
    end
    arguments (Output)
        con   % Added GlobalController object.
    end

    % Build Instance
    % largest number among the global controllers of this network + 1
    s_index = num2str(tools.next_tag_number(string(obj.a_GlobalController), obj.s_tag)) + obj.s_tag;
    if iscell(a_Unit)
        c_unit = a_Unit(:)';
    elseif isstring(a_Unit) || ischar(a_Unit)
        c_unit = cellstr(a_Unit(:)');
    else
        c_unit = num2cell(a_Unit(:)');
    end
    sct_para = opt.parameter;
    if istable(sct_para)
        sct_para = table2struct(sct_para);
    end
    c_para = namedargs2cell(sct_para);

    % get controller function
    dic    = GUILDA.keymap("GlobalController");
    mkInst = str2func(dic(string(Key)));
    con = mkInst(obj, s_index, c_unit{:}, c_para{:});

    if ismember(con.s_tag, string(obj.a_GlobalController))
        error(msg("GUILDA:PowerNetwork:GconTagInUse", char(con.s_tag), char(obj.s_tag)))
    end
    for idx = 1:numel(con.controlledUnits)
        unit = con.controlledUnits{idx};
        % Compare handles: isequal would accept an identical copy of the network
        if isempty(unit.a_Bus) || isempty(unit.a_Bus.a_PowerNetwork) || unit.a_Bus.a_PowerNetwork ~= obj
            error(msg("GUILDA:PowerNetwork:GconOtherNetwork", char(con.s_tag), char(unit.s_tag), char(obj.s_tag)))
        end
    end

    % The connections of the controller, from the map of the network with it: each input
    % must observe its unit ("observe") and each output drive an input ("global")
    % (with the network set, as after a successful add)
    obj.a_GlobalController = [obj.a_GlobalController; {con}];
    con.a_PowerNetwork = obj;
    try
        [tab, ~, c_idxGC, tab_c] = obj.get_variable_map();
    catch ME
        obj.a_GlobalController(end) = [];
        con.a_PowerNetwork = [];
        rethrow(ME)
    end
    iv_gc = c_idxGC{end};
    iv_uc = iv_gc(tab.Kind(iv_gc) == "uc");
    iv_yc = iv_gc(tab.Kind(iv_gc) == "yc");
    lv_glob = tab_c.Kind == "global" & ismember(tab_c.SourceIndex, iv_yc);
    lv_in   = ismember(iv_uc, tab_c.TargetIndex(tab_c.Kind == "observe"));
    lv_out  = ismember(iv_yc, tab_c.SourceIndex(lv_glob));
    n_u = numel(con.sv_u);
    n_o = numel(con.sv_y);
    for idx = 1:numel(con.controlledUnits)
        lv_i = lv_in((idx-1)*n_u + (1:n_u));
        lv_o = lv_out((idx-1)*n_o + (1:n_o));
        if ~all(lv_i) || ~all(lv_o)
            obj.a_GlobalController(end) = [];
            con.a_PowerNetwork = [];
            unit = con.controlledUnits{idx};
            sv_missing = ["output or state " + reshape(con.sv_u(~lv_i), [], 1); "input " + reshape(con.sv_y(~lv_o), [], 1)];
            error(msg("GUILDA:PowerNetwork:GconPorts", char(con.s_tag), char(unit.s_tag), class(unit), char(strjoin(sv_missing, ", "))))
        end
    end
    con.log_edit("added to " + obj.s_tag, "Topology");
    show_msg("info", "GUILDA:PowerNetwork:GconRoute", con.s_tag, join(tab_c.Source(lv_glob) + " -> " + tab_c.Target(lv_glob), "; "))
end
