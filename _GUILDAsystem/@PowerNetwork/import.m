function net = import(path, opt)
% Build a network and its scenarios from a model folder.
%
% Builds a PowerNetwork from a model folder (the layout written by net.export):
%   <path>/network/parameter.csv        Hz, baseMVA of the network (optional)
%   <path>/bus/parameter.csv            one row per bus (V, Varg required)
%   <path>/branch/parameter.csv         one row per branch (Type, From, To required)
%   <path>/component/<key>/main.csv     one row per component of type <key> (Bus, P, Q required)
%   <path>/component/<key>/dynamics.csv parameters referenced by the column ParameterID
%   <path>/component/<key>/opf.csv      OPF settings referenced by the column OpfID
%   <path>/local_controller/<key>/parameter.csv   one row per local controller (optional)
%   <path>/local_controller/<key>/option.json     constructor arguments outside the table, by FullTag (optional)
%   <path>/global_controller/<key>/parameter.csv  one row per controlled component (optional)
%   <path>/scenario/<tag>.json          one scenario per file (optional)
% Buses are numbered by their row; From, To and Bus refer to these numbers.
% A missing network/parameter.csv (folders written before v4) or a missing or NaN value
% keeps the defaults Hz = GUILDA.config("PowerSystemModel","Hz") and baseMVA = 100.
% The bus column Slack (optional) marks the slack bus; a bus column baseMVA (v3) is
% accepted and ignored: the system base is net.tab_parameter.base.baseMVA.
% The column FullTag (optional) of the bus, branch and component tables gives the full
% tag of a row, and the bus column Tag is then not used. A missing column or an empty value
% keeps the automatic tag (folders written before FullTag), with Tag as the bus prefix.
% A local_controller/ folder is the full set of local controllers of the components of the
% folder: their controllers from creation (the default Static AVR and governor of a
% generator) are removed, and each row is attached with comp.add_local_controller(<key>,
% parameter=<the other columns of the row>) to the component whose full tag is in the
% column Component (the AVR or "local" controller first, then the PSS, then the governor),
% then given the tag of the column FullTag. The values of option.json under the FullTag of
% the row (arguments outside the table, such as Q and R of an LQR; see
% LocalController.get_option) are added to the parameters; a text array becomes a string
% array and an object {"re", "im"} a complex number. A component without rows has no controller.
% Without the folder the components keep their controllers from creation. Each global
% controller (rows of the same FullTag in global_controller/<key>/parameter.csv) is added
% after the local controllers and the slack bus with net.add_global_controller(<key>,
% <its Component column>, parameter=<its option.json values>) and its dynamics table is set
% to the other columns.
% With Network=obj the buses are added to the existing network obj instead of a new
% one; this is how the network classes such as network.IEEE14bus load their folder in
% their constructor.
% The scenarios are added after the controllers, in the order of the file names, by
% net.add_scenario(<file name>) with the Time, Description and disturbances of the file
% (see net.export); a tag in use gets a number suffix. A file that is not a scenario file
% stops with GUILDA:PowerNetwork:ScenarioJson; unknown fields give the warning
% GUILDA:PowerNetwork:UnknownScenarioField and are ignored.
% Every table and scenario file is read and checked before the network changes: a wrong
% file, column or row number leaves obj unchanged. An unknown column gives the warning
% GUILDA:import:UnknownColumn and is ignored (a memo column does not stop the import);
% the columns of dynamics.csv and of the controller tables depend on the class and are not
% checked. A controller key that is not in GUILDA.keymap (GUILDA:import:UnknownControllerKey),
% a Component that is not a FullTag of the component tables (GUILDA:import:UnknownComponent)
% and rows that do not fit the slots of a component (GUILDA:import:ControllerSlots: two AVR
% or "local" controllers, two PSSs, two governors, or a PSS without an AVR) also stop the
% import before the network changes. The graph
% columns of earlier versions (Xaxis, Yaxis, Marker, MidXaxis, MidYaxis) stop the import
% with GUILDA:import:OldGraphColumns; tools.layout_convert_columns converts such a folder. A later
% failure, such as an unknown model key, a disturbance whose tag is not in the network or
% a failing power flow, can leave obj partly built, so build it again after an error.
%
% <@Examples>
% ```matlab
% path = net.export(fullfile(tempdir, "MyNet"));
% net2 = PowerNetwork.import(path);
% net2.tab_parameter.base      % Hz and baseMVA of net
% ```
%
% ```matlab
% % in the constructor of a network class next to its CSV folders
% PowerNetwork.import(fileparts(mfilename("fullpath")), Network=obj);
% ```
%
% See also PowerNetwork.export, PowerNetwork.import_matpower
%
% <@Group> Data IO

    arguments (Input)
        path               (1,1) string          % Model folder (e.g. the folder written by net.export).
        opt.Initialize     (1,1) logical = true  % Run net.initialize() after building the network.
        opt.Network                      = []    % Existing network to add the buses, branches and components to (it is returned). Its Hz and baseMVA are overwritten by network/parameter.csv when the file gives them. Default: a new PowerNetwork tagged with the folder name (without a leading @).
    end
    arguments (Output)
        net  % The built network.
    end
    if ~isfolder(path)
        error(msg("GUILDA:import:NotFound", path));
    end
    if isempty(opt.Network)
        [~, s_name] = fileparts(strip(path, "right", filesep));
        s_name = strip(s_name, "left", "@");
        if ~isvarname(s_name); s_name = "PowerNetwork"; end
        net = PowerNetwork(s_name);
    else
        if ~isa(opt.Network, "PowerNetwork") || ~isscalar(opt.Network)
            error(msg("GUILDA:import:InvalidNetwork", class(opt.Network)));
        end
        net = opt.Network;
    end

