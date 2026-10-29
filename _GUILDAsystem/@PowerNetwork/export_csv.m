function path = export_csv(obj, path, opt)
% <@Desc>
% Writes the network to a CSV model folder that PowerNetwork.import_csv reads back:
%   <path>/network/parameter.csv        Hz, baseMVA (net.tab_parameter.base)
%   <path>/bus/parameter.csv            one row per bus, in the order of net.a_Bus
%   <path>/branch/parameter.csv         one row per branch; From/To are bus row numbers
%   <path>/component/<key>/main.csv     one row per component of type <key>
%   <path>/component/<key>/dynamics.csv distinct parameter rows (column ParameterID)
%   <path>/component/<key>/opf.csv      distinct OPF rows (column OpfID)
% The bus column Slack is 1 for the slack bus. Equilibria and controllers are not saved.
% When the folder name starts with "@" (e.g. "@MyNet"), a class file MyNet.m is also
% written, so that the folder is a network class (net = MyNet()) when its parent folder
% is on the MATLAB path.
% An existing folder is an error unless Overwrite=true, which first deletes the network,
% bus, branch and component subfolders and the class file written by an earlier export.
% <@Role> Export
% <@Summary> Write the network to a CSV model folder.
% <@Signatures>
% [
%   "path = net.export_csv(path)",
%   "path = net.export_csv(path, Name, Value)"
% ]
% <@Parameters>
% [
%   {"Name": "path", "Type": "string scalar", "Description": "Model folder to write (created; its parent must exist).", "Required": true, "Default": "-"},
%   {"Name": "Overwrite", "Type": "logical scalar", "Description": "Replace an existing folder.", "Required": false, "Default": "false"},
%   {"Name": "ClassFile", "Type": "logical scalar", "Description": "Write the class file <name>.m (name = folder name without the leading @).", "Required": false, "Default": "true when the folder name starts with @"}
% ]
% <@Returns>
% [
%   {"Name": "path", "Type": "string scalar", "Description": "The written model folder."}
% ]
% <@Examples>
% [
%   "```matlab\nnet  = network.IEEE14bus;\npath = net.export_csv(fullfile(tempdir, \"@MyIEEE14\"), Overwrite=true);\nnet2 = PowerNetwork.import_csv(path);\n```"
% ]
% <@Since> 4.0

    arguments
        obj
        path            (1,1) string
        opt.Overwrite   (1,1) logical = false
        opt.ClassFile   (1,1) logical
    end
    path = strip(path, "right", filesep);
    [str_parent, str_folder] = fileparts(path);
    if ~isfield(opt, "ClassFile")
        opt.ClassFile = startsWith(str_folder, "@");
    end
    str_class = strip(str_folder, "left", "@");
    if opt.ClassFile && ~isvarname(str_class)
        error("GUILDA:export_csv:InvalidClassName", ...
              "The class file needs a valid MATLAB name, but the folder name gives ""%s"". Rename the folder or set ClassFile=false.", str_class);
    end
    if str_parent ~= "" && ~isfolder(str_parent)
        error("GUILDA:export_csv:NoParentFolder", "Parent folder not found: %s. Create it first.", str_parent);
    end
    if isfolder(path)
        if ~opt.Overwrite
            error("GUILDA:export_csv:FolderExists", ...
                  "Output folder already exists: %s. Set Overwrite=true to replace it, or choose another folder.", path);
        end
        for str_sub = ["network", "bus", "branch", "component"]
            if isfolder(fullfile(path, str_sub))
                rmdir(fullfile(path, str_sub), "s");
            end
        end
        if isfile(fullfile(path, str_class + ".m"))
            delete(fullfile(path, str_class + ".m"));
        end
    end
    for str_sub = ["network", "bus", "branch", "component"]
        mkdir(fullfile(path, str_sub));
    end

    % Export network base values
    writetable(obj.para_base.tab_parameter, fullfile(path, "network", "parameter.csv"));

    % Export bus and branch data
    str_bus = string(obj.a_Bus);
    writetable(bus_table(obj),             fullfile(path, "bus",    "parameter.csv"));
    writetable(branch_table(obj, str_bus), fullfile(path, "branch", "parameter.csv"));

    % Export component data
    a_Comp  = tools.vcellfun(@(bus) bus.a_Component, obj.a_Bus);
    str_key = tools.vcellfun(@(comp) string(comp.key), a_Comp);
    [str_key,~,i_keymap] = unique(str_key);
    for i_key = 1:numel(str_key)
        str_path_comp = fullfile(path, "component", str_key(i_key));
        a_Compi       = a_Comp(i_keymap == i_key);
        mkdir(str_path_comp);

        [tab_para, tab_dyn, tab_opf] = component_table(a_Compi, str_bus);
        writetable(tab_para, fullfile(str_path_comp, "main.csv"));
        writetable(tab_dyn,  fullfile(str_path_comp, "dynamics.csv"));
        writetable(tab_opf,  fullfile(str_path_comp, "opf.csv"));
    end

    % Class file
    if opt.ClassFile
        writelines(class_file(str_class, obj), fullfile(path, str_class + ".m"));
    end
end


