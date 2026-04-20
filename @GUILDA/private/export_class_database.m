function export_class_database(str_class_list)
    str_class_list = string(str_class_list);
    
    n_class = numel(str_class_list);
    
    disp(" ")
    disp(" === Update Documentation Database === ")
    disp("  Exporting class database for '_GUILDAdoc/database' ...")

    rv_character = strlength(str_class_list);
    r_indent = max(rv_character) + 2;
    sct_class_info = struct([]);
    for i_class = 1:n_class
        str_class_i = str_class_list(i_class);
        str_class_char = char(str_class_i);
        str_indent = repmat(' ', 1, r_indent - length(str_class_char));

        fprintf("  export("+num2str(i_class, '%.3d') + "/" + num2str(n_class, '%.0f') + "): " + str_class_i + str_indent + " ... ")
        try
            sct_info_i = export_class_doc(str_class_char);
            sct_class_info = [sct_class_info, sct_info_i]; %#ok<AGROW>
            disp("ok")
        catch
            disp("failed")
        end
    end

    if isempty(sct_class_info)
        warning('export_class_database:NoClassExported', 'No class documentation was exported.');
    end

    str_GUILDApath = GUILDA.pwd();
    str_file_name  = fullfile(str_GUILDApath, '_GUILDAdoc', 'database', 'list_Classes.js');
    str_json       = jsonencode(sct_class_info, 'PrettyPrint', true);
    str_js_content = sprintf('const class_list = %s;\n', str_json);
    
    % Overwrite output file.
    file_id       = fopen(str_file_name, 'w', 'n', 'UTF-8');
    if file_id < 0
        error('export_class_database:FileOpenFailed', 'Failed to open output file: %s', str_file_name);
    end
    fprintf(file_id, '%s', str_js_content);
    fclose(file_id);
end



function sct_info = export_class_doc(str_class_name)
    % This method uses MATLAB's reflection capabilities to extract metadata from the class properties and methods.
    % It also reads custom tags defined in the help comments.
    % The extracted information is saved as a JavaScript file for the GUILDA documentation database.
    meta_class       = meta.class.fromName(str_class_name);
    
    cell_prop_tags   = {'Desc', 'Role', 'Type', 'Size'};
    cell_method_tags = {
        'Desc', 'Role', 'Abst', 'DetailsCode', ...
        'Signatures', ...
        'Argin', 'Parameters', ...
        'Argout', 'Returns', ...
        'Examples', ...
        'Option'
    };
    cell_class_tags  = {'Desc', 'Role', 'Constructor'};

    sct_doc_data            = struct('ClassName', str_class_name, 'properties', [], 'methods', []);
    sct_doc_data.properties = build_meta_section(meta_class.PropertyList, str_class_name, cell_prop_tags,   "property");
    sct_doc_data.methods    = build_meta_section(meta_class.MethodList,   str_class_name, cell_method_tags, "method"  );
    sct_info                = build_class_info(str_class_name, meta_class, cell_class_tags);

    % Output JS file
    str_filepath   = which(str_class_name);
    str_GUILDApath = GUILDA.pwd;
    if contains(str_filepath, fullfile(str_GUILDApath, '_GUILDAsystem'))
        str_file_name = fullfile(str_GUILDApath, '_GUILDAdoc', 'database', 'GUILDAsystem', [str_class_name, '.js']);
    else
        str_file_name = fullfile(str_GUILDApath, '_GUILDAdoc', 'database', 'GUILDAobject', [str_class_name, '.js']);
    end
    sct_info.path  = str_file_name;
    str_json       = jsonencode(sct_doc_data, 'PrettyPrint', true);
    str_js_content = sprintf('const classData = %s;\n', str_json);
    file_id        = fopen(str_file_name, 'w', 'n', 'UTF-8');
    fprintf(file_id, '%s', str_js_content);
    fclose(file_id);
end

function sct_section = build_meta_section(meta_list, str_class_name, cell_tags, str_kind)
    sct_section = struct([]);
    for i_item = 1:numel(meta_list)
        meta_item   = meta_list(i_item);
        if ~strcmp(meta_item.DefiningClass.Name,'handle') && ~strcmp(meta_item.Name,'empty')
            sct_section = [sct_section, build_meta_info(meta_item, str_class_name, cell_tags, str_kind)]; 
        end
    end
