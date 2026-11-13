function path = export(obj, path, opt)
% Write the network to a CSV model folder.
%
% Writes the network to a CSV model folder that PowerNetwork.import reads back:
%   <path>/network/parameter.csv        Hz, baseMVA (net.tab_parameter.base)
%   <path>/bus/parameter.csv            one row per bus, in the order of net.a_Bus
%   <path>/branch/parameter.csv         one row per branch; From/To are bus row numbers
%   <path>/component/<key>/main.csv     one row per component of type <key>
%   <path>/component/<key>/dynamics.csv distinct parameter rows (column ParameterID)
%   <path>/component/<key>/opf.csv      distinct OPF rows (column OpfID)
% The bus column Slack is 1 for the slack bus. The column FullTag of the bus, branch and
% component tables holds the full tag; the bus column Tag holds its prefix (the tag
% without its trailing digits). Equilibria and controllers are not saved;
% the warning GUILDA:PowerNetwork:ControllersNotSaved lists the controllers left out.
% When the folder name starts with "@" (e.g. "@MyNet"), a class file MyNet.m is also
% written, so that the folder is a network class (net = MyNet()) when its parent folder
% is on the MATLAB path.
% An existing folder is an error unless Overwrite=true, which first deletes the network,
% bus, branch and component subfolders and the class file written by an earlier export.
%
% <@Examples>
% ```matlab
% net  = network.IEEE14bus;
% path = net.export(fullfile(tempdir, "@MyIEEE14"), Overwrite=true);
% net2 = PowerNetwork.import(path);
% ```
%
% See also PowerNetwork.import
%
% <@Group> Data IO

    arguments (Input)
        obj
        path            (1,1) string   % Model folder to write (created; its parent must exist).
        opt.Overwrite   (1,1) logical = false   % Replace an existing folder.
        opt.ClassFile   (1,1) logical   % Write the class file <name>.m (name = folder name without the leading @). Default: true when the folder name starts with @.
    end
    arguments (Output)
        path   % The written model folder.
    end
    path = strip(path, "right", filesep);
    [s_parent, s_folder] = fileparts(path);
    if ~isfield(opt, "ClassFile")
        opt.ClassFile = startsWith(s_folder, "@");
    end
    s_class = strip(s_folder, "left", "@");
    if opt.ClassFile && ~isvarname(s_class)
        error(msg("GUILDA:export:InvalidClassName", s_class));
    end
    if s_parent ~= "" && ~isfolder(s_parent)
        error(msg("GUILDA:export:NoParentFolder", s_parent));
    end
    if isfolder(path)
        if ~opt.Overwrite
            error(msg("GUILDA:export:FolderExists", path));
        end
        for s_sub = ["network", "bus", "branch", "component"]
            if isfolder(fullfile(path, s_sub))
                rmdir(fullfile(path, s_sub), "s");
            end
        end
        if isfile(fullfile(path, s_class + ".m"))
            delete(fullfile(path, s_class + ".m"));
        end
    end
    for s_sub = ["network", "bus", "branch", "component"]
        mkdir(fullfile(path, s_sub));
    end

    % Export network base values
    writetable(obj.a_Parameter{cellfun(@(p) p.s_tag=="base", obj.a_Parameter)}.tab_parameter, fullfile(path, "network", "parameter.csv"));

    % Export bus and branch data
    sv_bus = string(obj.a_Bus);
    writetable(bus_table(obj),             fullfile(path, "bus",    "parameter.csv"));
    writetable(branch_table(obj, sv_bus), fullfile(path, "branch", "parameter.csv"));

    % Export component data
    a_Comp  = tools.vcellfun(@(bus) bus.a_Component, obj.a_Bus);
    sv_key  = tools.vcellfun(@(comp) string(comp.key), a_Comp);
    [sv_key,~,i_keymap] = unique(sv_key);
    for i_key = 1:numel(sv_key)
        s_path_comp   = fullfile(path, "component", sv_key(i_key));
        a_Compi       = a_Comp(i_keymap == i_key);
        mkdir(s_path_comp);

        [tab_para, tab_dyn, tab_opf] = component_table(a_Compi, sv_bus);
        writetable(tab_para, fullfile(s_path_comp, "main.csv"));
        writetable(tab_dyn,  fullfile(s_path_comp, "dynamics.csv"));
        writetable(tab_opf,  fullfile(s_path_comp, "opf.csv"));
    end

    % Class file
    if opt.ClassFile
        writelines(class_file(s_class, obj), fullfile(path, s_class + ".m"));
    end

    warn_controllers_not_saved(obj, a_Comp);
end


function warn_controllers_not_saved(net, a_Comp)
    sv_local   = [strings(0,1); tools.vcellfun(@(comp) local_controller_paths(comp), a_Comp)];
    sv_global  = [strings(0,1); tools.vcellfun(@string, net.a_GlobalController)];
    if isempty(sv_local) && isempty(sv_global)
        return
    end
    show_msg("warning", "GUILDA:PowerNetwork:ControllersNotSaved", char(net.s_tag), ...
                char(string(numel(sv_local))), char(tag_list(sv_local)), ...
                char(string(numel(sv_global))), char(tag_list(sv_global)))
end

function sv_path = local_controller_paths(layer)
    % "<component>/<AVR>" and "<component>/<AVR>/<PSS>": tags alone may repeat between components
    sv_path = strings(0,1);
    for i = 1:numel(layer.a_LocalController)
        con = layer.a_LocalController{i};
        sv_path = [sv_path; string(layer) + "/" + [string(con); local_controller_paths(con)]]; %#ok<AGROW>
    end
