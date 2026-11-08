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
% The controlled units must have the states `sv_u` and the inputs `sv_y` of the
% controller. The addition is a "Topology" edit of the controller: its own equilibrium
% and handles are stale until net.initialize(); the power flow is not.
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
        sv_missing = ["state "+con.sv_u(~ismember(con.sv_u, unit.sv_x)); ...
                       "input "+con.sv_y(~ismember(con.sv_y, unit.sv_u))];
        if ~isempty(sv_missing)
            error(msg("GUILDA:PowerNetwork:GconPorts", char(con.s_tag), char(unit.s_tag), class(unit), char(strjoin(sv_missing, ", "))))
        end
    end
    obj.a_GlobalController = [obj.a_GlobalController; {con}];
    con.a_PowerNetwork = obj;
    con.log_edit("added to " + obj.s_tag, "Topology");
end
