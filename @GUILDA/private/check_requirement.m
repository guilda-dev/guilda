function check_requirement()
% Check the MATLAB version and the optional toolboxes listed in ./@GUILDA/config/ListToolbox.json.
%
% Prints "ok" for each installed toolbox and its Warning (what is unavailable without it)
% for each missing one. A toolbox counts as installed when it is licensed (license test)
% and installed (ver), the same check as tools.require_toolbox.

    sct_toolbox = jsondecode(fileread(fullfile(GUILDA.pwd,"@GUILDA","config","ListToolbox.json")));
    sv_key  = string(fieldnames(sct_toolbox));
    sv_name = arrayfun(@(s) string(sct_toolbox.(s).Name), sv_key);
    maxchar = max(strlength(sv_name)) + 1;

    fprintf('\n === Check Requirement === \n')
    
    nc = max(1,maxchar-8);
    fprintf(['︎   version : R2025a~ ',repmat(' ',1,nc),'... '])
    tab_ver  = struct2table(ver);
    l_MATLAB = (string(tab_ver.Name) == "MATLAB");
    sr_Release   = sort([tab_ver{l_MATLAB,"Release"},{'(R2025a)'}]);
    if strcmp(sr_Release{1},"(R2025a)")
        disp('ok')
    else
        disp('update your MATLAB version.')
    end

    for i = 1:numel(sv_key)
        sct = sct_toolbox.(sv_key(i));
        nc  = max(1,maxchar-strlength(sv_name(i)));
        fprintf(['︎   toolbox : ',char(sv_name(i)),repmat(' ',1,nc),'... '])
        if license('test', sct.License) && ~isempty(ver(char(sv_key(i))))
            disp('ok')
        else
            disp(sct.Warning)
        end
    end
    disp(" ")
end