end

function str = tag_list(sv_tag)
    str = "none";
    if ~isempty(sv_tag)
        str = join(sv_tag, ", ");
    end
end

function tab_pf = bus_table(net)
    n_bus = numel(net.a_Bus);
    Tag   = strings(n_bus,1);
    FullTag = strings(n_bus,1);
    Slack = zeros(n_bus,1);
    for i = 1:n_bus
        FullTag(i) = string(net.a_Bus{i}.s_tag);
        Tag(i)   = regexprep(FullTag(i), '\d+$', '');
        Slack(i) = net.a_Bus{i}.l_isSlack;
    end

    get_tab = @(b) [b.a_Parameter{cellfun(@(p) p.s_tag=="powerflow", b.a_Parameter)}.tab_parameter,...
                    b.a_Parameter{cellfun(@(p) p.s_tag=="operation", b.a_Parameter)}.tab_parameter,...
                    b.a_Parameter{cellfun(@(p) p.s_tag=="dynamics", b.a_Parameter)}.tab_parameter,...
                    b.a_Parameter{cellfun(@(p) p.s_tag=="graph", b.a_Parameter)}.tab_parameter];
    tab_bus = tools.vcellfun(@(b) get_tab(b), net.a_Bus);
    tab_pf  = [table(Tag, FullTag), tab_bus, table(Slack)];
end

function tab_para = branch_table(net, sv_bus)
    n_bra = numel(net.a_Branch);
    Type  = strings(n_bra,1);
    From  = nan(n_bra,1);
    To    = nan(n_bra,1);
    FullTag = strings(n_bra,1);
    for i = 1:n_bra
        br = net.a_Branch{i};
        FullTag(i) = string(br);
        Type(i) = br.key;
        From(i) = find(sv_bus == string(br.a_Bus{1}));
        To(i)   = find(sv_bus == string(br.a_Bus{2}));
    end

    get_tab = @(b) [b.a_Parameter{cellfun(@(p) p.s_tag=="dynamics", b.a_Parameter)}.tab_parameter,...
                    b.a_Parameter{cellfun(@(p) p.s_tag=="operation", b.a_Parameter)}.tab_parameter,...
                    b.a_Parameter{cellfun(@(p) p.s_tag=="graph", b.a_Parameter)}.tab_parameter];
    tab_bra  = tools.vcellfun(@(b) get_tab(b), net.a_Branch);
    tab_para = [table(Type, From, To, FullTag), tab_bra];
end

function [tab_opt, tab_para, tab_opf] = component_table(a_Comp, sv_Bus)
    n_comp = numel(a_Comp);

    Bus = nan(n_comp,1);
    FullTag = strings(n_comp,1);
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
        para{i} = comp.a_Parameter{cellfun(@(p) p.s_tag=="dynamics", comp.a_Parameter)}.tab_parameter;

        tab_OPF  = comp.a_Parameter{cellfun(@(p) p.s_tag=="OPF", comp.a_Parameter)}.tab_parameter;
        Bus(i) = find(sv_Bus == string(comp.a_Bus));
        FullTag(i) = string(comp);
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


    get_tab = @(b) [b.a_Parameter{cellfun(@(p) p.s_tag=="powerflow", b.a_Parameter)}.tab_parameter,...
                    b.a_Parameter{cellfun(@(p) p.s_tag=="operation", b.a_Parameter)}.tab_parameter,...
                    b.a_Parameter{cellfun(@(p) p.s_tag=="graph", b.a_Parameter)}.tab_parameter];
    tab_comp  = tools.vcellfun(@(c) get_tab(c), a_Comp);
    tab_opt   = [table(Bus, FullTag), tab_comp, table(ParameterID,OpfID)];

    OpfID    = (1:size(tab_opf,1))';
    tab_opf  = [table(OpfID), tab_opf];

    ParameterID = (1:size(tab_para,1))';
    tab_para    = [table(ParameterID), tab_para];
end

function s_code = class_file(s_class, net)
    s_template   = fullfile(fileparts(mfilename("fullpath")), "private", "export_class.txt");
    s_code       = string(fileread(s_template));

    a_comp   = tools.vcellfun(@(bus) bus.a_Component, net.a_Bus);
    l_isgen  = tools.vcellfun(@(comp) isa(comp, "component.generator.abstract"), a_comp);
    l_isload = tools.vcellfun(@(comp) isa(comp, "component.load.abstract"), a_comp);
    l_others = ~(l_isgen|l_isload);

    n_count = [numel(net.a_Bus), numel(net.a_Branch), numel(a_comp), ...
               sum(l_isgen), sum(l_isload), sum(l_others)];

    sr_rep = ["___MODEL_NAME___"     , ...
               "____MADE_DATE____"    , ...
               "___BUS_NUM___"        , ...
               "___BRANCH_NUM___"     , ...
               "___COMPONENT_NUM___"  , ...
               "___GENERATOR_NUM___"  , ...
               "___LOAD_NUM___"       , ...
               "___COMPENSATOR_NUM___"];
    sr_new = [s_class, ...
               string(datetime("now","Format","uuuu/MM/dd HH:mm:ss")), ...
               string(n_count)];
    s_code = replace(s_code, sr_rep, sr_new);
end
