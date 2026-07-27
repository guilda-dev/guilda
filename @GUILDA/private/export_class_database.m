function sct_summary = export_class_database(str_class_list, option)
    arguments
        str_class_list
        option.strict (1,1) logical = false
    end
    str_class_list = string(str_class_list);
    
    n_class = numel(str_class_list);
    
    disp(" ")
    disp(" === Update Documentation Database === ")
    disp("  Exporting class database for '_GUILDAdoc/database' ...")

    if ~isfolder("_GUILDAdoc/database")
        mkdir _GUILDAdoc/database
    end
    if ~isfolder("_GUILDAdoc/database/GUILDAsystem")
        mkdir _GUILDAdoc/database/GUILDAsystem
    end
    if ~isfolder("_GUILDAdoc/database/GUILDAobject")
        mkdir _GUILDAdoc/database/GUILDAobject
    end

    rv_character = strlength(str_class_list);
    r_indent = max(rv_character) + 2;
    sct_class_info = struct([]);
    sct_validation = repmat(struct('ClassName', '', 'Warnings', {{}}, 'Errors', {{}}), 0, 1);
    for i_class = 1:n_class
        str_class_i = str_class_list(i_class);
        str_class_char = char(str_class_i);
        str_indent = repmat(' ', 1, r_indent - length(str_class_char));

        fprintf("  export("+num2str(i_class, '%.3d') + "/" + num2str(n_class, '%.0f') + "): " + str_class_i + str_indent + " ... ")
        try
            [sct_info_i, sct_validation_i] = export_class_doc(str_class_char);
            sct_class_info = [sct_class_info, sct_info_i]; %#ok<AGROW>
            sct_validation(end+1,1) = sct_validation_i; %#ok<AGROW>
            n_warning_i = numel(sct_validation_i.Warnings);
            n_error_i   = numel(sct_validation_i.Errors);
            if n_warning_i == 0 && n_error_i == 0
                disp("ok")
            else
                fprintf("ok (%d warning(s), %d error(s))\n", n_warning_i, n_error_i)
                if option.strict
                    cellfun(@(msg) fprintf("    warning: %s\n", msg), sct_validation_i.Warnings);
                end
                cellfun(@(msg) fprintf("    error: %s\n", msg), sct_validation_i.Errors);
            end
        catch ME
            disp("failed")
            str_report = getReport(ME, 'extended', 'hyperlinks', 'off');
            fprintf("%s\n", str_report)
            sct_validation(end+1,1) = struct( ...
                'ClassName', str_class_char, ...
                'Warnings', {{}}, ...
                'Errors', {{sprintf('Class export failed: %s', ME.message)}} ...
            ); %#ok<AGROW>
        end
    end

    if isempty(sct_class_info)
        warning('export_class_database:NoClassExported', 'No class documentation was exported.');
    end

    str_GUILDApath = GUILDA.pwd();
    str_file_name  = fullfile(str_GUILDApath, '_GUILDAdoc', 'database', 'list_Classes.js');
    sct_schema = struct( ...
        'name',                 'GUILDA documentation class index', ...
        'version',              2, ...
        'classDocumentVersion', 2, ...
        'pathBase',             '_GUILDAdoc' ...
    );
    sct_schema.modelCategories = { ...
        'PowerNetwork', 'Bus', 'Branch', 'Component', 'LocalController', 'GlobalController' ...
    };
    sct_schema.coreClasses = sct_schema.modelCategories;
    sct_schema.tags = get_tag_schema();
    sct_schema.legacyAliases = struct( ...
        'Abst', 'Summary', ...
        'varargin', 'Parameters', ...
        'varargout', 'Returns', ...
        'DetailsCode', 'Notes' ...
    );
    sct_database         = struct();
    sct_database.schema  = sct_schema;
    sct_database.classes = sct_class_info;
    sct_database.validation = struct();
    sct_database.validation.warningCount = sum(arrayfun(@(v) numel(v.Warnings), sct_validation));
    sct_database.validation.errorCount   = sum(arrayfun(@(v) numel(v.Errors), sct_validation));
    sct_database.validation.classes      = sct_validation;
    str_json             = jsonencode(sct_database, 'PrettyPrint', true);
    str_js_content       = sprintf([ ...
        'window.GUILDA_DOC_INDEX = %s;\n', ...
        'window.classListData = window.GUILDA_DOC_INDEX.classes;\n', ...
        'const class_list = window.classListData;\n' ...
    ], str_json);
    
    % Overwrite output file.
    file_id       = fopen(str_file_name, 'w', 'n', 'UTF-8');
    if file_id < 0
        error('export_class_database:FileOpenFailed', 'Failed to open output file: %s', str_file_name);
    end
    fprintf(file_id, '%s', str_js_content);
    fclose(file_id);

    sct_summary = struct( ...
        'ClassCount',   numel(sct_class_info), ...
        'WarningCount', sct_database.validation.warningCount, ...
        'ErrorCount',   sct_database.validation.errorCount ...
    );
    if option.strict && sct_summary.ErrorCount > 0
        error('export_class_database:ValidationFailed', ...
            'Documentation validation failed with %d error(s).', sct_summary.ErrorCount);
    end
