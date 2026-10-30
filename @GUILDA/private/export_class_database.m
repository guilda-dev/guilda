function sct_summary = export_class_database(sct_classes, option)
% Export the class reference database read by _GUILDAdoc/class.html and method.html.
%
% sct_classes : struct array with fields Name and File (see find_doc_classes),
%               or a string array of class names.
% Output files (generated, not tracked by git):
%   _GUILDAdoc/database/list_Classes.js               class index
%   _GUILDAdoc/database/GUILDAsystem|GUILDAobject/*.js one file per class
    arguments
        sct_classes
        option.strict (1,1) logical = false
    end
    sct_classes = normalize_class_list(sct_classes);
    n_class = numel(sct_classes);

    str_GUILDApath = GUILDA.pwd();
    str_db_path    = fullfile(str_GUILDApath, '_GUILDAdoc', 'database');

    disp(" ")
    disp(" === Update Documentation Database === ")
    disp("  Exporting class database for '_GUILDAdoc/database' ...")

    % Remove class files of the previous export so that deleted or renamed
    % classes do not remain in the database.
    for str_folder = ["GUILDAsystem", "GUILDAobject"]
        str_folder_path = fullfile(str_db_path, str_folder);
        if isfolder(str_folder_path)
            rmdir(str_folder_path, 's');
        end
        mkdir(str_folder_path);
    end

    sct_ctx = struct();
    sct_ctx.root    = str_GUILDApath;
    sct_ctx.files   = containers.Map({sct_classes.Name}, {sct_classes.File});
    sct_ctx.sources = containers.Map('KeyType', 'char', 'ValueType', 'any');
    sct_ctx.strict  = option.strict;

    r_indent = max(strlength(string({sct_classes.Name}))) + 2;
    cell_class_info = cell(1, 0);
    sct_validation  = repmat(struct('ClassName', '', 'Warnings', {{}}, 'Errors', {{}}), 0, 1);
    sct_coverage    = struct('Classes', [0 0], 'Properties', [0 0], 'Methods', [0 0]);
    for i_class = 1:n_class
        str_class_char = sct_classes(i_class).Name;
        str_indent = repmat(' ', 1, r_indent - length(str_class_char));

        fprintf("  export(%.3d/%d): %s%s ... ", i_class, n_class, str_class_char, str_indent)
        try
            [sct_info_i, sct_validation_i, sct_coverage_i] = export_class_doc(str_class_char, sct_ctx);
            cell_class_info{end+1} = sct_info_i; %#ok<AGROW>
            sct_validation(end+1,1) = sct_validation_i; %#ok<AGROW>
            for str_field = ["Classes", "Properties", "Methods"]
                sct_coverage.(str_field) = sct_coverage.(str_field) + sct_coverage_i.(str_field);
            end
            n_warning_i = numel(sct_validation_i.Warnings);
            n_error_i   = numel(sct_validation_i.Errors);
            if n_warning_i == 0 && n_error_i == 0
                disp("ok")
            else
                fprintf("ok (%d warning(s), %d error(s))\n", n_warning_i, n_error_i)
                if option.strict
                    cellfun(@(msg) fprintf("    warning: %s\n", msg), sct_validation_i.Warnings);
                else
                    % Removed tag names are shown even without "strict".
                    cellfun(@(msg) fprintf("    warning: %s\n", msg), ...
                        sct_validation_i.Warnings(contains(sct_validation_i.Warnings, 'is no longer supported')));
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

    if isempty(cell_class_info)
        warning('export_class_database:NoClassExported', 'No class documentation was exported.');
    end

    str_file_name  = fullfile(str_db_path, 'list_Classes.js');
    sct_schema = struct( ...
        'name',                 'GUILDA documentation class index', ...
        'version',              4, ...
        'classDocumentVersion', 4, ...
        'pathBase',             '_GUILDAdoc' ...
    );
    sct_schema.generatedAt = char(datetime('now', 'TimeZone', 'local', 'Format', 'yyyy-MM-dd''T''HH:mm:ssXXX'));
    sct_schema.matlabRelease = version('-release');
    sct_schema.modelCategories = get_model_categories(cell_class_info);
    sct_schema.coreClasses = sct_schema.modelCategories;
    sct_schema.tags = get_tag_schema();
    sct_database         = struct();
    sct_database.schema  = sct_schema;
    sct_database.classes = cell_class_info;
    sct_database.coverage = struct( ...
        'Classes',    coverage_entry(sct_coverage.Classes), ...
        'Properties', coverage_entry(sct_coverage.Properties), ...
        'Methods',    coverage_entry(sct_coverage.Methods) ...
    );
    sct_database.validation = struct();
    sct_database.validation.warningCount = sum(arrayfun(@(v) numel(v.Warnings), sct_validation));
    sct_database.validation.errorCount   = sum(arrayfun(@(v) numel(v.Errors), sct_validation));
    sct_database.validation.classes      = num2cell(sct_validation);
    str_json       = jsonencode(sct_database, 'PrettyPrint', true);
    str_js_content = sprintf('window.GUILDA_DOC_INDEX = %s;\n', str_json);

    write_text_file(str_file_name, str_js_content);

    sct_summary = struct( ...
        'ClassCount',   numel(cell_class_info), ...
        'WarningCount', sct_database.validation.warningCount, ...
        'ErrorCount',   sct_database.validation.errorCount, ...
        'Coverage',     sct_database.coverage ...
    );
    fprintf("  %d classes, %d warning(s), %d error(s). Documented: classes %d/%d, public methods %d/%d, public properties %d/%d.\n", ...
        sct_summary.ClassCount, sct_summary.WarningCount, sct_summary.ErrorCount, ...
        sct_coverage.Classes(1), sct_coverage.Classes(2), ...
        sct_coverage.Methods(1), sct_coverage.Methods(2), ...
        sct_coverage.Properties(1), sct_coverage.Properties(2));
    if option.strict && sct_summary.ErrorCount > 0
        error('export_class_database:ValidationFailed', ...
            'Documentation validation failed with %d error(s).', sct_summary.ErrorCount);
    end
end

function sct_classes = normalize_class_list(val)
    if isstruct(val)
        sct_classes = val(:)';
        return
    end
    cell_names = cellstr(string(val));
    cell_files = cellfun(@which, cell_names, 'UniformOutput', false);
    sct_classes = struct('Name', cell_names(:)', 'File', cell_files(:)');
end

function sct_entry = coverage_entry(rv_count)
    sct_entry = struct('Documented', rv_count(1), 'Total', rv_count(2));
end

function cell_categories = get_model_categories(cell_class_info)
    % Direct subclasses of PowerSystemModel, in the usual reading order first.
    cell_preferred = {'PowerNetwork', 'Bus', 'Branch', 'Component', 'LocalController', 'GlobalController'};
    cell_models = {};
    for i = 1:numel(cell_class_info)
        sct_i = cell_class_info{i};
        if any(strcmp(sct_i.Superclasses, 'PowerSystemModel'))
            cell_models{end+1} = sct_i.Name; %#ok<AGROW>
        end
    end
    cell_categories = [intersect(cell_preferred, cell_models, 'stable'), sort(setdiff(cell_models, cell_preferred))];
end

function write_text_file(str_file_name, str_content)
    file_id = fopen(str_file_name, 'w', 'n', 'UTF-8');
    if file_id < 0
        error('export_class_database:FileOpenFailed', 'Failed to open output file: %s', str_file_name);
    end
    fprintf(file_id, '%s', str_content);
    fclose(file_id);
end



function [sct_info, sct_validation, sct_coverage] = export_class_doc(str_class_name, sct_ctx)
    % Combine MATLAB reflection (meta.class) with the tagged comments in the
    % source files and write one JavaScript file for the class.
    meta_class = meta.class.fromName(str_class_name);
    if isempty(meta_class)
        error('export_class_database:ClassNotFound', 'Class not found on the MATLAB path: %s', str_class_name);
    end

    cell_prop_tags   = get_tag_schema().property;
    cell_method_tags = get_tag_schema().method;
    cell_class_tags  = get_tag_schema().class;

    sct_doc_data = struct( ...
        'schema', struct('name', 'GUILDA class document', 'version', 4), ...
        'ClassName', str_class_name, ...
        'properties', [], ...
        'methods', [], ...
        'events', [], ...
        'enumeration', [], ...
        'validation', struct('Warnings', {{}}, 'Errors', {{}}) ...
    );
    [cell_props, cell_prop_diagnostics, rv_prop_cov] = build_meta_section(meta_class.PropertyList, str_class_name, cell_prop_tags, "property", sct_ctx);
    [cell_methods, cell_method_diagnostics, rv_method_cov] = build_meta_section(meta_class.MethodList, str_class_name, cell_method_tags, "method", sct_ctx);
    sct_doc_data.properties  = cell_props;
    sct_doc_data.methods     = cell_methods;
    sct_doc_data.events      = build_name_list(meta_class.EventList, sct_ctx);
    sct_doc_data.enumeration = build_name_list(meta_class.EnumerationMemberList, sct_ctx);
    [sct_info, cell_class_diagnostics] = build_class_info(str_class_name, meta_class, cell_class_tags, sct_ctx);
    sct_info.PropertyCount = count_members(cell_props, str_class_name);
    sct_info.MethodCount   = count_members(cell_methods, str_class_name);

    cell_diagnostics = [cell_class_diagnostics; cell_prop_diagnostics; cell_method_diagnostics];
    cell_warnings = cell_diagnostics(startsWith(cell_diagnostics, 'WARNING:'));
    cell_errors   = cell_diagnostics(startsWith(cell_diagnostics, 'ERROR:'));
    cell_warnings = erase(cell_warnings, 'WARNING: ');
    cell_errors   = erase(cell_errors, 'ERROR: ');
    sct_doc_data.validation = struct('Warnings', {cell_warnings}, 'Errors', {cell_errors});
    sct_validation = struct('ClassName', str_class_name, 'Warnings', {cell_warnings}, 'Errors', {cell_errors});
    sct_coverage = struct('Classes', [double(sct_info.Documented), 1], 'Properties', rv_prop_cov, 'Methods', rv_method_cov);

    % Output JS file
    if startsWith(sct_info.File, '_GUILDAsystem')
        str_database_folder = 'GUILDAsystem';
    else
        str_database_folder = 'GUILDAobject';
    end
    str_file_name = fullfile(sct_ctx.root, '_GUILDAdoc', 'database', str_database_folder, [str_class_name, '.js']);
    sct_info.path  = ['./database/', str_database_folder, '/', str_class_name, '.js'];
    str_json       = jsonencode(sct_doc_data, 'PrettyPrint', true);
    str_class_key  = jsonencode(str_class_name);
    str_js_content = sprintf([ ...
        '(function (root) {\n', ...
        '  root.GUILDA_DOC_CLASSES = root.GUILDA_DOC_CLASSES || {};\n', ...
        '  root.GUILDA_DOC_CLASSES[%s] = %s;\n', ...
        '})(window);\n' ...
    ], str_class_key, str_json);
    write_text_file(str_file_name, str_js_content);
end

function sct_count = count_members(cell_members, str_class_name)
    n_own = sum(cellfun(@(m) strcmp(m.Defining, str_class_name), cell_members));
    sct_count = struct('Own', n_own, 'Total', numel(cell_members));
end

function cell_names = build_name_list(meta_list, sct_ctx)
    cell_names = cell(1, 0);
    for i_item = 1:numel(meta_list)
        meta_item = meta_list(i_item);
        if isprop(meta_item, 'DefiningClass') && ~is_guilda_class(meta_item.DefiningClass.Name, sct_ctx)
            continue
        end
        cell_names{end+1} = meta_item.Name; %#ok<AGROW>
    end
end

function bln_guilda = is_guilda_class(str_class_name, sct_ctx)
    % Members inherited from MATLAB classes (handle, dynamicprops, mixins)
    % are not documented here.
    if isKey(sct_ctx.files, str_class_name)
        bln_guilda = true;
        return
    end
    str_file = which(str_class_name);
    bln_guilda = ~isempty(str_file) && startsWith(str_file, sct_ctx.root);
end

function str_file = get_class_file(str_class_name, sct_ctx)
    if isKey(sct_ctx.files, str_class_name)
        str_file = sct_ctx.files(str_class_name);
    else
        str_file = which(str_class_name);
    end
end

function str_rel = relative_path(str_file, sct_ctx)
    str_rel = '';
    if isempty(str_file) || ~startsWith(str_file, sct_ctx.root)
        return
    end
    str_rel = strrep(str_file(numel(sct_ctx.root)+2:end), '\', '/');
end

function sct_src = get_source(str_file, str_kind, sct_ctx)
    % Parse each source file once per export.
    str_key = [char(str_kind), '|', char(str_file)];
    if isKey(sct_ctx.sources, str_key)
        sct_src = sct_ctx.sources(str_key);
        return
    end
    if str_kind == "classdef"
        sct_src = parse_classdef_source(str_file);
    else
        sct_src = parse_function_file(str_file);
    end
    sct_ctx.sources(str_key) = sct_src;
end

function [cell_section, cell_diagnostics, rv_coverage] = build_meta_section(meta_list, str_class_name, cell_tags, str_kind, sct_ctx)
    cell_section = cell(1, 0);
    cell_diagnostics = cell(0,1);
    rv_coverage = [0 0];
    for i_item = 1:numel(meta_list)
        meta_item = meta_list(i_item);
        str_defining = meta_item.DefiningClass.Name;
        if strcmp(meta_item.Name, 'empty') || ~is_guilda_class(str_defining, sct_ctx)
            continue
        end
        [sct_info_i, cell_diagnostics_i] = build_meta_info(meta_item, str_class_name, cell_tags, str_kind, sct_ctx);
        cell_section{end+1} = sct_info_i; %#ok<AGROW>
        cell_diagnostics = [cell_diagnostics; cell_diagnostics_i]; %#ok<AGROW>

        % Coverage counts own public members only.
        if strcmp(str_defining, str_class_name) && ~sct_info_i.Hidden
            if str_kind == "property"
                bln_public = is_public_access(sct_info_i.GetAccess);
            else
                bln_public = is_public_access(sct_info_i.Access);
            end
            if bln_public
                bln_documented = ~isempty(strtrim(sct_info_i.Summary)) || ~isempty(strtrim(sct_info_i.Desc));
                rv_coverage = rv_coverage + [double(bln_documented), 1];
            end
        end
    end
end

function [sct_info, cell_diagnostics] = build_meta_info(meta_item, str_class_name, cell_tags, str_kind, sct_ctx)
    str_member   = meta_item.Name;
    str_defining = meta_item.DefiningClass.Name;
    str_def_file = get_class_file(str_defining, sct_ctx);
    sct_class_src = get_source(str_def_file, "classdef", sct_ctx);

    if str_kind == "property"
        sct_info = struct( ...
            'Name',      str_member, ...
            'Defining',  str_defining, ...
            'GetAccess', organize_access(meta_item.GetAccess), ...
            'SetAccess', organize_access(meta_item.SetAccess), ...
            'Dependent', meta_item.Dependent, ...
            'Constant',  meta_item.Constant, ...
            'Abstract',  meta_item.Abstract, ...
            'Hidden',    meta_item.Hidden, ...
            'Transient', meta_item.Transient, ...
            'HasDefault', meta_item.HasDefault, ...
            'DefaultCode', '', ...
            'Validation', get_property_validation(meta_item), ...
            'File',      relative_path(str_def_file, sct_ctx) ...
            );
        str_raw_help = '';
        if isKey(sct_class_src.props, str_member)
            sct_decl = sct_class_src.props(str_member);
            str_raw_help = sct_decl.Comment;
            if isempty(strtrim(str_raw_help))
                str_raw_help = sct_decl.Inline;
            end
            sct_info.DefaultCode = sct_decl.Entry.Default;
            if isempty(sct_info.Validation.Class) && isempty(sct_info.Validation.Size)
                sct_info.Validation = struct('Class', sct_decl.Entry.Class, 'Size', sct_decl.Entry.Size, ...
                    'Validators', {split_validators(sct_decl.Entry.Validators)});
            end
        elseif ~sct_class_src.found
            str_raw_help = sanitize_help_text(try_help(str_class_name + "." + string(str_member)));
        end
    else
        sct_info = struct( ...
            'Name',      str_member, ...
            'Defining',  str_defining, ...
            'Access',    organize_access(meta_item.Access), ...
            'Static',    meta_item.Static, ...
            'Abstract',  meta_item.Abstract, ...
            'Sealed',    meta_item.Sealed, ...
            'Hidden',    meta_item.Hidden, ...
            'IsConstructor', strcmp(str_member, short_class_name(str_defining)), ...
            'InputNames',  {reshape(cellstr(meta_item.InputNames), 1, [])}, ...
            'OutputNames', {reshape(cellstr(meta_item.OutputNames), 1, [])}, ...
            'Arguments', {cell(1, 0)}, ...
            'Signature', '', ...
            'File',      '' ...
            );
        [str_raw_help, sct_fn, str_src_file] = get_method_source(str_member, str_def_file, sct_class_src, sct_ctx);
        sct_info.File = relative_path(str_src_file, sct_ctx);
        if ~isempty(sct_fn)
            if ~isempty(sct_fn.Inputs),  sct_info.InputNames  = sct_fn.Inputs;  end
            if ~isempty(sct_fn.Outputs), sct_info.OutputNames = sct_fn.Outputs; end
            sct_info.Arguments = num2cell(sct_fn.Arguments);
        end
        if isempty(str_raw_help) && ~sct_class_src.found
            str_raw_help = sanitize_help_text(try_help(str_class_name + "." + string(str_member)));
        end
        sct_info.Signature = build_signature(sct_info, str_defining);
    end

    if isempty(strtrim(str_raw_help)) && ~sct_class_src.found
        str_raw_help = sanitize_help_text([meta_item.Description, newline, meta_item.DetailedDescription]);
    end
    str_context = char(str_class_name + "." + string(str_member));
    [sct_info, cell_diagnostics] = apply_help_tags(sct_info, str_raw_help, cell_tags, str_kind, str_context, sct_ctx.strict);

    % Report problems only where the member is defined, so that an inherited
    % member is not reported again for every subclass.
    if ~strcmp(str_defining, str_class_name)
        cell_diagnostics = cell(0,1);
        return
    end
    if str_kind == "method"
        if is_public_access(sct_info.Access) && ~sct_info.Hidden ...
                && isempty(strtrim(sct_info.Summary)) && isempty(strtrim(sct_info.Desc))
            cell_diagnostics{end+1,1} = sprintf('WARNING: %s: public method has no Summary or Desc.', str_context);
        end
        % An implicit constructor has no source; that is not a problem.
        if ~sct_info.Abstract && ~sct_info.IsConstructor && isempty(sct_info.File)
            cell_diagnostics{end+1,1} = sprintf('WARNING: %s: method is declared but no implementation was found.', str_context);
        end
        cell_diagnostics = [cell_diagnostics; check_parameter_names(sct_info, str_context)];
    end
end

function str_short = short_class_name(str_class_name)
    cell_parts = strsplit(str_class_name, '.');
    str_short = cell_parts{end};
end

function sct_validation = get_property_validation(meta_item)
    sct_validation = struct('Class', '', 'Size', '', 'Validators', {cell(1, 0)});
    meta_valid = meta_item.Validation;
    if isempty(meta_valid)
        return
    end
    if ~isempty(meta_valid.Class)
        sct_validation.Class = meta_valid.Class.Name;
    end
    if ~isempty(meta_valid.Size)
        cell_dims = arrayfun(@dimension_text, meta_valid.Size, 'UniformOutput', false);
        sct_validation.Size = ['(', strjoin(cell_dims, ','), ')'];
    end
    cell_fns = cellfun(@func2str, meta_valid.ValidatorFunctions, 'UniformOutput', false);
    sct_validation.Validators = reshape(regexprep(cell_fns, '^@\([^)]*\)\s*', ''), 1, []);
end

function str_dim = dimension_text(meta_dim)
    if isa(meta_dim, 'meta.FixedDimension')
        str_dim = num2str(meta_dim.Length);
    else
        str_dim = ':';
    end
end

function cell_validators = split_validators(str_validators)
    % '{mustBeA(x,"a"), mustBePositive}' -> {'mustBeA(x,"a")', 'mustBePositive'}
    cell_validators = cell(1, 0);
    str_body = strtrim(str_validators);
    if strlength(str_body) < 2
        return
    end
    str_body = str_body(2:end-1);
    i_start = 1;
    n_depth = 0;
    for i = 1:numel(str_body)
        ch = str_body(i);
        if any(ch == '([{'), n_depth = n_depth + 1; end
        if any(ch == ')]}'), n_depth = n_depth - 1; end
        if ch == ',' && n_depth == 0
            cell_validators{end+1} = strtrim(str_body(i_start:i-1)); %#ok<AGROW>
            i_start = i + 1;
        end
    end
    cell_validators{end+1} = strtrim(str_body(i_start:end));
    cell_validators = cell_validators(~cellfun(@isempty, cell_validators));
end

function [str_help, sct_fn, str_src_file] = get_method_source(str_member, str_def_file, sct_class_src, sct_ctx)
    % Method comments are read from, in order:
    %   1. the method file @Class/<method>.m (comment lines after "function"),
    %   2. a function defined inside the classdef file (same rule),
    %   3. @Class/private/<method>.m for a declared method implemented there,
    %   4. comment lines above a signature declared in a methods block.
    str_help = '';
    sct_fn = [];
    str_src_file = '';
    [str_dir, ~] = fileparts(str_def_file);
    [~, str_dir_name] = fileparts(str_dir);
    str_method_file = fullfile(str_dir, [str_member, '.m']);
    if startsWith(str_dir_name, '@') && isfile(str_method_file)
        sct_fn = get_source(str_method_file, "function", sct_ctx);
        str_help = sct_fn.Comment;
        str_src_file = str_method_file;
    elseif isKey(sct_class_src.funcs, str_member)
        sct_fn = sct_class_src.funcs(str_member);
        str_help = sct_fn.Comment;
        str_src_file = str_def_file;
    elseif startsWith(str_dir_name, '@') && isfile(fullfile(str_dir, 'private', [str_member, '.m']))
        str_src_file = fullfile(str_dir, 'private', [str_member, '.m']);
        sct_fn = get_source(str_src_file, "function", sct_ctx);
        str_help = sct_fn.Comment;
    end
    if isempty(strtrim(str_help)) && isKey(sct_class_src.decls, str_member)
        str_help = sct_class_src.decls(str_member);
    end
end

function str_signature = build_signature(sct_info, str_defining)
    % Build "[out1, out2] = name(in1, in2, Name=Value)" from the arguments
    % block when there is one, otherwise from the function line.
    cell_out = sct_info.OutputNames;
    cell_in  = sct_info.InputNames;
    if ~isempty(sct_info.Arguments)
        sct_args = [sct_info.Arguments{:}];
        cell_in = {};
        for i = 1:numel(sct_args)
            switch sct_args(i).Kind
                case 'Positional'
                    cell_in{end+1} = sct_args(i).Name; %#ok<AGROW>
                case 'Repeating'
                    cell_in{end+1} = [sct_args(i).Name, '...']; %#ok<AGROW>
            end
        end
        if any(strcmp({sct_args.Kind}, 'NameValue'))
            cell_in{end+1} = 'Name=Value';
        end
    end
    str_name = sct_info.Name;
    if sct_info.Static || sct_info.IsConstructor
        if sct_info.IsConstructor
            str_name = str_defining;
        else
            str_name = [str_defining, '.', str_name];
        end
    end
    switch numel(cell_out)
        case 0
            str_out = '';
        case 1
            str_out = [cell_out{1}, ' = '];
        otherwise
            str_out = ['[', strjoin(cell_out, ', '), '] = '];
    end
    str_signature = [str_out, str_name, '(', strjoin(cell_in, ', '), ')'];
end

function cell_diagnostics = check_parameter_names(sct_info, str_context)
    % <@Parameters> entries should name real inputs of the method.
    cell_diagnostics = cell(0,1);
    if isempty(sct_info.Parameters)
        return
    end
    cell_known = sct_info.InputNames;
    if ~isempty(sct_info.Arguments)
        sct_args = [sct_info.Arguments{:}];
        cell_known = [cell_known, {sct_args.Name}];
    end
    if any(strcmp(cell_known, 'varargin'))
        return
    end
    sct_params = [sct_info.Parameters{:}];
    cell_unknown = setdiff({sct_params.Name}, [cell_known, {''}], 'stable');
    for i = 1:numel(cell_unknown)
        cell_diagnostics{end+1,1} = sprintf( ...
            'WARNING: %s: <@Parameters> names "%s", which is not an input of the method.', ...
            str_context, cell_unknown{i}); %#ok<AGROW>
    end
end

function str_access = organize_access(dat)
    % MATLAB returns access lists in no fixed order, so the names are sorted
    % to keep the export identical between runs.
    if isa(dat,"char") || isa(dat,"string")
        str_access = char(dat);
        return
    end

    if iscell(dat)
        cell_access = cellfun(@organize_access, dat, 'UniformOutput', false);
        cell_access = cell_access(~cellfun(@isempty, cell_access));
        str_access = strjoin(sort(cell_access), ', ');
    elseif isscalar(dat)
        str_access = dat.Name;
    else
        cell_access = arrayfun(@(d) organize_access(d), dat, 'UniformOutput', false);
        str_access = strjoin(sort(cell_access), ', ');
    end
end

function cell_ancestors = get_ancestors(meta_class)
    % All superclasses, nearest first (breadth-first).
    cell_ancestors = {};
    cell_queue = num2cell(meta_class.SuperclassList(:)');
    while ~isempty(cell_queue)
        meta_i = cell_queue{1};
        cell_queue(1) = [];
        if any(strcmp(cell_ancestors, meta_i.Name))
            continue
        end
        cell_ancestors{end+1} = meta_i.Name; %#ok<AGROW>
        cell_queue = [cell_queue, num2cell(meta_i.SuperclassList(:)')]; %#ok<AGROW>
    end
end

function str_model = get_model_name(str_class_name, meta_class)
    % The model category is the class in the chain that directly inherits
    % PowerSystemModel (PowerNetwork, Bus, Branch, Component, ...).
    str_model = '';
    cell_queue = {meta_class};
    cell_seen = {};
    while ~isempty(cell_queue)
        meta_i = cell_queue{1};
        cell_queue(1) = [];
        if any(strcmp(cell_seen, meta_i.Name))
            continue
        end
        cell_seen{end+1} = meta_i.Name; %#ok<AGROW>
        cell_supers = arrayfun(@(m) m.Name, meta_i.SuperclassList, 'UniformOutput', false);
        if any(strcmp(cell_supers, 'PowerSystemModel'))
            str_model = meta_i.Name;
            return
        end
        cell_queue = [cell_queue, num2cell(meta_i.SuperclassList(:)')]; %#ok<AGROW>
    end
    if strcmp(str_class_name, 'PowerSystemModel')
        str_model = '';
    end
end

function [sct_info, cell_diagnostics] = build_class_info(str_class_name, meta_class, cell_tags, sct_ctx)
    cell_ancestors = get_ancestors(meta_class);
    cell_supers = reshape(arrayfun(@(m) m.Name, meta_class.SuperclassList, 'UniformOutput', false), 1, []);

    if strcmp(str_class_name, 'PowerSystemModel') || any(strcmp(cell_ancestors, 'PowerSystemModel'))
        str_type  = 'PowerSystemModel';
        str_model = get_model_name(str_class_name, meta_class);
    elseif strcmp(str_class_name, 'auxiliary') || any(strcmp(cell_ancestors, 'auxiliary'))
        str_type  = 'auxiliary';
        str_model = '';
    else
        str_type  = 'other';
        str_model = '';
    end
    str_package = '';
    if ~isempty(meta_class.ContainingPackage)
        str_package = meta_class.ContainingPackage.Name;
    end
    str_file = get_class_file(str_class_name, sct_ctx);

    sct_info = struct( ...
        'Name',         str_class_name, ...
        'Type',         str_type, ...
        'Model',        str_model, ...
        'Parent',       strjoin(cell_supers, ', '), ...
        'Superclasses', {cell_supers}, ...
        'Ancestors',    {cell_ancestors}, ...
        'Package',      str_package, ...
        'File',         relative_path(str_file, sct_ctx), ...
        'Abstract',     meta_class.Abstract, ...
        'Sealed',       meta_class.Sealed, ...
        'Hidden',       meta_class.Hidden ...
    );
    sct_src = get_source(str_file, "classdef", sct_ctx);
    str_help = sct_src.ClassComment;
    if isempty(strtrim(str_help)) && ~sct_src.found
        str_help = sanitize_help_text(try_help(str_class_name));
    end
    % meta.class.Description is only used without a readable source file:
    % it would turn a section line such as "%% Properties" into a summary.
    if isempty(strtrim(str_help)) && ~sct_src.found
        str_help = sanitize_help_text([meta_class.Description, newline, meta_class.DetailedDescription]);
    end
    [sct_info, cell_diagnostics] = apply_help_tags(sct_info, str_help, cell_tags, "class", str_class_name, sct_ctx.strict);
    sct_info.Documented = ~isempty(strtrim(sct_info.Summary)) || ~isempty(strtrim(sct_info.Desc));
    if ~sct_info.Documented
        cell_diagnostics{end+1,1} = sprintf('WARNING: %s: class has no Summary or Desc.', str_class_name);
    end
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



%% Source parsing
% The parser reads only what the documentation needs: the class comment,
% property declarations with their comments, functions defined in the
% classdef file, method signatures declared in methods blocks, and
% arguments blocks. It does not evaluate any code.

function sct_src = parse_classdef_source(str_file)
    sct_src = struct( ...
        'found', false, ...
        'ClassComment', '', ...
        'props', containers.Map('KeyType', 'char', 'ValueType', 'any'), ...
        'funcs', containers.Map('KeyType', 'char', 'ValueType', 'any'), ...
        'decls', containers.Map('KeyType', 'char', 'ValueType', 'any') ...
    );
    cell_lines = read_lines(str_file);
    if isempty(cell_lines)
        return
    end
    sct_src.found = true;
    idx_classdef = find(~cellfun(@isempty, regexp(cell_lines, '^\s*classdef\>', 'once')), 1, 'first');
    if isempty(idx_classdef)
        return
    end
    [sct_src.ClassComment, i] = collect_following_comment_lines(cell_lines, idx_classdef + 1);

    str_state = 'class';
    cell_buffer = {};
    n_lines = numel(cell_lines);
    while i <= n_lines
        str_line = cell_lines{i};
        [str_code, str_comment] = split_code_comment(str_line);
        str_code = strtrim(str_code);
        if isempty(str_code)
            if ~isempty(str_comment) && startsWith(strtrim(str_line), '%')
                cell_buffer{end+1,1} = str_line; %#ok<AGROW>
            elseif ~isempty(cell_buffer)
                cell_buffer{end+1,1} = str_line; %#ok<AGROW>
            end
            i = i + 1;
            continue
        end

        switch str_state
            case 'class'
                str_block = regexp(str_code, '^(properties|methods|events|enumeration)\>', 'tokens', 'once');
                if ~isempty(str_block)
                    str_state = str_block{1};
                elseif strcmp(str_code, 'end')
                    break
                end
                cell_buffer = {};
                i = i + 1;

            case 'properties'
                if is_end_line(str_code)
                    str_state = 'class';
                    cell_buffer = {};
                    i = i + 1;
                    continue
                end
                [str_decl, str_inline, i] = join_continued_lines(cell_lines, i);
                sct_entry = parse_declaration(str_decl);
                if ~isempty(sct_entry.Name)
                    sct_src.props(sct_entry.Name) = struct( ...
                        'Comment', normalize_comment_lines(cell_buffer), ...
                        'Inline',  strtrim(str_inline), ...
                        'Entry',   sct_entry);
                end
                cell_buffer = {};

            case 'methods'
                if is_end_line(str_code)
                    str_state = 'class';
                    cell_buffer = {};
                    i = i + 1;
                    continue
                end
                if ~isempty(regexp(str_code, '^function\>', 'once'))
                    [sct_fn, i] = parse_function_at(cell_lines, i);
                    if ~isempty(sct_fn.Name)
                        sct_src.funcs(sct_fn.Name) = sct_fn;
                    end
                else
                    [str_decl, ~, i] = join_continued_lines(cell_lines, i);
                    sct_header = parse_function_header(['function ', str_decl]);
                    if ~isempty(sct_header.Name) && ~isempty(cell_buffer)
                        sct_src.decls(sct_header.Name) = normalize_comment_lines(cell_buffer);
                    end
                end
                cell_buffer = {};

            otherwise % events, enumeration
                if is_end_line(str_code)
                    str_state = 'class';
                end
                cell_buffer = {};
                i = i + 1;
        end
    end
end

function sct_fn = parse_function_file(str_file)
    sct_fn = empty_function_info();
    cell_lines = read_lines(str_file);
    idx_function = find(~cellfun(@isempty, regexp(cell_lines, '^\s*function\>', 'once')), 1, 'first');
    if isempty(idx_function)
        return
    end
    sct_fn = parse_function_at(cell_lines, idx_function);
end

function sct_fn = empty_function_info()
    sct_fn = struct('Name', '', 'Inputs', {cell(1, 0)}, 'Outputs', {cell(1, 0)}, ...
        'Comment', '', 'Arguments', empty_argument_struct());
end

function [sct_fn, i_next] = parse_function_at(cell_lines, i_function)
    % Read "function ..." at i_function, the comment block after it, and the
    % arguments blocks; i_next is the line after the function's end.
    [str_header, ~, i] = join_continued_lines(cell_lines, i_function);
    sct_fn = parse_function_header(str_header);
    [sct_fn.Comment, i] = collect_following_comment_lines(cell_lines, i);
    [sct_fn.Arguments, i] = parse_arguments_blocks(cell_lines, i);
    i_next = skip_function_body(cell_lines, i_function);
end

function sct_header = parse_function_header(str_header)
    sct_header = empty_function_info();
    str_code = strtrim(split_code_comment(str_header));
    % MATLAB regexp drops tokens of optional groups, so split by hand:
    % function [out1, out2] = name(in1, in2)
    str_rest = strtrim(regexprep(str_code, '^function\s+', '', 'once'));
    i_eq  = find(str_rest == '=', 1, 'first');
    i_par = find(str_rest == '(', 1, 'first');
    str_out = '';
    if ~isempty(i_eq) && (isempty(i_par) || i_eq < i_par)
        str_out  = str_rest(1:i_eq-1);
        str_rest = strtrim(str_rest(i_eq+1:end));
    end
    str_name = regexp(str_rest, '^[A-Za-z][\w.]*', 'match', 'once');
    if isempty(str_name)
        return
    end
    str_rest = strtrim(str_rest(numel(str_name)+1:end));
    str_in = '';
    if startsWith(str_rest, '(')
        i_close = find(str_rest == ')', 1, 'first');
        if isempty(i_close), i_close = numel(str_rest) + 1; end
        str_in = str_rest(2:i_close-1);
    end
    sct_header.Name    = str_name;
    sct_header.Outputs = split_names(regexprep(str_out, '[\[\]]', ''));
    sct_header.Inputs  = split_names(str_in);
end

function cell_names = split_names(str_list)
    cell_names = regexp(strtrim(str_list), '[\s,]+', 'split');
    cell_names = cell_names(~cellfun(@isempty, cell_names));
    cell_names = reshape(cell_names, 1, []);
end

function i_next = skip_function_body(cell_lines, i_function)
    % Count block keywords to find the matching "end". A function file
    % without "end" simply runs to the end of the file.
    n_depth = 0;
    i = i_function;
    while i <= numel(cell_lines)
        str_code = strtrim(split_code_comment(cell_lines{i}));
        n_depth = n_depth + block_delta(str_code);
        i = i + 1;
        if n_depth <= 0
            break
        end
    end
    i_next = i;
end

function n_delta = block_delta(str_code)
    n_delta = 0;
    if isempty(str_code)
        return
    end
    if ~isempty(regexp(str_code, '^arguments\>\s*(\([^)]*\))?\s*$', 'once'))
        n_delta = 1;
        return
    end
    str_code = remove_string_literals(str_code);
    cell_tokens = regexp(str_code, '[A-Za-z_]\w*|[\(\)\[\]\{\}]|\.\s*[A-Za-z_]\w*', 'match');
    cell_openers = {'if', 'for', 'parfor', 'while', 'switch', 'try', 'function', 'spmd'};
    n_paren = 0;
    for i = 1:numel(cell_tokens)
        str_tok = cell_tokens{i};
        switch str_tok
            case {'(', '[', '{'}
                n_paren = n_paren + 1;
            case {')', ']', '}'}
                n_paren = max(n_paren - 1, 0);
            otherwise
                if n_paren > 0 || str_tok(1) == '.'
                    continue
                end
                if strcmp(str_tok, 'end')
                    n_delta = n_delta - 1;
                elseif any(strcmp(str_tok, cell_openers))
                    n_delta = n_delta + 1;
                end
        end
    end
end

function [sct_args, i_next] = parse_arguments_blocks(cell_lines, i)
    sct_args = empty_argument_struct();
    n_lines = numel(cell_lines);
    while i <= n_lines
        str_code = strtrim(split_code_comment(cell_lines{i}));
        if isempty(str_code)
            i = i + 1;
            continue
        end
        if isempty(regexp(str_code, '^arguments\>\s*(\([^)]*\))?\s*$', 'once'))
            break
        end
        % arguments, arguments (Repeating), arguments (Input, Repeating), arguments (Output)
        if contains(str_code, 'Repeating')
            str_block = 'Repeating';
        elseif contains(str_code, 'Output')
            str_block = 'Output';
        else
            str_block = 'Input';
        end
        i = i + 1;
        cell_buffer = {};
        while i <= n_lines
            [str_code, ~] = split_code_comment(cell_lines{i});
            str_code = strtrim(str_code);
            if isempty(str_code)
                if startsWith(strtrim(cell_lines{i}), '%')
                    cell_buffer{end+1,1} = cell_lines{i}; %#ok<AGROW>
                end
                i = i + 1;
                continue
            end
            if is_end_line(str_code)
                i = i + 1;
                break
            end
            [str_decl, str_inline, i] = join_continued_lines(cell_lines, i);
            sct_entry = parse_declaration(str_decl);
            if isempty(sct_entry.Name)
                cell_buffer = {};
                continue
            end
            str_description = strtrim(str_inline);
            if isempty(str_description)
                str_description = normalize_comment_lines(cell_buffer);
            end
            cell_buffer = {};
            sct_args(end+1) = make_argument(sct_entry, str_block, str_description); %#ok<AGROW>
        end
    end
    sct_args = sct_args(~strcmp({sct_args.Kind}, 'Output'));
    i_next = i;
end

function sct_arg = make_argument(sct_entry, str_block, str_description)
    str_name = sct_entry.Name;
    str_struct = '';
    if contains(str_name, '.')
        cell_parts = strsplit(str_name, '.');
        str_struct = cell_parts{1};
        str_name = cell_parts{2};
        str_kind = 'NameValue';
    elseif strcmp(str_block, 'Repeating')
        str_kind = 'Repeating';
    elseif strcmp(str_block, 'Output')
        str_kind = 'Output';
    else
        str_kind = 'Positional';
    end
    sct_arg = struct( ...
        'Name', str_name, ...
        'Kind', str_kind, ...
        'Struct', str_struct, ...
        'Size', sct_entry.Size, ...
        'Class', sct_entry.Class, ...
        'Validators', {split_validators(sct_entry.Validators)}, ...
        'Default', sct_entry.Default, ...
        'Required', strcmp(str_kind, 'Positional') && isempty(sct_entry.Default), ...
        'Description', str_description ...
    );
end

function sct_args = empty_argument_struct()
    sct_args = struct('Name', {}, 'Kind', {}, 'Struct', {}, 'Size', {}, 'Class', {}, ...
        'Validators', {}, 'Default', {}, 'Required', {}, 'Description', {});
end

function sct_entry = parse_declaration(str_decl)
    % Parse "name (dims) Class {validators} = default", the common grammar of
    % property declarations and arguments-block entries.
    sct_entry = struct('Name', '', 'Size', '', 'Class', '', 'Validators', '', 'Default', '');
    str_code = strtrim(str_decl);
    str_code = regexprep(str_code, ';\s*$', '');
    cell_tok = regexp(str_code, '^([A-Za-z]\w*(?:\.[A-Za-z]\w*)?)', 'tokens', 'once');
    if isempty(cell_tok)
        return
    end
    sct_entry.Name = cell_tok{1};
    str_rest = strtrim(str_code(numel(cell_tok{1})+1:end));
    if startsWith(str_rest, '(')
        i_close = find_matching(str_rest, 1);
        sct_entry.Size = str_rest(1:i_close);
        str_rest = strtrim(str_rest(i_close+1:end));
    end
    cell_class = regexp(str_rest, '^([A-Za-z][\w.]*)', 'tokens', 'once');
    if ~isempty(cell_class)
        sct_entry.Class = cell_class{1};
        str_rest = strtrim(str_rest(numel(cell_class{1})+1:end));
    end
    if startsWith(str_rest, '{')
        i_close = find_matching(str_rest, 1);
        sct_entry.Validators = str_rest(1:i_close);
        str_rest = strtrim(str_rest(i_close+1:end));
    end
    if startsWith(str_rest, '=')
        sct_entry.Default = strtrim(str_rest(2:end));
    end
end

function i_close = find_matching(str_text, i_open)
    % Index of the bracket that closes str_text(i_open), skipping strings.
    n_depth = 0;
    i = i_open;
    while i <= numel(str_text)
        ch = str_text(i);
        if ch == '"' || (ch == '''' && is_quote_start(str_text, i))
            i_end = find(str_text(i+1:end) == ch, 1, 'first');
            if isempty(i_end), break, end
            i = i + i_end + 1;
            continue
        end
        if any(ch == '([{'), n_depth = n_depth + 1; end
        if any(ch == ')]}')
            n_depth = n_depth - 1;
            if n_depth == 0
                i_close = i;
                return
            end
        end
        i = i + 1;
    end
    i_close = numel(str_text);
end

function bln_start = is_quote_start(str_text, i)
    % A single quote starts a char vector unless it is a transpose.
    bln_start = i == 1 || isempty(regexp(str_text(i-1), '[\w\)\]\}\.''"]', 'once'));
end

function [str_code, str_comment] = split_code_comment(str_line)
    % Split a line at the first % that is not inside a string literal.
    str_code = str_line;
    str_comment = '';
    i = 1;
    while i <= numel(str_line)
        ch = str_line(i);
        if ch == '"' || (ch == '''' && is_quote_start(str_line, i))
            i_end = find(str_line(i+1:end) == ch, 1, 'first');
            if isempty(i_end), return, end
            i = i + i_end + 1;
            continue
        end
        if ch == '%'
            str_code = str_line(1:i-1);
            str_comment = regexprep(str_line(i:end), '^%+\s?', '');
            return
        end
        i = i + 1;
    end
end

function str_code = remove_string_literals(str_code)
    str_code = regexprep(str_code, '"[^"]*"', '""');
    str_out = '';
    i = 1;
    while i <= numel(str_code)
        ch = str_code(i);
        if ch == '''' && is_quote_start(str_code, i)
            i_end = find(str_code(i+1:end) == '''', 1, 'first');
            if isempty(i_end), break, end
            i = i + i_end + 1;
            continue
        end
        str_out(end+1) = ch; %#ok<AGROW>
        i = i + 1;
    end
    str_code = str_out;
end

function [str_joined, str_inline, i_next] = join_continued_lines(cell_lines, i)
    % Join "..." continuations and lines inside open brackets into one
    % statement. str_inline is the trailing comment of the last line.
    str_joined = '';
    str_inline = '';
    n_depth = 0;
    while i <= numel(cell_lines)
        [str_code, str_comment] = split_code_comment(cell_lines{i});
        i = i + 1;
        bln_continue = ~isempty(regexp(str_code, '\.\.\.\s*$', 'once'));
        str_code = regexprep(str_code, '\.\.\.\s*$', '');
        str_joined = [str_joined, ' ', strtrim(str_code)]; %#ok<AGROW>
        str_clean = remove_string_literals(str_code);
        n_depth = n_depth + sum(ismember(str_clean, '([{')) - sum(ismember(str_clean, ')]}'));
        str_inline = str_comment;
        if ~bln_continue && n_depth <= 0
            break
        end
    end
    str_joined = strtrim(str_joined);
    i_next = i;
end

function bln_end = is_end_line(str_code)
    bln_end = ~isempty(regexp(str_code, '^end\s*[;,]?$', 'once'));
end

function cell_lines = read_lines(str_file_path)
    cell_lines = {};
    if isempty(str_file_path) || ~isfile(str_file_path)
        return
    end
    try
        str_text = fileread(str_file_path, 'Encoding', 'UTF-8');
    catch
        return
    end
    cell_lines = regexp(regexprep(str_text, '\r\n?', '\n'), '\n', 'split');
end

function [str_help, i_next] = collect_following_comment_lines(cell_lines, idx_start)
    cell_comment = {};
    i = idx_start;
    while i <= numel(cell_lines)
        str_line = cell_lines{i};
        % A "%%" section line starts a new code section, not more help text
        % (except directly below the header, where old files put the H1 line).
        if i > idx_start && ~isempty(regexp(str_line, '^\s*%%', 'once'))
            break
        end
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
    i_next = i;
end

function str_help = normalize_comment_lines(cell_comment)
    str_help = '';
    if isempty(cell_comment)
        return
    end

    for i = 1:numel(cell_comment)
        cell_comment{i} = regexprep(cell_comment{i}, '^\s*%+\s?', '');
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



%% Tags
function [sct_info, cell_diagnostics] = apply_help_tags(sct_info, str_raw_help, cell_tags, str_kind, str_context, bln_strict)
    [sct_parsed_tags, cell_source_tags, str_preamble] = parse_tagged_help(str_raw_help);
    cell_diagnostics = cell(0,1);

    % Removed tag names are not read. They are errors under "strict" and
    % warnings otherwise, and name the tag that replaces them.
    sct_removed = get_removed_tags();
    if bln_strict
        str_level = 'ERROR';
    else
        str_level = 'WARNING';
    end
    cell_removed_used = intersect(unique(cell_source_tags, 'stable'), fieldnames(sct_removed), 'stable');
    for i_tag = 1:numel(cell_removed_used)
        cell_diagnostics{end+1,1} = sprintf( ...
            '%s: %s: <@%s> is no longer supported; use <@%s>.', ...
            str_level, str_context, cell_removed_used{i_tag}, sct_removed.(cell_removed_used{i_tag})); %#ok<AGROW>
    end

    cell_allowed_tags = get_allowed_source_tags(cell_tags);
    cell_unknown_tags = setdiff(unique(cell_source_tags, 'stable'), [cell_allowed_tags; cell_removed_used(:)], 'stable');
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
        if isfield(sct_parsed_tags, str_tag_name)
            [sct_info.(str_tag_name), str_error] = parse_tag_value(str_tag_name, sct_parsed_tags.(str_tag_name));
            if ~isempty(str_error)
                cell_diagnostics{end+1,1} = sprintf( ...
                    'ERROR: %s: invalid <@%s> value: %s', ...
                    str_context, str_tag_name, str_error); %#ok<AGROW>
            end
        else
            sct_info.(str_tag_name) = get_default_tag_value(str_tag_name);
        end
    end

    % Untagged text before the first tag is not lost: its first line becomes
    % the Summary and the remaining lines the Desc, unless those tags exist.
    cell_preamble = regexp(strtrim(str_preamble), '\n', 'split');
    if ~isempty(cell_preamble{1})
        bln_summary = ~isempty(strtrim(sct_info.Summary));
        if ~bln_summary
            sct_info.Summary = strtrim(cell_preamble{1});
            cell_preamble(1) = [];
        end
        if isempty(strtrim(sct_info.Desc)) && ~isempty(cell_preamble)
            sct_info.Desc = strtrim(strjoin(cell_preamble, newline));
        end
    end
end

function cell_allowed_tags = get_allowed_source_tags(cell_canonical_tags)
    sct_all_tags = get_tag_schema();
    cell_all_canonical = [sct_all_tags.class(:); sct_all_tags.property(:); sct_all_tags.method(:)];
    cell_allowed_tags = unique([cell_canonical_tags(:); cell_all_canonical], 'stable');
end

function sct_removed = get_removed_tags()
    % Old tag name -> the tag that replaced it.
    sct_removed = struct( ...
        'Abst',        'Summary', ...
        'Description', 'Desc', ...
        'varargin',    'Parameters', ...
        'varargout',   'Returns', ...
        'DetailsCode', 'Notes', ...
        'Example',     'Examples', ...
        'Seealso',     'SeeAlso' ...
    );
end

function [sct_tag_data, cell_tag_names, str_preamble] = parse_tagged_help(rawHelp)
    str_help_text = char(string(rawHelp));
    str_help_text = regexprep(str_help_text, '\r\n?', '\n');

    % Strict tag: <@TagName> (no whitespace allowed inside brackets)
    str_tag_pattern = '<@([A-Za-z][A-Za-z0-9_]*)>';
    [cell_tag_tokens, iv_tag_starts, iv_tag_ends] = regexp(str_help_text, str_tag_pattern, 'tokens', 'start', 'end');

    sct_tag_data = struct();
    cell_tag_names = cellfun(@(token) token{1}, cell_tag_tokens, 'UniformOutput', false);
    if isempty(iv_tag_starts)
        str_preamble = str_help_text;
        return
    end
    str_preamble = str_help_text(1:iv_tag_starts(1)-1);

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
        case 'Calls'
            out = {};
        case {'Parameters', 'Returns'}
            out = cell(1, 0);
        otherwise
            out = '';
    end
end

function [out, str_error] = parse_tag_value(str_tag_name, str_raw_value)
    str_error = '';
    switch str_tag_name
        case {'Signatures', 'Examples', 'SeeAlso'}
            [out, str_error] = parse_json_string_list(str_raw_value);
        case 'Calls'
            [out, str_error] = parse_json_calls(str_raw_value);
        case 'Parameters'
            [out, str_error] = parse_json_parameters(str_raw_value);
            out = reshape(num2cell(out), 1, []);
        case 'Returns'
            [out, str_error] = parse_json_returns(str_raw_value);
            out = reshape(num2cell(out), 1, []);
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

function [out, str_error] = parse_json_calls(str_raw_value)
    str_text = strtrim(char(string(str_raw_value)));
    if ~isempty(str_text) && ~startsWith(str_text, '[')
        out = {};
        str_error = 'expected a JSON array of call objects.';
        return
    end
    [val_json, str_error] = try_jsondecode(str_raw_value);
    if isempty(val_json)
        out = {};
        return
    end
    if ~isstruct(val_json)
        out = {};
        str_error = 'expected a JSON array of call objects.';
        return
    end

    [sct_calls, str_validation_error] = normalize_call_struct_array(val_json);
    out = num2cell(sct_calls);
    if ~isempty(str_validation_error)
        str_error = str_validation_error;
    end
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

function [out, str_error] = normalize_call_struct_array(val)
    str_error = '';
    if ~isstruct(val)
        out = struct('Class', {}, 'Method', {}, 'Condition', {});
        str_error = 'expected a JSON array of call objects.';
        return
    end
    val = val(:);
    out = repmat(struct('Class', '', 'Method', '', 'Condition', ''), numel(val), 1);
    cell_invalid = {};
    for i = 1:numel(val)
        out(i).Class = get_struct_field_str(val(i), {'Class','class'});
        out(i).Method = get_struct_field_str(val(i), {'Method','method'});
        out(i).Condition = get_struct_field_str(val(i), {'Condition','condition'});
        if isempty(strtrim(out(i).Class)) || isempty(strtrim(out(i).Method))
            cell_invalid{end+1} = sprintf('%d', i); %#ok<AGROW>
        end
    end
    if ~isempty(cell_invalid)
        str_error = sprintf( ...
            'Calls entries %s must contain non-empty Class and Method fields.', ...
            strjoin(cell_invalid, ', '));
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
        'Calls', 'Examples', 'Notes', 'Throws', 'SeeAlso', 'Since', 'Deprecated' ...
    };
    sct_schema.structured = {'Signatures', 'Parameters', 'Returns', 'Calls', 'Examples', 'SeeAlso'};
end

function bln_public = is_public_access(str_access)
    str_access = lower(strtrim(char(string(str_access))));
    bln_public = strcmp(str_access, 'public') || isempty(str_access);
end
