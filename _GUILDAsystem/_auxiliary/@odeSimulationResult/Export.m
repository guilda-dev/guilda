function str_file = Export(obj, filename)
% Write the trajectories to a table file or a MAT-file.
%
% Writes the trajectories to a file. The format follows the extension of filename:
% .csv, .txt, .xlsx, .xls write one table (column t, then <bus>_Vreal, <bus>_Vimag,
% <bus>_Ireal, <bus>_Iimag, <bus>_P, <bus>_Q of each bus and <component>_<name> of each
% state and input); .mat saves odeResults, options, flag and output. A relative filename is
% relative to the current folder. simulate(..., Export=filename) calls it.
    arguments
        obj
        filename (1,1) string = string(datetime("now","Format","uuMMdd_HHmmss")) + "_simulation.csv" % Output file; its extension selects the format.
    end
    arguments (Output)
        str_file % Path of the written file.
    end
    str_file = filename;
    [~, ~, str_ext] = fileparts(str_file);

    switch lower(str_ext)
        case {".csv", ".txt", ".xlsx", ".xls"}
            writetable(wide_table(obj), str_file);
        case ".mat"
            odeResults = obj.odeResults; %#ok<PROPLC>
            options    = obj.options;
            flag       = obj.flag;
            output     = obj.output;
            save(str_file, "odeResults", "options", "flag", "output");
        otherwise
            error('GUILDA:odeSimulationResult:ExportFormat', '%s', ...
                  msg('GUILDA:odeSimulationResult:ExportFormat', char(str_ext)));
    end
end


function tab = wide_table(obj)
% One column per trajectory, prefixed by the bus or component tag
    r   = obj.odeResults;
    tab = table(r.t, 'VariableNames', "t");
    for i = 1:numel(r.Bus)
        tab = [tab, prefixed([r.Bus(i).V, r.Bus(i).I, r.Bus(i).PQ], obj.sv_bus(i))]; %#ok<AGROW>
        for j = 1:numel(r.Bus(i).Component)
            c = r.Bus(i).Component(j);
            if ~isfield(c, "X")             % a bus without components
                continue
            end
            tab = [tab, prefixed([c.X, c.U], obj.c_component{i}(j))]; %#ok<AGROW>
        end
    end
end

function tab = prefixed(tab, str_tag)
    tab.Properties.VariableNames = str_tag + "_" + string(tab.Properties.VariableNames);
end
