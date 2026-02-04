function check_requirement()
% Verification of Toolbox Installation Required for GUILDA Execution
% show >> ./@GUILDA/config/ListToolbox.txt

    product_info = ver;
    ToolboxInstalled = arrayfun(@(s) s.Name, product_info, 'UniformOutput', false);
    ToolboxRequired  = readlines(fullfile(GUILDA.pwd,"@GUILDA","config","ListToolbox.txt"));
    flag_warning = false;
    maxchar      = max(cellfun(@(c) numel(c), ToolboxRequired)) + 1;

    fprintf('\n === Check Requirement === \n')
    
    nc = max(1,maxchar-8);
    fprintf(['︎   version : R2023b~ ',repmat(' ',1,nc),'... '])
    tab_ver  = struct2table(ver);
    l_MATLAB = (string(tab_ver.Name) == "MATLAB");
    str_Release  = sort([tab_ver{l_MATLAB,"Release"},{'(R2023b)'}]);
    if strcmp(str_Release{1},"(R2023b)")
        disp('ok')
    else
        disp('update your MATLAB version.')
        flag_warning = true;
    end


    for i = 1:numel(ToolboxRequired)
        tr = char(ToolboxRequired(i));
        nc = max(1,maxchar-numel(tr));
        fprintf(['︎   toolbox : ',tr,repmat(' ',1,nc),'... '])
        if ismember(tr,ToolboxInstalled)
            disp('ok')
        else
            disp('Not installed!!')
            flag_warning = true;
        end
    end
    if flag_warning
        disp('Required Toolbox components for GUILDA specifications are currently missing installation. Execution of some analyses may result in errors.')
    end
    disp(" ")
end