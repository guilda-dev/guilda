function net = import_csv(path, opt)
% <@Desc>
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
% With Network=obj the buses are added to the existing network obj instead of a new
% one; this is how the network classes such as network.IEEE14bus load their folder in
% their constructor.
% <@Role> Constructor
% <@Summary> Build a network from a CSV model folder.
% <@Signatures>
% [
%   "net = PowerNetwork.import_csv(path)",
%   "net = PowerNetwork.import_csv(path, Name, Value)"
% ]
% <@Parameters>
% [
%   {"Name": "path", "Type": "string scalar", "Description": "Model folder (e.g. the folder written by net.export_csv).", "Required": true, "Default": "-"},
%   {"Name": "Initialize", "Type": "logical scalar", "Description": "Run net.initialize() after building the network.", "Required": false, "Default": "true"},
%   {"Name": "Network", "Type": "PowerNetwork", "Description": "Existing network to add the buses, branches and components to (it is returned). Its Hz and baseMVA are overwritten by network/parameter.csv when the file gives them.", "Required": false, "Default": "a new PowerNetwork tagged with the folder name (without a leading @)"}
% ]
% <@Returns>
% [
%   {"Name": "net", "Type": "PowerNetwork", "Description": "The built network."}
% ]
% <@Examples>
% [
%   "```matlab\npath = net.export_csv(fullfile(tempdir, \"MyNet\"));\nnet2 = PowerNetwork.import_csv(path);\nnet2.tab_parameter.base      % Hz and baseMVA of net\n```",
%   "```matlab\n% in the constructor of a network class next to its CSV folders\nPowerNetwork.import_csv(fileparts(mfilename(\"fullpath\")), Network=obj);\n```"
% ]
% <@Since> 4.0

    arguments
        path               (1,1) string
        opt.Initialize     (1,1) logical = true
        opt.Network                      = []
    end
    if ~isfolder(path)
        error("GUILDA:import_csv:NotFound", ...
              "Model folder not found: %s. Give the folder that holds bus/, branch/ and component/ (e.g. the path returned by net.export_csv).", path);
    end
    if isempty(opt.Network)
        [~, str_name] = fileparts(strip(path, "right", filesep));
        str_name = strip(str_name, "left", "@");
        if ~isvarname(str_name); str_name = "PowerNetwork"; end
        net = PowerNetwork(str_name);
    else
        if ~isa(opt.Network, "PowerNetwork") || ~isscalar(opt.Network)
            error("GUILDA:import_csv:InvalidNetwork", "Network must be a PowerNetwork object (got %s).", class(opt.Network));
        end
        net = opt.Network;
    end

% Network (Hz, baseMVA)
    str_NetPath = fullfile(path, "network", "parameter.csv");
    if isfile(str_NetPath)
        tab_net    = readtable(str_NetPath, "TextType", "string");
        str_NetOpt = check_cols(tab_net, strings(1,0), ["Hz", "baseMVA"], "network/parameter.csv");
        for str_name = str_NetOpt
            val = tab_net.(str_name)(1);
            if ~isnan(val)
                net.para_base.(str_name) = val;
            end
        end
    end

% Bus
    % Variable Names
    str_BusReq  = ["V", "Varg"];
    % (a "baseMVA" column is accepted and ignored: the system base is net.tab_parameter.base.baseMVA)
    str_BusOpt  = ["V0", "Varg0", "Gshunt", "Bshunt", "Vmin", "Vmax", "baseKV", "Tag", "Xaxis","Yaxis","Marker"];

    % validate table
    tab_bus    = readtable(fullfile(path, "bus", "parameter.csv"), "TextType", "string");
    str_BusOpt = check_cols(tab_bus, str_BusReq, str_BusOpt, "bus/parameter.csv");

    % Add bus
    n_Bus = size(tab_bus,1);
    a_Bus = cell(n_Bus,1);
    for i_bus = 1:n_Bus
        r_V    = tab_bus.V(i_bus);
        r_Varg = tab_bus.Varg(i_bus);

        tab_opt = tab_bus(i_bus,str_BusOpt);
        sct_opt = table2struct(tab_opt);
        c_opt   = namedargs2cell(sct_opt);
        a_Bus{i_bus} = net.add_bus("V", r_V, "Varg", r_Varg, c_opt{:});
    end


% Branch
    % Variable Names
    str_BraReq   = ["Type", "From", "To"];
    str_BraOpt   = ["R", "X", "C", "Tap", "Phase", "Smax", "Imax", "Pmax", "Qmax", "Vargmax", ...
                    "MidXaxis","MidYaxis","Marker","BusFromPoint","BusToPoint"];

    % Validate table
    tab_bra = readtable(fullfile(path, "branch", "parameter.csv"), "TextType", "string");
    % export writes "tap"/"phase" (the Branch parameter names); "Tap"/"Phase" (the add_branch names) are also accepted
    tab_bra = rename_cols(tab_bra, ["tap","phase"], ["Tap","Phase"], "branch/parameter.csv");
    str_BraOpt = check_cols(tab_bra, str_BraReq, str_BraOpt, "branch/parameter.csv");

    % Add branches (From/To are row numbers of bus/parameter.csv)
    for i_bra = 1:size(tab_bra,1)
        tab_brai  = tab_bra(i_bra,:);
        str_Type  = tab_brai.Type;
        str_fromto = [string(a_Bus{tab_brai.From}), string(a_Bus{tab_brai.To})];

        tab_opt = tab_brai(1,str_BraOpt);
        sct_opt = table2struct(tab_opt);
        c_opt   = namedargs2cell(sct_opt);
        net.add_branch(str_Type, str_fromto, c_opt{:});
    end

