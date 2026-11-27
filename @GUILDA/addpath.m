function addpath()
% Add paths for use of this software
% The root folder (".") comes first: it holds @GUILDA, so GUILDA.config and
% the other GUILDA methods work from any current folder.
% The optional folders _GUILDAverification and _GUILDAtextbook at the root are
% added when they exist, each folder only (not its subfolders); a missing one
% is skipped without a message.
% The folders of the setting Startup.ModelFolder (model classes of the user) are added
% after them at the end of the path, each with its subfolders except hidden folders and
% folders named archive (genpath: package and class folders are found through their
% parent). A GUILDA class therefore keeps its name against a user class of the same name.
% A folder that does not exist is skipped ("not found" in the log; GUILDA.dictionary
% warns about it). Run GUILDA.addpath and GUILDA.update_keymap after changing ModelFolder.
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
    % folders of the user: GUILDA.config needs the GUILDA folders on the path
    for s_folder = GUILDA.config("Startup","ModelFolder")
        s_log = [s_log, '︎  addpath: ', char(s_folder), ' ... ']; %#ok<AGROW>
        if ~isfolder(s_folder)
            s_log = [s_log, sprintf('not found\n')]; %#ok<AGROW>
            continue
        end
        sv_sub = split(string(genpath(char(s_folder))), pathsep);
        sv_sub = sv_sub(startsWith(sv_sub, s_folder));
        sv_rel = extractAfter(sv_sub, strlength(s_folder));
        sv_sub = sv_sub(~contains(sv_rel, filesep + ".") & ~contains(sv_rel + filesep, filesep + "archive" + filesep));
        try
            addpath(sv_sub{:}, '-end')
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
