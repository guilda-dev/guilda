function export_script(obj, s_path)
% Write the script of get_script to a .m file (UTF-8).
%
% <@Examples>
% ```matlab
% h.export_script("build_net.m")
% ```
    arguments (Input)
        obj                   % The log.
        s_path (1,1) string   % Path of the .m file; an existing file is overwritten.
    end
    arguments (Output)
    end
    if ~endsWith(s_path, ".m", "IgnoreCase", true)
        error(msg("GUILDA:HistoryGUILDA:NotMFile", s_path))
    end
    file_id = fopen(s_path, 'w', 'n', 'UTF-8');
    if file_id < 0
        error(msg("GUILDA:HistoryGUILDA:CannotWrite", s_path))
    end
    fprintf(file_id, '%s', char(obj.get_script()));
    fclose(file_id);
end