% Read and check every table before the network changes
    s_NetPath   = fullfile(path, "network", "parameter.csv");
    sr_NetOpt   = strings(1,0);
    if isfile(s_NetPath)
        tab_net    = readtable(s_NetPath, "TextType", "string");
        sr_NetOpt  = check_cols(tab_net, strings(1,0), ["Hz", "baseMVA"], "network/parameter.csv");
    end

    % Bus
    sr_BusReq   = ["V", "Varg"];
    sr_BusOpt   = ["Gshunt", "Bshunt", "Vmin", "Vmax", "baseKV", "Tag", "X", "Y", "Shape", "Length", "MarkerSize", "Color"];
    % (a "baseMVA" column is accepted and ignored: the system base is net.tab_parameter.base.baseMVA;
    % the removed initial values "V0", "Varg0" are ignored with an INFO message)
    tab_bus    = read_csv(path, "bus/parameter.csv");
    sr_BusOpt  = check_cols(tab_bus, sr_BusReq, sr_BusOpt, "bus/parameter.csv", ["FullTag", "Slack", "baseMVA", "V0", "Varg0"]);
    sr_removed = intersect(["V0", "Varg0"], string(tab_bus.Properties.VariableNames), "stable");
    if ~isempty(sr_removed)
        show_msg("info", "GUILDA:import:RemovedColumn", "bus/parameter.csv", strjoin(sr_removed, ", "));
    end
    sv_BusTag  = read_full_tag(tab_bus);
    n_Bus      = size(tab_bus,1);

    % Branch
    sr_BraReq    = ["Type", "From", "To"];
    sr_BraOpt    = ["R", "X", "C", "Tap", "Phase", "Circuit", "Smax", "Imax", "Pmax", "Qmax", "Vargmax", ...
                    "Path", "FromOffset", "ToOffset", "Style"];
    tab_bra = read_csv(path, "branch/parameter.csv");
    % export writes "tap"/"phase"/"circuit" (the Branch parameter names); "Tap"/"Phase"/"Circuit" (the add_branch names) are also accepted.
    % Without the circuit column, add_branch gives 2 circuits.
    tab_bra = rename_cols(tab_bra, ["tap","phase","circuit"], ["Tap","Phase","Circuit"], "branch/parameter.csv");
    sr_BraOpt = check_cols(tab_bra, sr_BraReq, sr_BraOpt, "branch/parameter.csv", "FullTag");
    check_bus_rows(tab_bra, ["From", "To"], n_Bus, "branch/parameter.csv");
    sv_BraTag = read_full_tag(tab_bra);

    % Component
    sr_CompOPF    = [ "OPFinit_P0", "OPFinit_Q0", ...
                      "OPFcost_HP", "OPFcost_HQ", ...
                      "OPFcost_fP", "OPFcost_fQ", "OPFcost_c", ...
                      "OPFcost_startup", "OPFcost_shutdown"];
    c_Comp = read_components(path, n_Bus, sr_CompOPF);

    % Controllers (Component refers to the FullTag of the component tables when every row has one)
    sv_CompTag = strings(0,1);
    for i_dir = 1:numel(c_Comp)
        sv_CompTag = [sv_CompTag; c_Comp{i_dir}.sv_tag]; %#ok<AGROW>
    end
    l_checkComp = all(sv_CompTag ~= "");    % else a wrong tag stops when the controller is added
    l_hasLocal = isfolder(fullfile(path, "local_controller"));
    c_Local    = read_controllers(path, "local_controller", "LocalController", sv_CompTag, l_checkComp);
    c_Global   = read_controllers(path, "global_controller", "GlobalController", sv_CompTag, l_checkComp);
    % slots of each component: one AVR or "local" controller, one PSS under an AVR, one governor
    sv_ConComp = strings(0,1);
    sv_ConRole = strings(0,1);
    for i_key = 1:numel(c_Local)
        sv_ConComp = [sv_ConComp; c_Local{i_key}.sv_comp]; %#ok<AGROW>
        sv_ConRole = [sv_ConRole; repmat(c_Local{i_key}.s_role, numel(c_Local{i_key}.sv_comp), 1)]; %#ok<AGROW>
    end
    for s_comp = unique(sv_ConComp).'
        sv_role = sv_ConRole(sv_ConComp == s_comp);
        if sum(ismember(sv_role, ["avr", "local"])) > 1 || sum(sv_role == "pss") > 1 || sum(sv_role == "governor") > 1 ...
                || (any(sv_role == "pss") && ~any(sv_role == "avr"))
            error(msg("GUILDA:import:ControllerSlots", s_comp, strjoin(sv_role, ", ")));
        end
    end

    % Scenarios
    sa_scenario = read_scenarios(path);

