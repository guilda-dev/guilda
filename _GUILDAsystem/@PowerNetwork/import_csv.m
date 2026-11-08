function net = import_csv(path, opt)
% Build a network from a CSV model folder.
%
% Builds a PowerNetwork from a CSV model folder (the layout written by net.export_csv):
%   <path>/network/parameter.csv        Hz, baseMVA of the network (optional)
%   <path>/bus/parameter.csv            one row per bus (V, Varg required)
%   <path>/branch/parameter.csv         one row per branch (Type, From, To required)
%   <path>/component/<key>/main.csv     one row per component of type <key> (Bus, P, Q required)
%   <path>/component/<key>/dynamics.csv parameters referenced by the column ParameterID
%   <path>/component/<key>/opf.csv      OPF settings referenced by the column OpfID
% Buses are numbered by their row; From, To and Bus refer to these numbers.
% A missing network/parameter.csv (folders written before v4) or a missing or NaN value
% keeps the defaults Hz = GUILDA.config("Model","Hz") and baseMVA = 100.
% The bus column Slack (optional) marks the slack bus; a bus column baseMVA (v3) is
% accepted and ignored: the system base is net.tab_parameter.base.baseMVA.
% The column FullTag (optional) of the bus, branch and component tables gives the full
% tag of a row, and the bus column Tag is then not used. A missing column or an empty value
% keeps the automatic tag (folders written before FullTag), with Tag as the bus prefix.
% With Network=obj the buses are added to the existing network obj instead of a new
% one; this is how the network classes such as network.IEEE14bus load their folder in
% their constructor.
% Every table is read and checked before the network changes: a wrong file, column or row
% number leaves obj unchanged. An unknown column gives the warning
% GUILDA:import_csv:UnknownColumn and is ignored (a memo column does not stop the import);
% the columns of dynamics.csv depend on the component class and are not checked. A later
% failure, such as an unknown model key or a failing power flow, can leave obj partly
% built, so build it again after an error.
%
% <@Examples>
% ```matlab
% path = net.export_csv(fullfile(tempdir, "MyNet"));
% net2 = PowerNetwork.import_csv(path);
% net2.tab_parameter.base      % Hz and baseMVA of net
% ```
%
% ```matlab
% % in the constructor of a network class next to its CSV folders
% PowerNetwork.import_csv(fileparts(mfilename("fullpath")), Network=obj);
% ```
%
% See also PowerNetwork.export_csv, PowerNetwork.import_matpower
%
% <@Group> Data IO

    arguments (Input)
        path               (1,1) string   % Model folder (e.g. the folder written by net.export_csv).
        opt.Initialize     (1,1) logical = true   % Run net.initialize() after building the network.
        opt.Network                      = []   % Existing network to add the buses, branches and components to (it is returned). Its Hz and baseMVA are overwritten by network/parameter.csv when the file gives them. Default: a new PowerNetwork tagged with the folder name (without a leading @).
    end
    arguments (Output)
        net   % The built network.
    end
    if ~isfolder(path)
        error(msg("GUILDA:import_csv:NotFound", path));
    end
    if isempty(opt.Network)
        [~, s_name] = fileparts(strip(path, "right", filesep));
        s_name = strip(s_name, "left", "@");
        if ~isvarname(s_name); s_name = "PowerNetwork"; end
        net = PowerNetwork(s_name);
    else
        if ~isa(opt.Network, "PowerNetwork") || ~isscalar(opt.Network)
            error(msg("GUILDA:import_csv:InvalidNetwork", class(opt.Network)));
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
    sr_BusOpt   = ["V0", "Varg0", "Gshunt", "Bshunt", "Vmin", "Vmax", "baseKV", "Tag", "Xaxis","Yaxis","Marker"];
    % (a "baseMVA" column is accepted and ignored: the system base is net.tab_parameter.base.baseMVA)
    tab_bus    = read_csv(path, "bus/parameter.csv");
    sr_BusOpt  = check_cols(tab_bus, sr_BusReq, sr_BusOpt, "bus/parameter.csv", ["FullTag", "Slack", "baseMVA"]);
    sv_BusTag  = read_full_tag(fullfile(path, "bus", "parameter.csv"));
    n_Bus      = size(tab_bus,1);

    % Branch
    sr_BraReq    = ["Type", "From", "To"];
    sr_BraOpt    = ["R", "X", "C", "Tap", "Phase", "Smax", "Imax", "Pmax", "Qmax", "Vargmax", ...
                    "MidXaxis","MidYaxis","Marker"];
    tab_bra = read_csv(path, "branch/parameter.csv");
    % export writes "tap"/"phase" (the Branch parameter names); "Tap"/"Phase" (the add_branch names) are also accepted
    tab_bra = rename_cols(tab_bra, ["tap","phase"], ["Tap","Phase"], "branch/parameter.csv");
    sr_BraOpt = check_cols(tab_bra, sr_BraReq, sr_BraOpt, "branch/parameter.csv", "FullTag");
    check_bus_rows(tab_bra, ["From", "To"], n_Bus, "branch/parameter.csv");
    sv_BraTag = read_full_tag(fullfile(path, "branch", "parameter.csv"));

    % Component
    sr_CompOPF    = [ "OPFinit_P0", "OPFinit_Q0", ...
                      "OPFcost_HP", "OPFcost_HQ", ...
                      "OPFcost_fP", "OPFcost_fQ", ...
                      "OPFcost_startup", "OPFcost_shutdown"];
    c_Comp = read_components(path, n_Bus, sr_CompOPF);

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
    a_Bus = cell(n_Bus,1);
    for i_bus = 1:n_Bus
        r_V    = tab_bus.V(i_bus);
        r_Varg = tab_bus.Varg(i_bus);

        % FullTag replaces the prefix, which is empty for an all-digit tag
        tab_opt = tab_bus(i_bus, sr_BusOpt(sr_BusOpt ~= "Tag" | sv_BusTag(i_bus) == ""));
        sct_opt = table2struct(tab_opt);
        c_opt   = namedargs2cell(sct_opt);
        a_Bus{i_bus} = net.add_bus("V", r_V, "Varg", r_Varg, "FullTag", sv_BusTag(i_bus), c_opt{:});
    end


