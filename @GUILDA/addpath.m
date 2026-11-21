function addpath()
% Add paths for use of this software
% The root folder (".") comes first: it holds @GUILDA, so GUILDA.config and
% the other GUILDA methods work from any current folder.
% The optional folders _GUILDAverification and _GUILDAtextbook at the root are
% added when they exist, each folder only (not its subfolders); a missing one
% is skipped without a message.
% The log lines are printed in the Command Window while the setting
% Startup.PrintPathLog is true (default); a failure is always reported.

    GUILDApath = GUILDA.pwd;
    pathlist = fileread(fullfile(GUILDApath,"@GUILDA","config","ListPath.txt"));
    pathlist = [".", string( strsplit(strtrim(pathlist)) )];
    sv_optional  = ["_GUILDAverification", "_GUILDAtextbook"];
    pathlist = [pathlist, sv_optional(arrayfun(@(s) isfolder(fullfile(GUILDApath,s)), sv_optional))];
    flag_warning = false;
    maxchar      = max(cellfun(@(c) numel(c), pathlist)) + 1;

    % log lines are printed after the folders are on the path: GUILDA.config may
    % show INFO with show_msg of _GUILDAsystem/_auxiliary
    s_log = sprintf('\n === Add path for GUILDA === \n');
    for i = 1:numel(pathlist)
        p  = pathlist{i};
        nc = max(1,maxchar-numel(p));
        s_log = [s_log, '︎  addpath: ',p,repmat(' ',1,nc),'... ']; %#ok<AGROW>
        try
            if p == "."
                addpath( GUILDApath )
            else
                addpath( fullfile(GUILDApath,replace(p,"/",filesep)) )
            end
            s_log = [s_log, sprintf('ok\n')]; %#ok<AGROW>
        catch
            s_log = [s_log, sprintf('failed !!!\n')]; %#ok<AGROW>
            flag_warning = true;
        end
    end
    if GUILDA.config("Startup","PrintPathLog")
        fprintf('%s', s_log)
    end
    if flag_warning
        disp('Failed to add the required folder path to GUILDA. This may cause a functional failure.')
    end
end