end

function sct_info = build_meta_info(meta_item, str_class_name, cell_tags, str_kind)
    if str_kind == "property"
        sct_info = struct( ...
            'Name',      meta_item.Name,               ...
            'Defining',  meta_item.DefiningClass.Name, ...
            'GetAccess', organize_access(meta_item.GetAccess),          ...
            'SetAccess', organize_access(meta_item.SetAccess),          ...
            'Dependent', meta_item.Dependent,          ...
            'Constant',  meta_item.Constant,           ...
            'Abstract',  meta_item.Abstract,           ...
            'Hidden',    meta_item.Hidden              ...
            );
    else
        sct_info = struct( ...
            'Name',      meta_item.Name,               ...
            'Defining',  meta_item.DefiningClass.Name, ...
            'Access',    organize_access(meta_item.Access),             ...
            'Static',    meta_item.Static,             ...
            'Abstract',  meta_item.Abstract,           ...
            'Hidden',    meta_item.Hidden              ...
            );
    end

    str_raw_help = get_member_help_text(str_class_name, meta_item, str_kind);
    if isempty(strtrim(str_raw_help))
        str_raw_help = sanitize_help_text([meta_item.Description,newline, meta_item.DetailedDescription]);
    end
    sct_info = apply_help_tags(sct_info, str_raw_help, cell_tags);
end

function str_access = organize_access(dat)
    if isa(dat,"char") || isa(dat,"string")
        str_access = char(dat);
        return
    end

    if isscalar(dat)
        str_access = dat.Name;
    elseif iscell(dat)
        str_access = tools.hcellfun(@(d) [d.Name,', '], dat);
        str_access = str_access(1:(end-2));
    else
        str_access = tools.harrayfun(@(d) [d.Name,', '], dat);
        str_access = str_access(1:(end-2));
    end
end

function sct_info = build_class_info(str_class_name, meta_class, cell_tags)
    cell_superclasses = superclasses(str_class_name);

    if any(strcmp(cell_superclasses, "PowerSystemModel"))
        str_type  = "PowerSystemModel";
        str_list  = ["PowerNetwork", "Cubicle", "Bus", "Branch", "Component", "LocalController", "GlobalController"];
        str_model = "";
        for i = 1:numel(str_list)
            str_Model = str_list(i);
            if any(strcmp(cell_superclasses, str_Model)) || strcmp(meta_class.Name, str_Model)
                str_model = str_Model;
                break
            end
        end
    elseif any(strcmp(cell_superclasses, "auxiliary")) || strcmp(str_class_name, "LayerPackage")
        str_type = "auxiliary";
        str_model = "";
    else
        str_type = "other";
        str_model = "";
    end
    
    sct_info = struct( ...
        'Name',     str_class_name, ...
        'Type',     str_type, ...
        'Model',    str_model,...  
        'Parent',   organize_access(meta_class.SuperclassList), ...
        'Abstract', meta_class.Abstract, ...
        'Hidden',   meta_class.Hidden ...
    );
    str_help = get_class_help_text(str_class_name);
    if isempty(strtrim(str_help))
        str_help = sanitize_help_text([meta_class.Description,newline, meta_class.DetailedDescription]);
    end
    sct_info = apply_help_tags(sct_info, str_help, cell_tags);
end

function str_help = get_class_help_text(str_class_name)
    str_help = sanitize_help_text(try_help(str_class_name));
    if ~isempty(strtrim(str_help))
        return
    end

    str_class_path = which(str_class_name);
    str_help = extract_class_comment_block(str_class_path);
end

function str_help = get_member_help_text(str_class_name, meta_item, str_kind)
    str_help = '';
    str_member_name = string(meta_item.Name);

    % First try MATLAB help system.
    if str_kind == "method"
        str_help = sanitize_help_text(try_help(str_class_name + "." + str_member_name));
    elseif str_kind == "property"
        str_help = sanitize_help_text(try_help(str_class_name + "." + str_member_name));
    end
    if ~isempty(strtrim(str_help))
        return
    end

    % Fallback: parse source files under @ClassName.
    str_class_path = which(str_class_name);
    if str_kind == "method"
        str_method_path = fullfile(fileparts(str_class_path), char(str_member_name + ".m"));
        str_help = extract_function_comment_block(str_method_path);
    elseif str_kind == "property"
        str_help = extract_property_comment_block(str_class_path, char(str_member_name));
    end