% Network (Hz, baseMVA)
    tp = net.tab_parameter;
    for s_name = sr_NetOpt
        val = tab_net.(s_name)(1);
        if ~isnan(val)
            tp.base.(s_name) = val;
        end
    end
    net.tab_parameter = tp;

% Add buses
    n_BusBefore = numel(net.a_Bus);                  % buses of an existing network (Network=obj)
    a_Bus = cell(n_Bus,1);
    % the rows are converted once: indexing a table row by row is slow
    sa_BusOpt = repmat(struct(), n_Bus, 1);
    if ~isempty(sr_BusOpt)
        sa_BusOpt = table2struct(tab_bus(:, sr_BusOpt));
    end
    for i_bus = 1:n_Bus
        % FullTag replaces the prefix, which is empty for an all-digit tag
        sct_opt = sa_BusOpt(i_bus);
        if sv_BusTag(i_bus) ~= "" && isfield(sct_opt, "Tag")
            sct_opt = rmfield(sct_opt, "Tag");
        end
        c_opt   = namedargs2cell(sct_opt);
        a_Bus{i_bus} = net.add_bus("V", tab_bus.V(i_bus), "Varg", tab_bus.Varg(i_bus), "FullTag", sv_BusTag(i_bus), c_opt{:});
    end


% Add branches (From/To are row numbers of bus/parameter.csv)
    % the rows are converted once: indexing a table row by row is slow
    n_Branch  = size(tab_bra,1);
    sa_BraOpt = repmat(struct(), n_Branch, 1);
    if ~isempty(sr_BraOpt)
        sa_BraOpt = table2struct(tab_bra(:, sr_BraOpt));
    end
    for i_bra = 1:n_Branch
        % the rows were checked (check_bus_rows), so the buses are given by their index in
        % net.a_Bus, which add_branch does not have to look up by tag
        ir_fromto = n_BusBefore + [tab_bra.From(i_bra), tab_bra.To(i_bra)];
        c_opt     = namedargs2cell(sa_BraOpt(i_bra));
        set_full_tag(net.add_branch(tab_bra.Type(i_bra), ir_fromto, c_opt{:}), sv_BraTag(i_bra));
    end