end



function [sct_info, sct_validation] = export_class_doc(str_class_name)
    % This method uses MATLAB's reflection capabilities to extract metadata from the class properties and methods.
    % It also reads custom tags defined in the help comments.
    % The extracted information is saved as a JavaScript file for the GUILDA documentation database.
    meta_class       = meta.class.fromName(str_class_name);
    
    cell_prop_tags   = { ...
        'Summary', 'Desc', 'Role', 'Type', 'Size', 'Unit', 'Default', ...
        'Constraints', 'Notes', 'SeeAlso', 'Since', 'Deprecated' ...
    };
    cell_method_tags = {
        'Summary', 'Desc', 'Role', 'Signatures', 'Parameters', 'Returns', ...
        'Examples', 'Notes', 'Throws', 'SeeAlso', 'Since', 'Deprecated'
    };
    cell_class_tags  = { ...
        'Summary', 'Desc', 'Role', 'Constructor', 'Notes', ...
        'SeeAlso', 'Since', 'Deprecated' ...
    };

    sct_doc_data            = struct( ...
        'schema', struct('name', 'GUILDA class document', 'version', 2), ...
        'ClassName', str_class_name, ...
        'properties', [], ...
        'methods', [], ...
        'validation', struct('Warnings', {{}}, 'Errors', {{}}) ...
    );
    [sct_doc_data.properties, cell_prop_diagnostics] = build_meta_section(meta_class.PropertyList, str_class_name, cell_prop_tags, "property");
    [sct_doc_data.methods, cell_method_diagnostics]  = build_meta_section(meta_class.MethodList, str_class_name, cell_method_tags, "method");
    [sct_info, cell_class_diagnostics]               = build_class_info(str_class_name, meta_class, cell_class_tags);
    cell_diagnostics = [cell_class_diagnostics; cell_prop_diagnostics; cell_method_diagnostics];
    cell_warnings = cell_diagnostics(startsWith(cell_diagnostics, 'WARNING:'));
    cell_errors   = cell_diagnostics(startsWith(cell_diagnostics, 'ERROR:'));
    cell_warnings = erase(cell_warnings, 'WARNING: ');
    cell_errors   = erase(cell_errors, 'ERROR: ');
    sct_doc_data.validation = struct('Warnings', {cell_warnings}, 'Errors', {cell_errors});
    sct_validation = struct('ClassName', str_class_name, 'Warnings', {cell_warnings}, 'Errors', {cell_errors});

    % Output JS file
    str_filepath   = which(str_class_name);
    str_GUILDApath = GUILDA.pwd;
    if contains(str_filepath, fullfile(str_GUILDApath, '_GUILDAsystem'))
        str_database_folder = 'GUILDAsystem';
        str_file_name = fullfile(str_GUILDApath, '_GUILDAdoc', 'database', 'GUILDAsystem', [str_class_name, '.js']);
    else
        str_database_folder = 'GUILDAobject';
        str_file_name = fullfile(str_GUILDApath, '_GUILDAdoc', 'database', 'GUILDAobject', [str_class_name, '.js']);
    end
    sct_info.path  = strrep(fullfile('.', 'database', str_database_folder, [str_class_name, '.js']), '\\', '/');
    str_json       = jsonencode(sct_doc_data, 'PrettyPrint', true);
    str_class_key  = jsonencode(str_class_name);
    str_js_content = sprintf([ ...
        '(function (root) {\n', ...
        '  const data = %s;\n', ...
        '  root.GUILDA_DOC_CLASSES = root.GUILDA_DOC_CLASSES || {};\n', ...
        '  root.GUILDA_DOC_CLASSES[%s] = data;\n', ...
        '  root.classData = data;\n', ...
        '})(window);\n' ...
    ], str_json, str_class_key);
    file_id        = fopen(str_file_name, 'w', 'n', 'UTF-8');
    if file_id < 0
        error('export_class_database:FileOpenFailed', 'Failed to open output file: %s', str_file_name);
    end
    fprintf(file_id, '%s', str_js_content);
    fclose(file_id);