% Component
    %Variable Names
    str_CompReq   = [ "Bus", "P", "Q"];
    str_CompOpt   = [ "baseMVA", "Pmin", "Pmax", "Qmin", "Qmax", "ParameterID", "OpfID", ...
                      "Xaxis","Yaxis","Marker","BusPoint","MidXaxis","MidYaxis"];
    str_CompOPF   = [ "OPFinit_P0", "OPFinit_Q0", ...
                      "OPFcost_HP", "OPFcost_HQ", ...
                      "OPFcost_fP", "OPFcost_fQ", ...
                      "OPFcost_startup", "OPFcost_shutdown"];

    str_CompPath = fullfile(path, "component");
    str_CompDir  = dir(str_CompPath);

    % Add components
    for i_dir = 1:length(str_CompDir)
        if ~str_CompDir(i_dir).isdir || startsWith(str_CompDir(i_dir).name, ".")
            continue
        end
        str_CompKey = str_CompDir(i_dir).name;
        str_KeyPath = fullfile(str_CompPath,str_CompKey);


        tab_CompOpt  = readtable(fullfile(str_KeyPath, "main.csv"  ), "TextType", "string");
        str_CompDynPath  = fullfile(str_KeyPath, "dynamics.csv");
        str_CompOpfPath  = fullfile(str_KeyPath, "opf.csv");

        l_hasDyn     = false;
        if ismember("ParameterID",tab_CompOpt.Properties.VariableNames)
            assert(isfile(str_CompDynPath), "Not found Parameter table: %s", str_CompDynPath);
            l_hasDyn     = true;
            tab_CompDyn  = readtable(str_CompDynPath, "TextType", "string");
        end

        l_hasOPF     = false;
        if ismember("OpfID",tab_CompOpt.Properties.VariableNames)
            assert(isfile(str_CompOpfPath), "Not found OPF table: %s", str_CompOpfPath);
            l_hasOPF     = true;
            tab_CompOpf  = readtable(str_CompOpfPath, "TextType", "string");
        end

        str_CompOpt_ = check_cols(tab_CompOpt, str_CompReq, str_CompOpt, "component/"+str_CompKey+"/main.csv");

        for i_comp = 1:size(tab_CompOpt,1)
            tab_CompOpti = tab_CompOpt(i_comp, :);

            i_bus = tab_CompOpti.Bus;
            r_P   = tab_CompOpti.P;
            r_Q   = tab_CompOpti.Q;
            sct_opt = struct();

            for i_opt = 1:length(str_CompOpt_)
                str_opti = str_CompOpt_(i_opt);
                val = tab_CompOpti.(str_opti);
                sct_opt.(str_opti) = val;
            end

            % import OPF parameter if exists OpfID
            if l_hasOPF
                str_ID = tab_CompOpti.OpfID;
                tab_CompOpfi = tab_CompOpf(tab_CompOpf.OpfID==str_ID, :);
                assert(~isempty(tab_CompOpfi), "Not found OPF ID %s in %s", str_ID, str_CompOpfPath);
                for i_opt = 1:length(str_CompOPF)
                    val = tab_CompOpfi{1, str_CompOPF(i_opt)};
                    sct_opt.(str_CompOPF(i_opt)) = val;
                end
                sct_opt = rmfield(sct_opt, "OpfID");
            end

            % import Dynamic parameter table if exists ParameterID
            if l_hasDyn
                str_ID = tab_CompOpti.ParameterID;
                tab_CompDyni = tab_CompDyn(tab_CompDyn.ParameterID==str_ID, :);
                assert(~isempty(tab_CompDyni), "Not found parameter ID %s in %s", str_ID, str_CompDynPath);
                sct_opt.parameter = tab_CompDyni;
                sct_opt = rmfield(sct_opt, "ParameterID");
            end

            c_opt = namedargs2cell(sct_opt);
            a_Bus{i_bus}.add_component(str_CompKey, "P", r_P, "Q", r_Q, c_opt{:});
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


function tab = rename_cols(tab, old_cols, new_cols, relpath)
    names = string(tab.Properties.VariableNames);
    for i = 1:numel(old_cols)
        if ~ismember(old_cols(i), names)
            continue
        end
        assert(~ismember(new_cols(i), names), ...
            "network:import_csv:DuplicateColumns", ...
            "Both %s and %s are given in %s", old_cols(i), new_cols(i), relpath);
        tab = renamevars(tab, old_cols(i), new_cols(i));
    end
end


function optional_cols = check_cols(tab, required_cols, optional_cols, relpath)
    names   = string(tab.Properties.VariableNames);
    missing = required_cols(~ismember(required_cols, names));
    assert(isempty(missing), ...
        "network:import_csv:MissingColumns", ...
        "Missing required columns in %s: %s", relpath, strjoin(missing, ", "));
    if ~isempty(optional_cols)
        optional_cols = optional_cols(ismember(optional_cols, names));
    end
end