% Add branches (From/To are row numbers of bus/parameter.csv)
    for i_bra = 1:size(tab_bra,1)
        tab_brai  = tab_bra(i_bra,:);
        s_Type    = tab_brai.Type;
        sr_fromto = [string(a_Bus{tab_brai.From}), string(a_Bus{tab_brai.To})];

        tab_opt = tab_brai(1,sr_BraOpt);
        sct_opt = table2struct(tab_opt);
        c_opt   = namedargs2cell(sct_opt);
        set_full_tag(net.add_branch(s_Type, sr_fromto, c_opt{:}), sv_BraTag(i_bra));
    end

% Add components
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

        for i_comp = 1:size(tab_CompOpt,1)
            tab_CompOpti = tab_CompOpt(i_comp, :);

            i_bus = tab_CompOpti.Bus;
            r_P   = tab_CompOpti.P;
            r_Q   = tab_CompOpti.Q;
            sct_opt = struct();

            for i_opt = 1:length(sr_CompOpt_)
                s_opti = sr_CompOpt_(i_opt);
                val = tab_CompOpti.(s_opti);
                sct_opt.(s_opti) = val;
            end

            % import OPF parameter if exists OpfID
            if l_hasOPF
                s_ID = tab_CompOpti.OpfID;
                tab_CompOpfi = tab_CompOpf(tab_CompOpf.OpfID==s_ID, :);
                for i_opt = 1:length(sr_CompOPF)
                    val = tab_CompOpfi{1, sr_CompOPF(i_opt)};
                    sct_opt.(sr_CompOPF(i_opt)) = val;
                end
                sct_opt = rmfield(sct_opt, "OpfID");
            end

            % import Dynamic parameter table if exists ParameterID
            if l_hasDyn
                s_ID = tab_CompOpti.ParameterID;
                tab_CompDyni = tab_CompDyn(tab_CompDyn.ParameterID==s_ID, :);
                sct_opt.parameter = tab_CompDyni;
                sct_opt = rmfield(sct_opt, "ParameterID");
            end

            c_opt = namedargs2cell(sct_opt);
            set_full_tag(a_Bus{i_bus}.add_component(s_CompKey, "P", r_P, "Q", r_Q, c_opt{:}), sv_CompTag(i_comp));
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

    if opt.Initialize
        net.initialize;
    end