end

function [sct_section, cell_diagnostics] = build_meta_section(meta_list, str_class_name, cell_tags, str_kind)
    sct_section = struct([]);
    cell_diagnostics = cell(0,1);
    for i_item = 1:numel(meta_list)
        if iscell(meta_list)
            meta_item = meta_list{i_item};
        else
            meta_item = meta_list(i_item);
        end
        if ~strcmp(meta_item.DefiningClass.Name,'handle') && ~strcmp(meta_item.Name,'empty')
            [sct_info_i, cell_diagnostics_i] = build_meta_info(meta_item, str_class_name, cell_tags, str_kind);
            sct_section = [sct_section, sct_info_i]; %#ok<AGROW>
            cell_diagnostics = [cell_diagnostics; cell_diagnostics_i]; %#ok<AGROW>
        end
    end
end

function [sct_info, cell_diagnostics] = build_meta_info(meta_item, str_class_name, cell_tags, str_kind)
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
    str_context = char(str_class_name + "." + string(meta_item.Name));
    [sct_info, cell_diagnostics] = apply_help_tags(sct_info, str_raw_help, cell_tags, str_kind, str_context);
    if str_kind == "method" && strcmp(meta_item.DefiningClass.Name, str_class_name) ...
            && is_public_access(sct_info.Access) && ~sct_info.Hidden ...
            && isempty(strtrim(sct_info.Summary)) && isempty(strtrim(sct_info.Desc))
        cell_diagnostics{end+1,1} = sprintf('WARNING: %s: public method has no Summary or Desc.', str_context);
    end
end

function str_access = organize_access(dat)
    if isa(dat,"char") || isa(dat,"string")
        str_access = char(dat);
        return
    end

    if iscell(dat)
        cell_access = cellfun(@organize_access, dat, 'UniformOutput', false);
        cell_access = cell_access(~cellfun(@isempty, cell_access));
        str_access = strjoin(cell_access, ', ');
    elseif isscalar(dat)
        str_access = dat.Name;
    else
        cell_access = arrayfun(@(d) organize_access(d), dat, 'UniformOutput', false);
        str_access = strjoin(cell_access, ', ');
    end
end

function [sct_info, cell_diagnostics] = build_class_info(str_class_name, meta_class, cell_tags)
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
    [sct_info, cell_diagnostics] = apply_help_tags(sct_info, str_help, cell_tags, "class", str_class_name);
    if isempty(strtrim(sct_info.Summary)) && isempty(strtrim(sct_info.Desc))
        cell_diagnostics{end+1,1} = sprintf('WARNING: %s: class has no Summary or Desc.', str_class_name);
    end
end

function str_help = get_class_help_text(str_class_name)
    % Parse the source first so that indentation and text-art alignment are
    % not changed by MATLAB's help renderer.
    str_class_path = which(str_class_name);
    str_help = extract_class_comment_block(str_class_path);
    if ~isempty(strtrim(str_help))
        return
    end

    str_help = sanitize_help_text(try_help(str_class_name));
end

