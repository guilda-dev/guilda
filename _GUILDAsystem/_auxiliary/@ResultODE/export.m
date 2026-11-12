function s_file = export(obj, filename)
% Write the trajectories to a table file or a MAT-file.
%
% Writes the trajectories to a file. The format follows the extension of filename:
% .csv, .txt, .xlsx, .xls write one table (column t, then <bus>_Vreal, <bus>_Vimag,
% <bus>_Ireal, <bus>_Iimag, <bus>_P, <bus>_Q of each bus, <component>_<name> of each
% state and input, one column per controller state named by the Label of tab_variable,
% and one column per output named by the Label of tab_output); .mat saves odeResults,
% rm_variable, tab_variable, rm_output, tab_output, options, flag and output, so the
% controller states and outputs (in rm_variable and rm_output only) are kept. A relative filename is
% relative to the current folder. simulate(..., Export=filename) calls it.
    arguments (Input)
        obj
        filename (1,1) string = string(datetime("now","Format","uuMMdd_HHmmss")) + "_simulation.csv" % Output file; its extension selects the format.
    end
    arguments (Output)
        s_file % Path of the written file.
    end
    s_file = filename;
    [~, ~, s_ext] = fileparts(s_file);

    switch lower(s_ext)
        case {".csv", ".txt", ".xlsx", ".xls"}
            writetable(wide_table(obj), s_file);
        case ".mat"
            odeResults   = obj.odeResults;
            rm_variable  = obj.rm_variable;
            tab_variable = obj.tab_variable;
            rm_output  = obj.rm_output;
            tab_output = obj.tab_output;
            options    = obj.options;
            flag       = obj.flag;
            output     = obj.output;
            save(s_file, "odeResults", "rm_variable", "tab_variable", "rm_output", "tab_output", ...
                 "options", "flag", "output");
        otherwise
            error(msg("GUILDA:ResultODE:ExportFormat", char(s_ext)));
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
    % The Label tells apart controllers with the same tag on different components
    tab_map = obj.tab_variable;
    lv_ctrl = tab_map.Kind == "x" & ~ismember(tab_map.Owner, vertcat(obj.c_component{:}));
    tab = [tab, array2table(obj.rm_variable(:, lv_ctrl), 'VariableNames', tab_map.Label(lv_ctrl))];
    tab = [tab, array2table(obj.rm_output, 'VariableNames', obj.tab_output.Label)];
end

function tab = prefixed(tab, s_tag)
    tab.Properties.VariableNames = s_tag + "_" + string(tab.Properties.VariableNames);
end
