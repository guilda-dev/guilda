function export_update_log()
%EXPORT_UPDATE_LOG Export update log text entries to _GUILDAdoc/database/list_UpdateLog.js
% Expected input format (@GUILDA/config/ListUpdateLog.txt):
%   date   : YYYY-MM-DD
%   title  : ...
%   content: ...
%   ---
% Lines that are empty or start with '#' or '%' are ignored.

    str_GUILDApath = GUILDA.pwd();
    str_input_file = fullfile(str_GUILDApath, '@GUILDA', 'config', 'ListUpdateLog.txt');
    str_output_file = fullfile(str_GUILDApath, '_GUILDAdoc', 'database', 'list_UpdateLog.js');

    if ~isfile(str_input_file)
        error('export_update_log:InputNotFound', 'Input file was not found: %s', str_input_file);
    end

    file_id = fopen(str_input_file, 'r', 'n', 'UTF-8');
    if file_id < 0
        error('export_update_log:InputOpenFailed', 'Failed to open input file: %s', str_input_file);
    end
    cleaner = onCleanup(@() fclose(file_id));

    sct_logs = struct('title', {}, 'date', {}, 'content', {});
    sct_current = struct('date', '', 'title', '', 'content', '');
    i_line = 0;
    while true
        str_line = fgetl(file_id);
        if ~ischar(str_line)
            break
        end

        i_line = i_line + 1;
        str_line = strtrim(str_line);
        if startsWith(str_line, '#') || startsWith(str_line, '%')
            continue
        end

        if strcmp(str_line, '---')
            if ~isempty(strtrim([sct_current.date, sct_current.title, sct_current.content]))
                if isempty(sct_current.date) || isempty(sct_current.title) || isempty(sct_current.content)
                    warning('export_update_log:IncompleteEntry', ...
                        'Skipped incomplete entry near line %d in %s. date/title/content are required.', ...
                        i_line, str_input_file);
                else
                    sct_logs(end+1) = struct( ...
                        'title', sct_current.title, ...
                        'date', sct_current.date, ...
                        'content', sct_current.content ...
                    ); %#ok
                end
                sct_current = struct('date', '', 'title', '', 'content', '');
            end
            continue
        end

        if isempty(str_line)
            if ~isempty(strtrim([sct_current.date, sct_current.title, sct_current.content]))
                if isempty(sct_current.date) || isempty(sct_current.title) || isempty(sct_current.content)
                    warning('export_update_log:IncompleteEntry', ...
                        'Skipped incomplete entry near line %d in %s. date/title/content are required.', ...
                        i_line, str_input_file);
                else
                    sct_logs(end+1) = struct( ...
                        'title', sct_current.title, ...
                        'date', sct_current.date, ...
                        'content', sct_current.content ...
                    ); %#ok
                end
                sct_current = struct('date', '', 'title', '', 'content', '');
            end
            continue
        end

        if startsWith(str_line, '- ')
            if ~isempty(strtrim([sct_current.date, sct_current.title, sct_current.content]))
                if isempty(sct_current.date) || isempty(sct_current.title) || isempty(sct_current.content)
                    warning('export_update_log:IncompleteEntry', ...
                        'Skipped incomplete entry near line %d in %s. date/title/content are required.', ...
                        i_line, str_input_file);
                else
                    sct_logs(end+1) = struct( ...
                        'title', sct_current.title, ...
                        'date', sct_current.date, ...
                        'content', sct_current.content ...
                    ); %#ok
                end
                sct_current = struct('date', '', 'title', '', 'content', '');
            end
            str_line = strtrim(extractAfter(str_line, 2));
        end

        cell_tokens = regexp(str_line, '^([A-Za-z]+)\s*:\s*(.*)$', 'tokens', 'once');
        if isempty(cell_tokens)
            warning('export_update_log:InvalidLine', ...
                'Skipped invalid line %d in %s. Expected key-value format: key: value', ...
                i_line, str_input_file);
            continue
        end

        str_key = lower(strtrim(cell_tokens{1}));
        str_value = strtrim(cell_tokens{2});

        switch str_key
            case {'date', 'title', 'content'}
                sct_current.(str_key) = str_value;
            otherwise
                warning('export_update_log:UnknownKey', ...
                    'Skipped unknown key "%s" at line %d in %s.', ...
                    str_key, i_line, str_input_file);
        end
    end

    if ~isempty(strtrim([sct_current.date, sct_current.title, sct_current.content]))
        if isempty(sct_current.date) || isempty(sct_current.title) || isempty(sct_current.content)
            warning('export_update_log:IncompleteEntry', ...
                'Skipped incomplete entry near end of file in %s. date/title/content are required.', ...
                str_input_file);
        else
            sct_logs(end+1) = struct( ...
                'title', sct_current.title, ...
                'date', sct_current.date, ...
                'content', sct_current.content ...
            ); 
        end
    end

    if isempty(sct_logs)
        warning('export_update_log:NoEntries', 'No valid update log entries were found in: %s', str_input_file);
    end

    str_json = jsonencode(sct_logs, 'PrettyPrint', true);
    str_js_content = sprintf('const updateLogData = %s;\n', str_json);

    file_id = fopen(str_output_file, 'w', 'n', 'UTF-8');
    if file_id < 0
        error('export_update_log:OutputOpenFailed', 'Failed to open output file: %s', str_output_file);
    end
    fprintf(file_id, '%s', str_js_content);
    fclose(file_id);
end