% Add components
    c_CompNew = cell(0,1);
    for i_dir = 1:numel(c_Comp)
        sct_comp     = c_Comp{i_dir};
        s_CompKey    = sct_comp.key;
        tab_CompOpt  = sct_comp.tab_main;
        sr_CompOpt_  = sct_comp.sr_opt;
        sv_CompTag   = sct_comp.sv_tag;
        tab_CompDyn  = sct_comp.tab_dyn;
        tab_CompOpf  = sct_comp.tab_opf;
        l_hasDyn     = ~isempty(tab_CompDyn);
        l_hasOPF     = ~isempty(tab_CompOpf);

        % the columns are read once: indexing a table row by row is slow
        c_CompCol = cell(1, numel(sr_CompOpt_));
        for i_opt = 1:numel(sr_CompOpt_)
            c_CompCol{i_opt} = tab_CompOpt.(sr_CompOpt_(i_opt));
        end
        c_OpfCol = cell(1, numel(sr_CompOPF));
        if l_hasOPF
            for i_opt = 1:numel(sr_CompOPF)
                c_OpfCol{i_opt} = tab_CompOpf{:, sr_CompOPF(i_opt)};
            end
        end

        for i_comp = 1:size(tab_CompOpt,1)
            i_bus = tab_CompOpt.Bus(i_comp);
            r_P   = tab_CompOpt.P(i_comp);
            r_Q   = tab_CompOpt.Q(i_comp);
            sct_opt = struct();

            for i_opt = 1:length(sr_CompOpt_)
                sct_opt.(sr_CompOpt_(i_opt)) = c_CompCol{i_opt}(i_comp,:);
            end

            % import OPF parameter if exists OpfID (the first row of the ID)
            if l_hasOPF
                i_row = find(tab_CompOpf.OpfID == tab_CompOpt.OpfID(i_comp), 1);
                for i_opt = 1:length(sr_CompOPF)
                    sct_opt.(sr_CompOPF(i_opt)) = c_OpfCol{i_opt}(i_row,:);
                end
                sct_opt = rmfield(sct_opt, "OpfID");
            end

            % import Dynamic parameter table if exists ParameterID
            if l_hasDyn
                s_ID = tab_CompOpt.ParameterID(i_comp);
                tab_CompDyni = tab_CompDyn(tab_CompDyn.ParameterID==s_ID, :);
                sct_opt.parameter = tab_CompDyni;
                sct_opt = rmfield(sct_opt, "ParameterID");
            end

            c_opt = namedargs2cell(sct_opt);
            comp  = a_Bus{i_bus}.add_component(s_CompKey, "P", r_P, "Q", r_Q, c_opt{:});
            set_full_tag(comp, sv_CompTag(i_comp));
            c_CompNew{end+1,1} = comp; %#ok<AGROW>
        end
    end

% Local controllers (local_controller/ is the full set: the controllers from creation go first)
    if l_hasLocal
        sv_NewTag = strings(numel(c_CompNew), 1);
        for i_comp = 1:numel(c_CompNew)
            comp = c_CompNew{i_comp};
            sv_NewTag(i_comp) = comp.s_tag;
            for con = reshape(comp.a_LocalController, 1, [])
                comp.remove_local_controller(con{1}.s_tag, RemoveNested=true);
            end
        end
        % by role, so that the AVR of a component is there before its PSS
        for sv_role = {["avr", "local"], "pss", "governor"}
            for i_key = 1:numel(c_Local)
                sct_con = c_Local{i_key};
                if ~ismember(sct_con.s_role, sv_role{1})
                    continue
                end
                for i_con = 1:numel(sct_con.sv_comp)
                    i_comp = find(sv_NewTag == sct_con.sv_comp(i_con), 1);
                    if isempty(i_comp)
                        error(msg("GUILDA:import:UnknownComponent", sct_con.s_file, string(i_con), sct_con.sv_comp(i_con)));
                    end
                    sct_para = sct_con.sa_para(i_con);
                    sct_opt  = sct_con.c_option{i_con};
                    for s_name = string(fieldnames(sct_opt)).'
                        sct_para.(s_name) = sct_opt.(s_name);
                    end
                    con = c_CompNew{i_comp}.add_local_controller(sct_con.s_key, parameter=sct_para);
                    set_full_tag(con, sct_con.sv_tag(i_con));
                end
            end
        end
    end