function str_help = get_member_help_text(str_class_name, meta_item, str_kind)
    str_help = '';
    str_member_name = string(meta_item.Name);

    % Parse source files first to preserve intentional whitespace.
    str_class_path = which(str_class_name);
    if str_kind == "method"
        str_method_path = fullfile(fileparts(str_class_path), char(str_member_name + ".m"));
        str_help = extract_function_comment_block(str_method_path);
    elseif str_kind == "property"
        str_help = extract_property_comment_block(str_class_path, char(str_member_name));
    end
    if ~isempty(strtrim(str_help))
        return
    end

    % Fallback to MATLAB's help system when source comments are unavailable.
    str_help = sanitize_help_text(try_help(str_class_name + "." + str_member_name));
end

function str_help = try_help(str_symbol)
    str_help = ''; %#ok<NASGU>
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

    while ~isempty(cell_lines) && isempty(strtrim(cell_lines{1}))
        cell_lines(1) = [];
    end
    while ~isempty(cell_lines) && isempty(strtrim(cell_lines{end}))
        cell_lines(end) = [];
    end

    str_clean_help = strjoin(cell_lines, newline);
end

function [sct_info, cell_diagnostics] = apply_help_tags(sct_info, str_raw_help, cell_tags, str_kind, str_context)
    [sct_parsed_tags, cell_source_tags] = parse_tagged_help(str_raw_help);
    cell_diagnostics = cell(0,1);

    cell_allowed_tags = get_allowed_source_tags(cell_tags);
    cell_unknown_tags = setdiff(unique(cell_source_tags, 'stable'), cell_allowed_tags, 'stable');
    for i_tag = 1:numel(cell_unknown_tags)
        cell_diagnostics{end+1,1} = sprintf( ...
            'WARNING: %s: unknown %s tag <@%s>.', ...
            str_context, str_kind, cell_unknown_tags{i_tag}); %#ok<AGROW>
    end

    cell_unique_tags = unique(cell_source_tags, 'stable');
    for i_tag = 1:numel(cell_unique_tags)
        if sum(strcmp(cell_source_tags, cell_unique_tags{i_tag})) > 1
            cell_diagnostics{end+1,1} = sprintf( ...
                'WARNING: %s: duplicate tag <@%s>; the last value is used.', ...
                str_context, cell_unique_tags{i_tag}); %#ok<AGROW>
        end
    end

    for i_tag = 1:numel(cell_tags)
        str_tag_name = cell_tags{i_tag};
        [bln_found, str_source_tag] = resolve_tag_alias(sct_parsed_tags, str_tag_name);
        if bln_found
            [sct_info.(str_tag_name), str_error] = parse_tag_value(str_tag_name, sct_parsed_tags.(str_source_tag));
            if ~isempty(str_error)
                cell_diagnostics{end+1,1} = sprintf( ...
                    'ERROR: %s: invalid <@%s> value: %s', ...
                    str_context, str_source_tag, str_error); %#ok<AGROW>
            end
        else
            sct_info.(str_tag_name) = get_default_tag_value(str_tag_name);
        end
    end
end

function [bln_found, str_source_tag] = resolve_tag_alias(sct_parsed_tags, str_tag_name)
    cell_candidates = {str_tag_name};
    switch str_tag_name
        case 'Summary'
            cell_candidates = {'Summary', 'Abst'};
        case 'Desc'
            cell_candidates = {'Desc', 'Description'};
        case 'Parameters'
            cell_candidates = {'Parameters', 'varargin'};
        case 'Returns'
            cell_candidates = {'Returns', 'varargout'};
        case 'Notes'
            cell_candidates = {'Notes', 'DetailsCode'};
        case 'Examples'
            cell_candidates = {'Examples', 'Example'};
        case 'SeeAlso'
            cell_candidates = {'SeeAlso', 'Seealso'};
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