end


function c_Comp = read_components(path, n_Bus, sr_CompOPF)
    % Read and check the tables of every folder component/<key>; nothing is added yet
    sr_CompReq   = [ "Bus", "P", "Q"];
    sr_CompOpt   = [ "baseMVA", "Pmin", "Pmax", "Qmin", "Qmax", "ParameterID", "OpfID", ...
                     "Xaxis","Yaxis","Marker","MidXaxis","MidYaxis"];
    s_CompPath   = fullfile(path, "component");
    c_Comp       = {};
    if ~isfolder(s_CompPath)
        show_msg("warning", "GUILDA:import_csv:NoComponentFolder", s_CompPath);
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
                "GUILDA:import_csv:MissingColumns", ...
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
                               "sv_tag", read_full_tag(fullfile(s_CompPath, s_key, "main.csv")), ...
                               "tab_dyn", tab_dyn, "tab_opf", tab_opf); %#ok<AGROW>
    end
end


function tab = read_csv(path, relpath)
    s_file = fullfile(path, relpath);
    if ~isfile(s_file)
        error(msg("GUILDA:import_csv:MissingFile", s_file, relpath));
    end
    tab = readtable(s_file, "TextType", "string");
end


function check_bus_rows(tab, cols, n_Bus, relpath)
    % From, To and Bus are row numbers of bus/parameter.csv
    for s_col = cols
        val   = tab.(s_col);
        r_val = double(val);
        i_row = find(isnan(r_val) | r_val < 1 | r_val > n_Bus | r_val ~= fix(r_val), 1);
        if ~isempty(i_row)
            error(msg("GUILDA:import_csv:BusRow", relpath, string(i_row), s_col, value_text(val(i_row)), string(n_Bus), string(n_Bus)));
        end
    end
end


function check_ids(tab_main, tab_ref, s_col, relpath, relref)
    i_row = find(~ismember(string(tab_main.(s_col)), string(tab_ref.(s_col))), 1);
    if ~isempty(i_row)
        error(msg("GUILDA:import_csv:UnknownID", relpath, string(i_row), s_col, value_text(tab_main.(s_col)(i_row)), relref));
    end
end


function str = value_text(val)
    % readtable gives NaN or a missing string for an empty or non-numeric cell
    str = string(val);
    if ismissing(str)
        str = "NaN";
    end
end


function sv_tag = read_full_tag(s_file)
    % Column FullTag as text ("" for a missing column or value): an all-digit tag stays as written
    opts = detectImportOptions(s_file);
    if ~ismember("FullTag", string(opts.VariableNames))
        n_row   = height(readtable(s_file, "TextType", "string"));
        sv_tag  = strings(n_row, 1);
        return
    end
    opts = setvartype(opts, "FullTag", "string");
    opts.SelectedVariableNames = "FullTag";
    sv_tag = strip(fillmissing(readtable(s_file, opts).FullTag, "constant", ""));
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
            "GUILDA:import_csv:DuplicateColumns", ...
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
        "GUILDA:import_csv:MissingColumns", ...
        "Missing required columns in %s: %s", relpath, strjoin(missing, ", "));
    known = [required_cols, optional_cols, other_cols];
    lv_unknown = ~ismember(names, known);
    if any(lv_unknown)
        % The column names as written: readtable changes the ones that are not MATLAB names
        sr_written = names;
        if ~isempty(tab.Properties.VariableDescriptions)
            sr_written = string(tab.Properties.VariableDescriptions);
        end
        show_msg("warning", "GUILDA:import_csv:UnknownColumn", relpath, strjoin(sr_written(lv_unknown), ", "), strjoin(known, ", "));
    end
    if ~isempty(optional_cols)
        optional_cols = optional_cols(ismember(optional_cols, names));
    end
end