% Slack bus (needs the components)
    if ismember("Slack", string(tab_bus.Properties.VariableNames))
        lv_slack = tab_bus.Slack;
        if isstring(lv_slack)
            lv_slack = ismember(lower(strip(lv_slack)), ["1", "true"]);
        end
        i_slack = find(lv_slack == 1, 1);
        if ~isempty(i_slack)
            bus = a_Bus{i_slack};
            evalc("bus.l_isSlack = true;");     % without the SetSlack message
        end
    end

% Global controllers (after the local controllers, which decide where their outputs go)
    for i_key = 1:numel(c_Global)
        sct_con = c_Global{i_key};
        for s_tag = unique(sct_con.sv_tag, "stable").'
            lv_row = sct_con.sv_tag == s_tag;
            con = net.add_global_controller(sct_con.s_key, sct_con.sv_comp(lv_row), parameter=sct_con.c_option{find(lv_row, 1)});
            set_full_tag(con, s_tag);
            % the columns get the classes of the default table (e.g. a logical read as 1/0)
            tab_dyn = con.tab_parameter.dynamics;
            for s_col = string(tab_dyn.Properties.VariableNames)
                if ismember(s_col, string(sct_con.tab.Properties.VariableNames))
                    tab_dyn.(s_col) = feval(class(tab_dyn.(s_col)), sct_con.tab.(s_col)(lv_row));
                end
            end
            con.tab_parameter.dynamics = tab_dyn;
        end
    end

% Add scenarios (their disturbances are checked against the components and controllers)
    for i_sc = 1:numel(sa_scenario)
        sc = net.add_scenario(sa_scenario(i_sc).s_tag);
        sc.add_from_json_struct(sa_scenario(i_sc).sct);
    end

    if opt.Initialize
        net.initialize;
    end
end


function c_Comp = read_components(path, n_Bus, sr_CompOPF)
    % Read and check the tables of every folder component/<key>; nothing is added yet
    sr_CompReq   = [ "Bus", "P", "Q"];
    sr_CompOpt   = [ "baseMVA", "Pmin", "Pmax", "Qmin", "Qmax", "ParameterID", "OpfID", ...
                     "DX", "DY", "Shape", "Path", "Offset", "MarkerSize", "Color"];
    s_CompPath   = fullfile(path, "component");
    c_Comp       = {};
    if ~isfolder(s_CompPath)
        show_msg("warning", "GUILDA:import:NoComponentFolder", s_CompPath);
        return
    end
    sct_CompDir = dir(s_CompPath);
    for i_dir = 1:length(sct_CompDir)
        if ~sct_CompDir(i_dir).isdir || startsWith(sct_CompDir(i_dir).name, ".")
            continue
        end
        s_key    = string(sct_CompDir(i_dir).name);
        s_rel    = "component/" + s_key + "/";
        s_main   = s_rel + "main.csv";

        tab_main = read_csv(path, s_main);
        sr_opt   = check_cols(tab_main, sr_CompReq, sr_CompOpt, s_main, "FullTag");
        check_bus_rows(tab_main, "Bus", n_Bus, s_main);

        tab_dyn = [];
        if ismember("ParameterID", sr_opt)
            tab_dyn = read_csv(path, s_rel + "dynamics.csv");
            % The other columns depend on the component class
            assert(ismember("ParameterID", string(tab_dyn.Properties.VariableNames)), ...
                "GUILDA:import:MissingColumns", ...
                "Missing required columns in %s: ParameterID", s_rel + "dynamics.csv");
            check_ids(tab_main, tab_dyn, "ParameterID", s_main, s_rel + "dynamics.csv");
        end

        tab_opf = [];
        if ismember("OpfID", sr_opt)
            tab_opf = read_csv(path, s_rel + "opf.csv");
            check_cols(tab_opf, ["OpfID", sr_CompOPF], strings(1,0), s_rel + "opf.csv");
            check_ids(tab_main, tab_opf, "OpfID", s_main, s_rel + "opf.csv");
        end

        c_Comp{end+1} = struct("key", s_key, "tab_main", tab_main, "sr_opt", sr_opt, ...
                               "sv_tag", read_full_tag(tab_main), ...
                               "tab_dyn", tab_dyn, "tab_opf", tab_opf); %#ok<AGROW>
    end
end