end

function str_help = try_help(str_symbol)
    str_help = '';
    try
        str_help = char(string(help(char(str_symbol))));
    catch
        str_help = '';
    end

    str_trim = strtrim(str_help);
    if isempty(str_trim)
        str_help = '';
        return
    end

    if contains(str_trim, 'No help found', 'IgnoreCase', true) || contains(str_trim, 'ヘルプが見つかりません')
        str_help = '';
    end
end

function str_help = extract_class_comment_block(str_class_path)
    str_help = '';
    str_text = read_text_file(str_class_path);
    if isempty(str_text)
        return
    end

    cell_lines = regexp(regexprep(str_text, '\r\n?', '\n'), '\n', 'split');
    idx_classdef = find(~cellfun(@isempty, regexp(cell_lines, '^\s*classdef\b', 'once')), 1, 'first');
    if isempty(idx_classdef)
        return
    end

    str_help = collect_following_comment_lines(cell_lines, idx_classdef + 1);
end

function str_help = extract_function_comment_block(str_file_path)
    str_help = '';
    str_text = read_text_file(str_file_path);
    if isempty(str_text)
        return
    end

    cell_lines = regexp(regexprep(str_text, '\r\n?', '\n'), '\n', 'split');
    idx_function = find(~cellfun(@isempty, regexp(cell_lines, '^\s*function\b', 'once')), 1, 'first');
    if isempty(idx_function)
        return
    end

    str_help = collect_following_comment_lines(cell_lines, idx_function + 1);
end

function str_help = extract_property_comment_block(str_class_path, str_property_name)
    str_help = '';
    str_text = read_text_file(str_class_path);
    if isempty(str_text)
        return
    end

    cell_lines = regexp(regexprep(str_text, '\r\n?', '\n'), '\n', 'split');
    str_pattern = ['^\s*', regexptranslate('escape', str_property_name), '\b'];

    idx_property = find(~cellfun(@isempty, regexp(cell_lines, str_pattern, 'once')), 1, 'first');
    if isempty(idx_property)
        return
    end

    cell_comment = {};
    i = idx_property - 1;
    while i >= 1
        str_line = cell_lines{i};
        if ~isempty(regexp(str_line, '^\s*%.*$', 'once'))
            cell_comment = [{str_line}; cell_comment]; %#ok<AGROW>
            i = i - 1;
            continue
        end
        if isempty(strtrim(str_line)) && ~isempty(cell_comment)
            cell_comment = [{str_line}; cell_comment]; %#ok<AGROW>
            i = i - 1;
            continue
        end
        break
    end

    if isempty(cell_comment)
        return
    end

    str_help = normalize_comment_lines(cell_comment);
end

function str_help = collect_following_comment_lines(cell_lines, idx_start)
    cell_comment = {};
    i = idx_start;
    while i <= numel(cell_lines)
        str_line = cell_lines{i};
        if ~isempty(regexp(str_line, '^\s*%.*$', 'once'))
            cell_comment{end+1,1} = str_line; %#ok<AGROW>
            i = i + 1;
            continue
        end
        if isempty(strtrim(str_line)) && ~isempty(cell_comment)
            cell_comment{end+1,1} = str_line; %#ok<AGROW>
            i = i + 1;
            continue
        end
        break
    end

    str_help = normalize_comment_lines(cell_comment);
end

function str_text = read_text_file(str_file_path)
    str_text = '';
    if isempty(str_file_path) || ~exist(str_file_path, 'file')
        return
    end
    try
        str_text = fileread(str_file_path);
    catch
        str_text = '';
    end
end

function str_help = normalize_comment_lines(cell_comment)
    str_help = '';
    if isempty(cell_comment)
        return
    end

    for i = 1:numel(cell_comment)
        cell_comment{i} = regexprep(cell_comment{i}, '^\s*%\s?', '');
    end

    while ~isempty(cell_comment) && isempty(strtrim(cell_comment{1}))
        cell_comment(1) = [];
    end
    while ~isempty(cell_comment) && isempty(strtrim(cell_comment{end}))
        cell_comment(end) = [];
    end

    if isempty(cell_comment)
        return
    end

    str_help = sanitize_help_text(strjoin(cell_comment, newline));
end