function tab_pf = bus_table(net)
    n_bus = numel(net.a_Bus);
    Tag   = strings(n_bus,1);
    Slack = zeros(n_bus,1);
    for i = 1:n_bus
        char_tag = char(string(net.a_Bus{i}.str_tag));
        Tag(i)   = string(char_tag(1:end-3));
        Slack(i) = net.a_Bus{i}.l_isSlack;
    end

    get_tab = @(b) [b.para_powerflow.tab_parameter,...
                    b.para_operation.tab_parameter,...
                    b.para_dynamics.tab_parameter,...
                    b.para_graph.tab_parameter];
    tab_bus = tools.vcellfun(@(b) get_tab(b), net.a_Bus);
    tab_pf  = [table(Tag), tab_bus, table(Slack)];
end

function tab_para = branch_table(net, str_bus)
    n_bra = numel(net.a_Branch);
    Type  = strings(n_bra,1);
    From  = nan(n_bra,1);
    To    = nan(n_bra,1);
    for i = 1:n_bra
        br = net.a_Branch{i};
        Type(i) = br.key;
        From(i) = find(str_bus == string(br.a_Bus{1}));
        To(i)   = find(str_bus == string(br.a_Bus{2}));
    end

    get_tab = @(b) [b.para_dynamics.tab_parameter,...
                    b.para_operation.tab_parameter,...
                    b.para_graph.tab_parameter];
    tab_bra  = tools.vcellfun(@(b) get_tab(b), net.a_Branch);
    tab_para = [table(Type, From, To), tab_bra];
end

function [tab_opt, tab_para, tab_opf] = component_table(a_Comp, str_Bus)
    n_comp = numel(a_Comp);

    Bus = nan(n_comp,1);
    OPFinit_P0 = nan(n_comp,1);
    OPFinit_Q0 = nan(n_comp,1);
    OPFcost_HP = nan(n_comp,1);
    OPFcost_HQ = nan(n_comp,1);
    OPFcost_fP = nan(n_comp,1);
    OPFcost_fQ = nan(n_comp,1);
    OPFcost_startup  = nan(n_comp,1);
    OPFcost_shutdown = nan(n_comp,1);

    para = cell(n_comp,1);

    for i = 1:n_comp
        comp = a_Comp{i};
        para{i} = comp.para_dynamics.tab_parameter;

        tab_OPF  = comp.para_OPF.tab_parameter;
        Bus(i) = find(str_Bus == string(comp.a_Bus));
        OPFinit_P0(i) = tab_OPF.P0;
        OPFinit_Q0(i) = tab_OPF.Q0;
        OPFcost_HP(i) = tab_OPF.HP;
        OPFcost_HQ(i) = tab_OPF.HQ;
        OPFcost_fP(i) = tab_OPF.fP;
        OPFcost_fQ(i) = tab_OPF.fQ;
        OPFcost_startup(i)  = tab_OPF.startup;
        OPFcost_shutdown(i) = tab_OPF.shutdown;
    end

    tab_opf   = table(OPFinit_P0, OPFinit_Q0, OPFcost_HP, OPFcost_HQ, OPFcost_fP, OPFcost_fQ, OPFcost_startup, OPFcost_shutdown);
    tab_para  = vertcat(para{:});

    [tab_opf,  ~, OpfID]       = unique(tab_opf, 'rows', 'stable');
    [tab_para, ~, ParameterID] = unique(tab_para,'rows', 'stable');


    get_tab = @(b) [b.para_powerflow.tab_parameter,...
                    b.para_operation.tab_parameter,...
                    b.para_graph.tab_parameter];
    tab_comp  = tools.vcellfun(@(c) get_tab(c), a_Comp);
    tab_opt   = [table(Bus), tab_comp, table(ParameterID,OpfID)];

    OpfID    = (1:size(tab_opf,1))';
    tab_opf  = [table(OpfID), tab_opf];

    ParameterID = (1:size(tab_para,1))';
    tab_para    = [table(ParameterID), tab_para];
end

function str_code = class_file(str_class, net)
    str_template = fullfile(fileparts(mfilename("fullpath")), "private", "export_csv_class.txt");
    str_code     = string(fileread(str_template));

    a_comp   = tools.vcellfun(@(bus) bus.a_Component, net.a_Bus);
    l_isgen  = tools.vcellfun(@(comp) isa(comp, "component.generator.abstract"), a_comp);
    l_isload = tools.vcellfun(@(comp) isa(comp, "component.load.abstract"), a_comp);
    l_others = ~(l_isgen|l_isload);

    n_count = [numel(net.a_Bus), numel(net.a_Branch), numel(a_comp), ...
               sum(l_isgen), sum(l_isload), sum(l_others)];

    str_rep = ["___MODEL_NAME___"     , ...
               "____MADE_DATE____"    , ...
               "___BUS_NUM___"        , ...
               "___BRANCH_NUM___"     , ...
               "___COMPONENT_NUM___"  , ...
               "___GENERATOR_NUM___"  , ...
               "___LOAD_NUM___"       , ...
               "___COMPENSATOR_NUM___"];
    str_new = [str_class, ...
               string(datetime("now","Format","uuuu/MM/dd HH:mm:ss")), ...
               string(n_count)];
    str_code = replace(str_code, str_rep, str_new);
end