function cell_allowed_tags = get_allowed_source_tags(cell_canonical_tags)
    cell_allowed_tags = cell(0,1);
    for i_tag = 1:numel(cell_canonical_tags)
        str_tag_name = cell_canonical_tags{i_tag};
        switch str_tag_name
            case 'Summary';    cell_aliases = {'Summary', 'Abst'};
            case 'Desc';       cell_aliases = {'Desc', 'Description'};
            case 'Parameters'; cell_aliases = {'Parameters', 'varargin'};
            case 'Returns';    cell_aliases = {'Returns', 'varargout'};
            case 'Notes';      cell_aliases = {'Notes', 'DetailsCode'};
            case 'Examples';   cell_aliases = {'Examples', 'Example'};
            case 'SeeAlso';    cell_aliases = {'SeeAlso', 'Seealso'};
            otherwise;        cell_aliases = {str_tag_name};
        end
        cell_allowed_tags = [cell_allowed_tags; cell_aliases(:)]; %#ok<AGROW>
    end
    sct_all_tags = get_tag_schema();
    cell_all_canonical = [sct_all_tags.class(:); sct_all_tags.property(:); sct_all_tags.method(:)];
    cell_all_aliases = {'Abst'; 'Description'; 'varargin'; 'varargout'; 'DetailsCode'; 'Example'; 'Seealso'};
    cell_allowed_tags = [cell_allowed_tags; cell_all_canonical; cell_all_aliases];
    cell_allowed_tags = unique(cell_allowed_tags, 'stable');
end

function [sct_tag_data, cell_tag_names] = parse_tagged_help(rawHelp)
    str_help_text = char(string(rawHelp));
    str_help_text = regexprep(str_help_text, '\r\n?', '\n');

    % Strict tag: <@TagName> (no whitespace allowed inside brackets)
    str_tag_pattern = '<@([A-Za-z][A-Za-z0-9_]*)>';
    [cell_tag_tokens, iv_tag_starts, iv_tag_ends] = regexp(str_help_text, str_tag_pattern, 'tokens', 'start', 'end');

    sct_tag_data = struct();
    cell_tag_names = cellfun(@(token) token{1}, cell_tag_tokens, 'UniformOutput', false);
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

        while ~isempty(cell_lines) && isempty(strtrim(cell_lines{1}))
            cell_lines(1) = [];
        end

        while ~isempty(cell_lines) && isempty(strtrim(cell_lines{end}))
            cell_lines(end) = [];
        end

        % Remove only the separator after an inline tag. Do not left-trim
        % every line: leading spaces can be meaningful in tables and diagrams.
        if ~isempty(cell_lines)
            cell_lines{1} = regexprep(cell_lines{1}, '^ ', '', 'once');
        end

        str_normalized_value = strjoin(cell_lines, '\n');
        sct_tag_data.(str_tag_name) = str_normalized_value;
    end
end

function out = get_default_tag_value(str_tag_name)
    switch str_tag_name
        case {'Signatures', 'Examples', 'SeeAlso'}
            out = {};
        case {'Parameters'}
            out = empty_parameter_struct();
        case {'Returns'}
            out = empty_return_struct();
        otherwise
            out = '';
    end
end

function [out, str_error] = parse_tag_value(str_tag_name, str_raw_value)
    str_error = '';
    switch str_tag_name
        case {'Signatures', 'Examples', 'SeeAlso'}
            [out, str_error] = parse_json_string_list(str_raw_value);
        case 'Parameters'
            [out, str_error] = parse_json_parameters(str_raw_value);
        case 'Returns'
            [out, str_error] = parse_json_returns(str_raw_value);
        otherwise
            out = char(string(str_raw_value));
    end
end

function [out, str_error] = parse_json_string_list(str_raw_value)
    [val_json, str_error] = try_jsondecode(str_raw_value);
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
        str_error = 'expected a JSON string or array of strings.';
    end
end

function [out, str_error] = parse_json_parameters(str_raw_value)
    [val_json, str_error] = try_jsondecode(str_raw_value);
    if isempty(val_json)
        out = empty_parameter_struct();
        return
    end
    if ~isstruct(val_json)
        out = empty_parameter_struct();
        str_error = 'expected a JSON object or array of parameter objects.';
        return
    end

    out = normalize_parameter_struct_array(val_json);
end