function str_clean_help = sanitize_help_text(str_raw_help)
    str_clean_help = regexprep(char(string(str_raw_help)), '\r\n?', '\n');

    cell_inherited_help_patterns = {
        '^.*についてのヘルプはスーパークラス .* から継承されます$'
        '^.*のヘルプはスーパークラス .* から継承されます$'
        '^Help for .* is inherited from superclass .*$'
        '^.* help is inherited from superclass .*$'
    };

    cell_lines = regexp(str_clean_help, '\n', 'split');
    cell_keep = true(size(cell_lines));
    for i_line = 1:numel(cell_lines)
        str_line = strtrim(cell_lines{i_line});
        if isempty(str_line)
            continue;
        end

        bln_is_inherited_help = any(cellfun(@(str_pattern) ...
            ~isempty(regexp(str_line, str_pattern, 'once')), cell_inherited_help_patterns));

        if bln_is_inherited_help
            cell_keep(i_line) = false;
        end
    end

    cell_lines = cell_lines(cell_keep);
    cell_lines = cellfun(@(s) regexprep(s, '^\s+', ''), cell_lines, 'UniformOutput', false);

    while ~isempty(cell_lines) && isempty(strtrim(cell_lines{1}))
        cell_lines(1) = [];
    end
    while ~isempty(cell_lines) && isempty(strtrim(cell_lines{end}))
        cell_lines(end) = [];
    end

    str_clean_help = strjoin(cell_lines, newline);
end

function sct_info = apply_help_tags(sct_info, str_raw_help, cell_tags)
    sct_parsed_tags = parse_tagged_help(str_raw_help);
    for i_tag = 1:numel(cell_tags)
        str_tag_name = cell_tags{i_tag};
        [bln_found, str_source_tag] = resolve_tag_alias(sct_parsed_tags, str_tag_name);
        if bln_found
            sct_info.(str_tag_name) = parse_tag_value(str_tag_name, sct_parsed_tags.(str_source_tag));
        else
            sct_info.(str_tag_name) = get_default_tag_value(str_tag_name);
        end
    end
end

function [bln_found, str_source_tag] = resolve_tag_alias(sct_parsed_tags, str_tag_name)
    cell_candidates = {str_tag_name};
    switch str_tag_name
        case 'Parameters'
            cell_candidates = {'Parameters', 'varargin'};
        case 'Returns'
            cell_candidates = {'Returns', 'varargout'};
        case 'Abst'
            cell_candidates = {'Abst'};
    end

    bln_found = false;
    str_source_tag = '';
    for i = 1:numel(cell_candidates)
        str_candidate = cell_candidates{i};
        if isfield(sct_parsed_tags, str_candidate)
            bln_found = true;
            str_source_tag = str_candidate;
            return
        end
    end
end

function sct_tag_data = parse_tagged_help(rawHelp)
    str_help_text = char(string(rawHelp));
    str_help_text = regexprep(str_help_text, '\r\n?', '\n');

    % Strict tag: <@TagName> (no whitespace allowed inside brackets)
    str_tag_pattern = '<@([A-Za-z][A-Za-z0-9_]*)>';
    [cell_tag_tokens, iv_tag_starts, iv_tag_ends] = regexp(str_help_text, str_tag_pattern, 'tokens', 'start', 'end');

    sct_tag_data = struct();
    if isempty(iv_tag_starts)
        return
    end

    for i_tag = 1:numel(iv_tag_starts)
        str_tag_name   = cell_tag_tokens{i_tag}{1};
        i_value_start = iv_tag_ends(i_tag) + 1;
        if i_tag < numel(iv_tag_starts)
            i_value_end = iv_tag_starts(i_tag + 1) - 1;
        else
            i_value_end = length(str_help_text);
        end

        if i_value_start <= i_value_end
            str_raw_value = str_help_text(i_value_start:i_value_end);
        else
            str_raw_value = '';
        end

        cell_lines = regexp(str_raw_value, '\n', 'split');
        for i_line = 1:numel(cell_lines)
            cell_lines{i_line} = regexprep(cell_lines{i_line}, '^\s+', '');
        end

        while ~isempty(cell_lines) && isempty(cell_lines{1})
            cell_lines(1) = [];
        end

        while ~isempty(cell_lines) && isempty(cell_lines{end})
            cell_lines(end) = [];
        end

        str_normalized_value = strjoin(cell_lines, '\n');
        sct_tag_data.(str_tag_name) = str_normalized_value;
    end