function c_Con = read_controllers(path, s_folder, s_category, sv_CompTag, l_checkComp)
    % Read and check the tables of every folder <s_folder>/<key>; nothing is added yet.
    % sv_CompTag: the full tags of the components of the folder, checked when l_checkComp
    c_Con  = {};
    s_path = fullfile(path, s_folder);
    if ~isfolder(s_path)
        return
    end
    dic      = GUILDA.keymap(s_category);
    sct_dir  = dir(s_path);
    for i_dir = 1:numel(sct_dir)
        if ~sct_dir(i_dir).isdir || startsWith(sct_dir(i_dir).name, ".")
            continue
        end
        s_key = string(sct_dir(i_dir).name);
        s_rel = s_folder + "/" + s_key + "/parameter.csv";
        if ~isKey(dic, s_key)
            error(msg("GUILDA:import:UnknownControllerKey", s_folder + "/" + s_key, s_key, s_category, join(keys(dic)', ", ")));
        end
        tab    = read_csv(path, s_rel);
        sr_col = string(tab.Properties.VariableNames);
        sr_req = "Component";
        if s_category == "GlobalController"
            sr_req = ["FullTag", "Component"];
        end
        check_cols(tab, sr_req, strings(1,0), s_rel, sr_col);    % the other columns depend on the class
        sv_comp = strip(string(tab.Component));
        if l_checkComp
            i_row = find(~ismember(sv_comp, sv_CompTag), 1);
            if ~isempty(i_row)
                error(msg("GUILDA:import:UnknownComponent", s_rel, string(i_row), sv_comp(i_row)));
            end
        end
        mc     = meta.class.fromName(dic(s_key));
        s_role = string(mc.PropertyList(string({mc.PropertyList.Name}) == "s_role").DefaultValue);
        % the parameters of each row, converted once: a table row per controller is slow
        sa_para = table2struct(tab(:, ~ismember(sr_col, ["Component", "FullTag"])));
        sv_tag  = read_full_tag(tab);
        % option.json: the constructor arguments outside the table, by FullTag (get_option)
        c_option = repmat({struct()}, height(tab), 1);
        s_json   = fullfile(s_path, s_key, "option.json");
        if isfile(s_json)
            s_relJson = s_folder + "/" + s_key + "/option.json";
            try
                sct_json = jsondecode(fileread(s_json));
            catch ME
                error(msg("GUILDA:import:OptionJson", s_relJson, ME.message));
            end
            if ~isstruct(sct_json) || ~isscalar(sct_json)
                error(msg("GUILDA:import:OptionJson", s_relJson, "the file is not one JSON object"));
            end
            for s_tag = string(fieldnames(sct_json)).'
                i_row = find(sv_tag == s_tag, 1);
                if isempty(i_row) || ~isstruct(sct_json.(s_tag)) || ~isscalar(sct_json.(s_tag))
                    error(msg("GUILDA:import:OptionJson", s_relJson, s_tag + " is not an object of a FullTag of parameter.csv"));
                end
                sct = sct_json.(s_tag);
                for s_name = string(fieldnames(sct)).'
                    val = sct.(s_name);
                    if isstruct(val) && isequal(sort(string(fieldnames(val))), ["im"; "re"])
                        sct.(s_name) = complex(val.re, val.im);     % written as {"re": ..., "im": ...}
                    elseif iscellstr(val) || ischar(val)
                        sct.(s_name) = string(val);
                    end
                end
                c_option{i_row} = sct;
            end
        end
        c_Con{end+1} = struct("s_key", s_key, "s_role", s_role, "s_file", s_rel, "tab", tab, ...
                              "sv_comp", sv_comp, "sv_tag", sv_tag, "sa_para", sa_para, "c_option", {c_option}); %#ok<AGROW>
    end
end


function tab = read_csv(path, relpath)
    % The graph columns of earlier versions stop the import with the hint to convert them.
    % The text columns of the graph parameters are read as text ("" for an empty cell, also
    % in an all-empty column, which readtable would read as NaN); "," is the only delimiter
    % (a Path "x y; x y" has spaces and semicolons).
    s_file = fullfile(path, relpath);
    if ~isfile(s_file)
        error(msg("GUILDA:import:MissingFile", s_file, relpath));
    end
    opts   = detectImportOptions(s_file, "Delimiter", ",", "TextType", "string");
    sv_old = intersect(["Xaxis", "Yaxis", "Marker", "MidXaxis", "MidYaxis"], string(opts.VariableNames), "stable");
    if ~isempty(sv_old)
        error(msg("GUILDA:import:OldGraphColumns", relpath, strjoin(sv_old, ", "), path));
    end
    sv_text = intersect(["Shape", "Path", "Style", "Color"], string(opts.VariableNames), "stable");
    if ~isempty(sv_text)
        opts = setvartype(opts, sv_text, "string");
    end
    if ismember("FullTag", string(opts.VariableNames))
        opts = setvartype(opts, "FullTag", "string");   % read_full_tag
    end
    tab  = readtable(s_file, opts);
    for s_col = sv_text
        sv = fillmissing(tab.(s_col), "constant", "");
        sv(sv == "NaN") = "";                        % an all-empty column written as NaN (writetable of a double)
        tab.(s_col) = sv;
    end
end


function check_bus_rows(tab, cols, n_Bus, relpath)
    % From, To and Bus are row numbers of bus/parameter.csv
    for s_col = cols
        val   = tab.(s_col);
        r_val = double(val);
        i_row = find(isnan(r_val) | r_val < 1 | r_val > n_Bus | r_val ~= fix(r_val), 1);
        if ~isempty(i_row)
            error(msg("GUILDA:import:BusRow", relpath, string(i_row), s_col, value_text(val(i_row)), string(n_Bus), string(n_Bus)));
        end
    end
end


function check_ids(tab_main, tab_ref, s_col, relpath, relref)
    i_row = find(~ismember(string(tab_main.(s_col)), string(tab_ref.(s_col))), 1);
    if ~isempty(i_row)
        error(msg("GUILDA:import:UnknownID", relpath, string(i_row), s_col, value_text(tab_main.(s_col)(i_row)), relref));
    end
end


function str = value_text(val)
    % readtable gives NaN or a missing string for an empty or non-numeric cell
    str = string(val);
    if ismissing(str)
        str = "NaN";
    end
end


function sv_tag = read_full_tag(tab)
    % Column FullTag as text ("" for a missing column or value); read_csv reads it as text,
    % so an all-digit tag stays as written
    if ~ismember("FullTag", string(tab.Properties.VariableNames))
        sv_tag  = strings(height(tab), 1);
        return
    end
    sv_tag = strip(fillmissing(tab.FullTag, "constant", ""));
end


function set_full_tag(obj, s_tag)
    % Branches and components have no tag argument, so this logs a rename when s_tag logs them.
    % Set right after the row is added: the automatic number of the next row cannot take this tag
    if s_tag ~= ""
        obj.s_tag = s_tag;
    end
end


function tab = rename_cols(tab, old_cols, new_cols, relpath)
    names = string(tab.Properties.VariableNames);
    for i = 1:numel(old_cols)
        if ~ismember(old_cols(i), names)
            continue
        end
        assert(~ismember(new_cols(i), names), ...
            "GUILDA:import:DuplicateColumns", ...
            "Both %s and %s are given in %s", old_cols(i), new_cols(i), relpath);
        tab = renamevars(tab, old_cols(i), new_cols(i));
    end
end


function optional_cols = check_cols(tab, required_cols, optional_cols, relpath, other_cols)
    % other_cols: known columns that the caller reads by itself or ignores
    arguments (Input)
        tab
        required_cols
        optional_cols
        relpath
        other_cols = strings(1,0)
    end
    names   = string(tab.Properties.VariableNames);
    missing = required_cols(~ismember(required_cols, names));
    assert(isempty(missing), ...
        "GUILDA:import:MissingColumns", ...
        "Missing required columns in %s: %s", relpath, strjoin(missing, ", "));
    known = [required_cols, optional_cols, other_cols];
    lv_unknown = ~ismember(names, known);
    if any(lv_unknown)
        % The column names as written: readtable changes the ones that are not MATLAB names
        sr_written = names;
        if ~isempty(tab.Properties.VariableDescriptions)
            sr_written = string(tab.Properties.VariableDescriptions);
        end
        show_msg("warning", "GUILDA:import:UnknownColumn", relpath, strjoin(sr_written(lv_unknown), ", "), strjoin(known, ", "));
    end
    if ~isempty(optional_cols)
        optional_cols = optional_cols(ismember(optional_cols, names));
    end
end