function [out, str_error] = parse_json_returns(str_raw_value)
    [val_json, str_error] = try_jsondecode(str_raw_value);
    if isempty(val_json)
        out = empty_return_struct();
        return
    end
    if ~isstruct(val_json)
        out = empty_return_struct();
        str_error = 'expected a JSON object or array of return-value objects.';
        return
    end

    out = normalize_return_struct_array(val_json);
end

function [val, str_error] = try_jsondecode(str_raw_value)
    val = [];
    str_error = '';
    str_text = strtrim(char(string(str_raw_value)));
    if isempty(str_text)
        return
    end
    if ~(startsWith(str_text, '[') || startsWith(str_text, '{'))
        str_error = 'structured tags must contain JSON beginning with [ or {.';
        return
    end
    try
        val = jsondecode(str_text);
    catch ME
        val = [];
        str_error = ME.message;
    end
end

function out = normalize_parameter_struct_array(val)
    if ~isstruct(val)
        out = empty_parameter_struct();
        return
    end
    val = val(:);
    out = repmat(struct( ...
        'Name', '', 'Kind', '', 'Type', '', 'Unit', '', 'Description', '', ...
        'Required', '', 'Default', '', 'Constraints', '' ...
    ), numel(val), 1);
    for i = 1:numel(val)
        out(i).Name = get_struct_field_str(val(i), {'Name','name'});
        out(i).Kind = get_struct_field_str(val(i), {'Kind','kind'});
        out(i).Type = get_struct_field_str(val(i), {'Type','type','Class','class'});
        out(i).Unit = get_struct_field_str(val(i), {'Unit','unit'});
        out(i).Description = get_struct_field_str(val(i), {'Description','description','Desc','desc'});
        req = get_struct_field(val(i), {'Required','required'});
        if isempty(req)
            out(i).Required = '';
        else
            out(i).Required = req;
        end
        out(i).Default = get_struct_field_str(val(i), {'Default','default'});
        out(i).Constraints = get_struct_field_str(val(i), {'Constraints','constraints','Range','range'});
    end
end

function out = normalize_return_struct_array(val)
    if ~isstruct(val)
        out = empty_return_struct();
        return
    end
    val = val(:);
    out = repmat(struct('Name', '', 'Type', '', 'Unit', '', 'Description', ''), numel(val), 1);
    for i = 1:numel(val)
        out(i).Name = get_struct_field_str(val(i), {'Name','name'});
        out(i).Type = get_struct_field_str(val(i), {'Type','type','Class','class'});
        out(i).Unit = get_struct_field_str(val(i), {'Unit','unit'});
        out(i).Description = get_struct_field_str(val(i), {'Description','description','Desc','desc'});
    end
end

function out = empty_parameter_struct()
    out = struct( ...
        'Name', {}, 'Kind', {}, 'Type', {}, 'Unit', {}, 'Description', {}, ...
        'Required', {}, 'Default', {}, 'Constraints', {} ...
    );
end

function out = empty_return_struct()
    out = struct('Name', {}, 'Type', {}, 'Unit', {}, 'Description', {});
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

function sct_schema = get_tag_schema()
    sct_schema = struct();
    sct_schema.class = { ...
        'Summary', 'Desc', 'Role', 'Constructor', 'Notes', ...
        'SeeAlso', 'Since', 'Deprecated' ...
    };
    sct_schema.property = { ...
        'Summary', 'Desc', 'Role', 'Type', 'Size', 'Unit', 'Default', ...
        'Constraints', 'Notes', 'SeeAlso', 'Since', 'Deprecated' ...
    };
    sct_schema.method = { ...
        'Summary', 'Desc', 'Role', 'Signatures', 'Parameters', 'Returns', ...
        'Examples', 'Notes', 'Throws', 'SeeAlso', 'Since', 'Deprecated' ...
    };
    sct_schema.structured = {'Signatures', 'Parameters', 'Returns', 'Examples', 'SeeAlso'};
end

function bln_public = is_public_access(str_access)
    str_access = lower(strtrim(char(string(str_access))));
    bln_public = strcmp(str_access, 'public') || isempty(str_access);
end
