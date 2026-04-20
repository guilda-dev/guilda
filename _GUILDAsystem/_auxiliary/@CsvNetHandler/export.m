function path = export(net, ModelName, opt)
%EXPORT Export PowerNetwork to CSV files.
% Output directory structure:
%   <savepath>/@ModelName/
%     bus/powerflow.csv
%     branch/powerflow.csv
%     component/<key>/option.csv
%     component/<key>/dynamics.csv   (only when needed)

    arguments
        net               (1,1) PowerNetwork
        ModelName         (1,1) string  {mustBeValidVariableName} = "PowerNetwork"+string(datetime("now","Format","uuuuMMdd_HHmmss"))
        opt.version       (1,1) double  = 1.0;
        opt.savepath      (1,1) string  {mustBeFolder} = uigetdir(fullfile(GUILDA.pwd,"_GUILDAexport"), "Select folder to save CSV folder")
        opt.Overwrite     (1,1) logical = false
    end

    path = fullfile(opt.savepath, "@"+ModelName);
    if ~opt.Overwrite && isfolder(path)
        error("Output folder already exists: %s", path);
    end
    mkdir(fullfile(path, "bus"));
    mkdir(fullfile(path, "branch"));
    mkdir(fullfile(path, "component"));

    % Export bus and branch data
    str_bus = string(net.a_Bus);
    tab_pf = bus_table(net);
    writetable(tab_pf,    fullfile(path, "bus", "parameter.csv"));
    
    tab_pf = branch_table(net, str_bus);
    writetable(tab_pf, fullfile(path, "branch", "parameter.csv"));
    
    % Export component data
    a_Comp = tools.vcellfun(@(bus) bus.a_Component, net.a_Bus);
    str_key = tools.vcellfun(@(comp) string(comp.key), a_Comp);
    [str_key,~,i_keymap] = unique(str_key);
    for i_key = 1:numel(str_key)
        str_path_comp = fullfile(path, "component", str_key(i_key));
        i_Compi  = i_keymap == i_key;
        a_Compi  = a_Comp(i_Compi);
    
        mkdir(str_path_comp);
        
        [tab_para, tab_dyn, tab_opf] = component_table(a_Compi, str_bus);
        writetable(tab_para,  fullfile(str_path_comp, "main.csv"));
        writetable(tab_dyn,   fullfile(str_path_comp, "dynamics.csv"));
        writetable(tab_opf,   fullfile(str_path_comp, "opf.csv"));
    end

    % make constructor file
    str_code = make_constructor_file(ModelName, net, opt.version);
    str_outpath  = fullfile(path, ModelName + ".m");
    writelines(str_code,str_outpath);

end


function tab_pf = bus_table(net)
    n_bus = numel(net.a_Bus);
    Tag   = string(nan(n_bus,1));

    for i = 1:n_bus
        char_tag   = char(string(net.a_Bus{i}.str_tag));
        Tag(i)     = string(char_tag(1:end-3));
    end
    
    get_tab = @(b) [b.para_powerflow.tab_parameter,...
                    b.para_operation.tab_parameter,...
                    b.para_dynamics.tab_parameter,...
                    b.para_graph.tab_parameter];
    tab_bus = tools.vcellfun(@(b) get_tab(b), net.a_Bus);
    tab_pf  = [table(Tag), tab_bus];
end

function tab_para = branch_table(net, str_bus)
    n_bra   = numel(net.a_Branch);

    Type    = string(nan(n_bra,1));
    From    = nan(n_bra,1);
    To      = nan(n_bra,1);


    for i = 1:n_bra
        br = net.a_Branch{i};
        Type(i)    = br.key;
        From(i)    = find(str_bus == string(br.a_Bus{1}));
        To(i)      = find(str_bus == string(br.a_Bus{2}));
    end

    get_tab = @(b) [b.para_dynamics.tab_parameter,...
                    b.para_operation.tab_parameter,...
                    b.para_graph.tab_parameter];
    tab_bus  = tools.vcellfun(@(b) get_tab(b), net.a_Branch);
    tab_para = [table(Type, From, To), tab_bus];
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
    OPFcost_startup = nan(n_comp,1);
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

    OpfID       = (1:size(tab_opf,1))';
    tab_opf  = [table(OpfID), tab_opf];
    
    ParameterID = (1:size(tab_para,1))';
    tab_para = [table(ParameterID), tab_para];
end

function str_code = make_constructor_file(ModelName, net, ver)
    
    str_myfile   = mfilename("fullpath");
    str_mypath   = fileparts(str_myfile);
    str_template = fullfile(str_mypath, "template.txt");
    str_template_code = string(fileread(str_template));

    a_comp   = tools.vcellfun(@(bus) bus.a_Component, net.a_Bus);
    l_isgen  = tools.vcellfun(@(comp) isa(comp, "component.generator.abstract"), a_comp);
    l_isload = tools.vcellfun(@(comp) isa(comp, "component.load.abstract"), a_comp);
    l_others = ~(l_isgen|l_isload);

    n_count = [numel(net.a_Bus),...
               numel(net.a_Branch),...
               numel(a_comp),...
               sum(l_isgen),...
               sum(l_isload),...
               sum(l_others),...
               ver];

    str_rep = ["___MODEL_NAME___"     , ...
               "____MADE_DATE____"    , ...
               "___BUS_NUM___"        , ...
               "___BRANCH_NUM___"     , ...
               "___COMPONENT_NUM___"  , ...
               "___GENERATOR_NUM___"  , ...
               "___LOAD_NUM___"       , ...
               "___COMPENSATOR_NUM___", ...
               "___VERSION___"];

    str_new = [ModelName, ...
               string(datetime("now","Format","uuuu/MM/dd HH:mm:ss")), ...
               string(n_count)];

    str_code = replace(str_template_code, str_rep, str_new);
end