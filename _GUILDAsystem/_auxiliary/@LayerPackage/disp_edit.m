function varargout = disp_edit(obj)
% Show the edits of the layer and its subtree since the last initialize.
%
% Displays the edit log of this layer and every layer below it, in the order the edits
% were made, as a table: timestamp ("uuuu/MM/dd HH:mm:ss"), ID (tags from the edited
% layer up, joined by "/"), log, tag (kind of edit), before and after (cell columns).
% With an output argument it returns the table instead of displaying it.
%
% <@Examples>
% ```matlab
% net.disp_edit()               % every edit of the network
% net.a_Bus{1}.disp_edit()      % edits of the first bus and the layers below it
% tab = net.disp_edit();        % the same rows as a table
% ```
    arguments (Input)
        obj (1,1) % Layer whose subtree is shown.
    end
    arguments (Output, Repeating)
        varargout % Edit log (table, Nx6) when one output is requested; displayed otherwise.
    end
    sct_log   = obj.collect_edit();
    timestamp = reshape(string(datetime([sct_log.r_time], 'ConvertFrom','datenum', 'Format','uuuu/MM/dd HH:mm:ss')), [], 1);
    ID        = reshape(string({sct_log.s_ID}),  [], 1);
    log       = reshape(string({sct_log.s_log}), [], 1);
    tag       = reshape(string({sct_log.s_tag}), [], 1);
    before    = reshape({sct_log.before}, [], 1);
    after     = reshape({sct_log.after},  [], 1);
    tab = table(timestamp, ID, log, tag, before, after);

    switch nargout
        case 0
            if isempty(sct_log)
                disp("  (no edits since the last initialize)")
            else
                disp(tab)
            end
        case 1
            varargout{1} = tab;
    end
end
