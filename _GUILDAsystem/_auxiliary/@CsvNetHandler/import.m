function net = import(path, net, options)
%IMPORT_CSV Build a PowerNetwork from CSV files.
% Expected directory structure:
%   @ModelName/
%     bus/parameter.csv
%     branch/parameter.csv
%     component/<key>/option.csv
%     component/<key>/dynamics.csv    (optional)

    arguments
        path           (1,1) string
        net            (1,1) PowerNetwork = PowerNetwork()
        options.Initialize (1,1) logical = true
    end
    
% Bus 
    % Variable Names
    str_BusReq  = ["V", "Varg"];
    str_BusOpt  = ["Gshunt", "Bshunt", "Vmin", "Vmax", "baseKV", "baseMVA", "Tag", "Xaxis","Yaxis","Marker"];
    
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
        opt = namedargs2cell(sct_opt);
        a_Bus{i_bus} = net.add_bus("V", r_V, "Varg", r_Varg, opt{:});
    end


% Branch
    % Variable Names
    str_BraReq   = ["Type", "From", "To"];
    str_BraOpt   = ["R", "X", "C", "Tap", "Phase", "Smax", "Imax", "Pmax", "Qmax", "Vargmax", ...
                    "MidXaxis","MidYaxis","Marker","BusFromPoint","BusToPoint"];

    % Validate table
    tab_bra = readtable(fullfile(path, "branch", "parameter.csv"), "TextType", "string");
    str_BraOpt = check_cols(tab_bra, str_BraReq, str_BraOpt, "branch/parameter.csv");

    % Add branches
    for i_bra = 1:size(tab_bra,1)
        tab_brai  = tab_bra(i_bra,:);
        str_Type  = tab_brai.Type;
        rs_fromto = tab_brai{1,["From", "To"]};
        
        tab_opt = tab_brai(1,str_BraOpt);
        sct_opt = table2struct(tab_opt);
        opt = namedargs2cell(sct_opt);
        net.add_branch(str_Type, rs_fromto, opt{:});
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
            
            opt = namedargs2cell(sct_opt);
            a_Bus{i_bus}.add_component(str_CompKey, "P", r_P, "Q", r_Q, opt{:});
        end
    end

    
    if options.Initialize
        net.initialize;
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