end

function out = get_default_tag_value(str_tag_name)
    switch str_tag_name
        case {'Signatures', 'Examples'}
            out = {};
        case {'Parameters'}
            out = struct('Name', {}, 'Type', {}, 'Description', {}, 'Required', {}, 'Default', {});
        case {'Returns'}
            out = struct('Name', {}, 'Type', {}, 'Description', {});
        otherwise
            out = '';
    end
end

function out = parse_tag_value(str_tag_name, str_raw_value)
    switch str_tag_name
        case {'Signatures', 'Examples'}
            out = parse_json_string_list(str_raw_value);
        case 'Parameters'
            out = parse_json_parameters(str_raw_value);
        case 'Returns'
            out = parse_json_returns(str_raw_value);
        otherwise
            out = char(string(str_raw_value));
    end
end

function out = parse_json_string_list(str_raw_value)
    val_json = try_jsondecode(str_raw_value);
    if isempty(val_json)
        out = {};
        return
    end
    if isstring(val_json)
        out = cellstr(val_json(:));
        return
    end
    if ischar(val_json)
        out = {val_json};
        return
    end
    if iscell(val_json)
        out = cellfun(@(x) char(string(x)), val_json, 'UniformOutput', false);
    else
        out = {};
    end
end

function out = parse_json_parameters(str_raw_value)
    val_json = try_jsondecode(str_raw_value);
    if isempty(val_json) || ~isstruct(val_json)
        out = struct('Name', {}, 'Type', {}, 'Description', {}, 'Required', {}, 'Default', {});
        return
    end

    out = normalize_parameter_struct_array(val_json);
end

function out = parse_json_returns(str_raw_value)
    val_json = try_jsondecode(str_raw_value);
    if isempty(val_json) || ~isstruct(val_json)
        out = struct('Name', {}, 'Type', {}, 'Description', {});
        return
    end

    out = normalize_return_struct_array(val_json);
end

function val = try_jsondecode(str_raw_value)
    val = [];
    str_text = strtrim(char(string(str_raw_value)));
    if isempty(str_text)
        return
    end
    if ~(startsWith(str_text, '[') || startsWith(str_text, '{'))
        return
    end
    try
        val = jsondecode(str_text);
    catch
        val = [];
    end
end

function out = normalize_parameter_struct_array(val)
    if ~isstruct(val)
        out = struct('Name', {}, 'Type', {}, 'Description', {}, 'Required', {}, 'Default', {});
        return
    end
    val = val(:);
    out = repmat(struct('Name', '', 'Type', '', 'Description', '', 'Required', '', 'Default', ''), numel(val), 1);
    for i = 1:numel(val)
        out(i).Name = get_struct_field_str(val(i), {'Name','name'});
        out(i).Type = get_struct_field_str(val(i), {'Type','type','Class','class'});
        out(i).Description = get_struct_field_str(val(i), {'Description','description','Desc','desc'});
        req = get_struct_field(val(i), {'Required','required'});
        if isempty(req)
            out(i).Required = '';
        else
            out(i).Required = req;
        end
        out(i).Default = get_struct_field_str(val(i), {'Default','default'});
    end
end

function out = normalize_return_struct_array(val)
    if ~isstruct(val)
        out = struct('Name', {}, 'Type', {}, 'Description', {});
        return
    end
    val = val(:);
    out = repmat(struct('Name', '', 'Type', '', 'Description', ''), numel(val), 1);
    for i = 1:numel(val)
        out(i).Name = get_struct_field_str(val(i), {'Name','name'});
        out(i).Type = get_struct_field_str(val(i), {'Type','type','Class','class'});
        out(i).Description = get_struct_field_str(val(i), {'Description','description','Desc','desc'});
    end
end

function out = get_struct_field(s, candidates)
    out = [];
    names = fieldnames(s);
    for i = 1:numel(candidates)
        idx = find(strcmpi(names, candidates{i}), 1, 'first');
        if ~isempty(idx)
            out = s.(names{idx});
            return
        end
    end
end

function out = get_struct_field_str(s, candidates)
    v = get_struct_field(s, candidates);
    if isempty(v)
        out = '';
    else
        out = char(string(v));
    end
end
