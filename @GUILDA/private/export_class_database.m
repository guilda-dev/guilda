function sct_summary = export_class_database(sct_scan, option)
% Export the class reference database read by _GUILDAdoc/class.html,
% method.html and the Reference tab of index.html.
%
% >> export_class_database(find_doc_classes())                % changed classes only
% >> export_class_database(find_doc_classes(), "full", true)  % every class
%
% sct_scan : output of find_doc_classes (Roots, Classes, Files, Tool).
% full     : ignore database/manifest.json and export every class.
% strict   : removed tags are errors and errors stop the export; implies full.
%
% A class is exported again when one of its files (the classdef file, or
% every .m file in its @Class folder) was added, removed or edited, and so
% are its descendants, which show its members. The other classes are taken
% from manifest.json, which stores the files (time, size, checksum) and the
% index entry of every class; no git is used. A changed exporter (Tool
% signature) rebuilds everything, and files of vanished classes are deleted.
%
% Output files (generated, not tracked by git):
%   _GUILDAdoc/database/list_Classes.js     class index and folder tree
%   _GUILDAdoc/database/GUILDAsystem/*.js   one file per System class
%   _GUILDAdoc/database/GUILDAobject/*.js   one file per Object class
%   _GUILDAdoc/database/User/*.js           one file per User class (never published)
%   _GUILDAdoc/database/manifest.json       export state for the next run
%
% Schema version 5
% ----------------
% list_Classes.js: window.GUILDA_DOC_INDEX = {
%   schema: {name, version: 5, classDocumentVersion: 5, pathBase, generatedAt,
%            matlabRelease, modelCategories, coreClasses,
%            tags: {class, property, method: [tag name], removed: {Tag: message}}}
%   classes: [class], sorted by Name
%   tree: [node], roots System, Object, then one per user root folder
%   coverage: {Classes, Properties, Methods: {Documented, Total}}
%   validation: {warningCount, errorCount, classes: [{ClassName, Warnings, Errors}]}
% }
% class: Name, Origin ("System"|"Object"|"User"), Folder, Category (= Package),
%   Type ("PowerSystemModel"|"auxiliary"|"other"), Model, Parent,
%   Superclasses, Ancestors (nearest first), Subclasses (direct, among the
%   exported classes), Package, File, Line, Abstract, Sealed, Hidden,
%   Summary, Desc, SeeAlso, Examples, Deprecated, Documented,
%   PropertyCount {Own, Total}, MethodCount {Own, Total}, path (class JS file)
% node: Name, Kind ("folder"|"file"), Path, Children ([] for files), and on
%   file nodes Class (the classdef file and every file in @Class/) and
%   Method (a method file directly in @Class/).
%   Path, File and Folder are relative to the GUILDA root with "/";
%   for User classes they are absolute.
% <Class>.js: window.GUILDA_DOC_CLASSES[Name] = {
%   schema: {name, version: 5}, ClassName, properties: [property],
%   methods: [method], events: [name], enumeration: [name],
%   validation: {Warnings, Errors}}
% property: Name, Defining, Group, GetAccess, SetAccess, Dependent, Constant,
%   Abstract, Hidden, Transient, HasDefault, DefaultCode,
%   Validation {Class, Size, Validators}, Unit, File, Line,
%   Summary, Desc, SeeAlso, Type, Deprecated
% method: Name, Defining, Group, Access, Static, Abstract, Sealed, Hidden,
%   IsConstructor, InputNames, OutputNames, Arguments [argument],
%   Outputs [argument], Signature, File, Line,
%   ImplementedIn ("classdef"|"file"|"private"|""), Overrides, Throws,
%   Summary, Desc, SeeAlso, Examples, Deprecated
% argument: Name, Kind ("Positional"|"Repeating"|"NameValue"|"Output"),
%   Struct, Size, Class, Validators, Default, Required, Unit, Description
%
% Read from the code and MATLAB help conventions (no tags):
%   Summary  first comment line (H1); Desc the following lines (Markdown)
%   SeeAlso  a "See also A, B" line
%   Unit     a leading "[unit]" in a property or arguments-block comment
%   Group    property: trailing comment of the "properties (...)" line,
%            else the block attributes ("Public" without attributes);
%            method: name prefix before the first "_", "Constructor",
%            or "Other" without "_"
%   Overrides  nearest GUILDA ancestor that defines the same method
%   Throws     error IDs in error(...) and MException(...) calls of the
%              method body (with the local functions of a method file)
% Tags: <@Examples> (class, method), <@Deprecated> (all), <@Type> (property).
    arguments
        sct_scan (1,1) struct
        option.strict (1,1) logical = false
        option.full   (1,1) logical = false
    end
    sct_classes = sct_scan.Classes;
    cell_names  = {sct_classes.Name};
    n_class     = numel(sct_classes);

    str_GUILDApath = GUILDA.pwd();
    str_db_path    = fullfile(str_GUILDApath, '_GUILDAdoc', 'database');
    str_manifest   = fullfile(str_db_path, 'manifest.json');

    disp(" ")
    disp(" === Update Documentation Database === ")

    sct_old  = read_manifest(str_manifest);
    bln_full = option.full || option.strict || isempty(sct_old) || ~strcmp(sct_old.exporter, sct_scan.Tool);
    if bln_full
        sct_old = struct('exporter', '', 'files', empty_file_state(), 'classes', empty_entry_struct());
        for str_folder = ["GUILDAsystem", "GUILDAobject", "User"]
            str_folder_path = fullfile(str_db_path, str_folder);
            if isfolder(str_folder_path)
                rmdir(str_folder_path, 's');
            end
        end
    end
    map_old = containers.Map('KeyType', 'char', 'ValueType', 'any');
    for i_old = 1:numel(sct_old.classes)
        map_old(sct_old.classes(i_old).Name) = sct_old.classes(i_old);
    end

    % Classes to export: new or changed classes, then their descendants.
    cell_changed = get_changed_files(sct_old.files, sct_scan.Files);
    cell_class_files = arrayfun(@(c) get_class_files(c, sct_scan.Files), sct_classes, 'UniformOutput', false);
    bln_export = true(1, n_class);
    for i_class = 1:n_class
        str_name = cell_names{i_class};
        if ~isKey(map_old, str_name)
            continue
        end
        sct_entry = map_old(str_name);
        bln_export(i_class) = ~strcmp(sct_entry.File, sct_classes(i_class).File) ...
            || ~strcmp(sct_entry.Origin, sct_classes(i_class).Origin) ...
            || any(ismember([cell_class_files{i_class}, cellstr_row(sct_entry.Files)], cell_changed));
    end
    cell_vanished = setdiff(keys(map_old), cell_names);
    cell_moved = [cell_names(bln_export), cell_vanished];
    for i_class = find(~bln_export)
        sct_entry = map_old(cell_names{i_class});
        bln_export(i_class) = any(ismember(cellstr_row(sct_entry.Ancestors), cell_moved));
    end

    % Files of vanished classes, and old files of classes that moved.
    for i_old = 1:numel(sct_old.classes)
        sct_entry = sct_old.classes(i_old);
        i_now = find(strcmp(cell_names, sct_entry.Name), 1);
        if isempty(i_now) || ~strcmp(get_js_path(sct_classes(i_now)), sct_entry.Js)
            str_js_file = fullfile(str_db_path, strrep(sct_entry.Js, '/', filesep));
            if isfile(str_js_file)
                delete(str_js_file);
            end
        end
    end

    if bln_full
        fprintf("  Exporting all %d classes to '_GUILDAdoc/database' ...\n", n_class)
    else
        fprintf("  Exporting %d of %d classes to '_GUILDAdoc/database' (changed and their descendants) ...\n", ...
            sum(bln_export), n_class)
    end

    sct_ctx = struct();
    sct_ctx.root      = str_GUILDApath;
    sct_ctx.files     = containers.Map(cell_names, {sct_classes.File});
    sct_ctx.origins   = containers.Map(cell_names, {sct_classes.Origin});
    sct_ctx.sources   = containers.Map('KeyType', 'char', 'ValueType', 'any');
    sct_ctx.metas     = containers.Map('KeyType', 'char', 'ValueType', 'any');
    sct_ctx.own_methods = containers.Map('KeyType', 'char', 'ValueType', 'any');
    sct_ctx.overrides = containers.Map('KeyType', 'char', 'ValueType', 'char');
    sct_ctx.guilda    = containers.Map('KeyType', 'char', 'ValueType', 'logical');
    sct_ctx.strict    = option.strict;

    r_indent = max([strlength(string(cell_names(bln_export))), 0]) + 2;
    iv_export = find(bln_export);
    cell_entries = cell(1, n_class);
    for i_class = 1:n_class
        if ~bln_export(i_class)
            cell_entries{i_class} = map_old(cell_names{i_class});
        end
    end
    for k = 1:numel(iv_export)
        i_class = iv_export(k);
        str_class_char = cell_names{i_class};
        str_indent = repmat(' ', 1, r_indent - length(str_class_char));

        fprintf("  export(%.3d/%d): %s%s ... ", k, numel(iv_export), str_class_char, str_indent)
        try
            [sct_info_i, sct_validation_i, sct_coverage_i] = export_class_doc(str_class_char, sct_ctx);
            cell_entries{i_class} = struct( ...
                'Name',       str_class_char, ...
                'Origin',     sct_classes(i_class).Origin, ...
                'File',       sct_classes(i_class).File, ...
                'Js',         get_js_path(sct_classes(i_class)), ...
                'Files',      cell_class_files(i_class), ...
                'Ancestors',  {sct_info_i.Ancestors}, ...
                'Info',       sct_info_i, ...
                'Validation', sct_validation_i, ...
                'Coverage',   sct_coverage_i);
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
            % A failed class is left out of the manifest, so the next run
            % tries it again.
            disp("failed")
            str_report = getReport(ME, 'extended', 'hyperlinks', 'off');
            fprintf("%s\n", str_report)
            cell_entries{i_class} = struct( ...
                'Name', str_class_char, 'Failed', true, ...
                'Validation', struct('ClassName', str_class_char, 'Warnings', {{}}, ...
                    'Errors', {{sprintf('Class export failed: %s', ME.message)}}));
        end
    end

    bln_ok = cellfun(@(e) ~isfield(e, 'Failed'), cell_entries);
    cell_class_info = cellfun(@(e) e.Info, cell_entries(bln_ok), 'UniformOutput', false);
    cell_class_info = add_subclasses(cell_class_info);
    if isempty(cell_class_info)
        warning('export_class_database:NoClassExported', 'No class documentation was exported.');
    end

    sct_coverage = struct('Classes', [0 0], 'Properties', [0 0], 'Methods', [0 0]);
    for i_entry = find(bln_ok)
        for str_field = ["Classes", "Properties", "Methods"]
            sct_coverage.(str_field) = sct_coverage.(str_field) + reshape(cell_entries{i_entry}.Coverage.(str_field), 1, []);
        end
    end
    cell_validation = cellfun(@(e) e.Validation, cell_entries, 'UniformOutput', false);

    str_file_name  = fullfile(str_db_path, 'list_Classes.js');
    sct_schema = struct( ...
        'name',                 'GUILDA documentation class index', ...
        'version',              5, ...
        'classDocumentVersion', 5, ...
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
    sct_database.tree    = build_tree(sct_scan, sct_ctx);
    sct_database.coverage = struct( ...
        'Classes',    coverage_entry(sct_coverage.Classes), ...
        'Properties', coverage_entry(sct_coverage.Properties), ...
        'Methods',    coverage_entry(sct_coverage.Methods) ...
    );
    sct_database.validation = struct();
    sct_database.validation.warningCount = sum(cellfun(@(v) numel(v.Warnings), cell_validation));
    sct_database.validation.errorCount   = sum(cellfun(@(v) numel(v.Errors), cell_validation));
    sct_database.validation.classes      = cell_validation;
    str_json       = jsonencode(sct_database, 'PrettyPrint', true);
    str_js_content = sprintf('window.GUILDA_DOC_INDEX = %s;\n', str_json);
    write_text_file(str_file_name, str_js_content);

    sct_manifest = struct( ...
        'name',     'GUILDA documentation manifest', ...
        'version',  5, ...
        'exporter', sct_scan.Tool, ...
        'files',    rmfield(sct_scan.Files, 'Changed'), ...
        'classes',  {cell_entries(bln_ok)});
    write_text_file(str_manifest, jsonencode(sct_manifest));

    sct_summary = struct( ...
        'ClassCount',    numel(cell_class_info), ...
        'ExportedCount', numel(iv_export), ...
        'WarningCount',  sct_database.validation.warningCount, ...
        'ErrorCount',    sct_database.validation.errorCount, ...
        'Coverage',      sct_database.coverage ...
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

function sct_entries = empty_entry_struct()
    sct_entries = struct('Name', {}, 'Origin', {}, 'File', {}, 'Js', {}, 'Files', {}, ...
        'Ancestors', {}, 'Info', {}, 'Validation', {}, 'Coverage', {});
end

function sct_manifest = read_manifest(str_file)
    sct_manifest = [];
    if ~isfile(str_file)
        return
    end
    try
        sct_manifest = jsondecode(fileread(str_file, 'Encoding', 'UTF-8'));
    catch
        sct_manifest = [];
        return
    end
    if ~isstruct(sct_manifest) || ~all(isfield(sct_manifest, {'exporter', 'files', 'classes'}))
        sct_manifest = [];
        return
    end
    if isempty(sct_manifest.files)
        sct_manifest.files = empty_file_state();
    end
    if isempty(sct_manifest.classes)
        sct_manifest.classes = empty_entry_struct();
    elseif iscell(sct_manifest.classes)
        % jsondecode returns a cell when the entries differ in shape.
        sct_manifest = [];
    end
end

function sct_files = empty_file_state()
    sct_files = struct('Path', {}, 'Hash', {}, 'Tracked', {});
end

function cell_changed = get_changed_files(sct_old_files, sct_new_files)
    % Tracked paths added, removed or with other content than in the manifest.
    sct_old_files = sct_old_files([sct_old_files.Tracked]);
    sct_new_files = sct_new_files([sct_new_files.Tracked]);
    cell_old = {sct_old_files.Path};
    cell_new = {sct_new_files.Path};
    [bln_known, iv_old] = ismember(cell_new, cell_old);
    bln_changed = ~bln_known;
    for i_file = find(bln_known)
        bln_changed(i_file) = ~strcmp(sct_new_files(i_file).Hash, sct_old_files(iv_old(i_file)).Hash);
    end
    cell_changed = [cell_new(bln_changed), setdiff(cell_old, cell_new)];
end

function cell_files = get_class_files(sct_class, sct_files)
    % The classdef file, or every .m file of the @Class folder.
    [str_dir, ~] = fileparts(sct_class.File);
    [~, str_dir_name] = fileparts(str_dir);
    if startsWith(str_dir_name, '@')
        cell_all = {sct_files.Path};
        cell_files = cell_all(startsWith(cell_all, [str_dir, filesep]));
    else
        cell_files = {sct_class.File};
    end
end

function cell_row = cellstr_row(val)
    % A list decoded from JSON: [] or a cell column.
    if isempty(val)
        cell_row = cell(1, 0);
    else
        cell_row = reshape(cellstr(val), 1, []);
    end
end

function str_js = get_js_path(sct_class)
    % Class JS file relative to _GUILDAdoc/database.
    switch sct_class.Origin
        case 'System', str_folder = 'GUILDAsystem';
        case 'Object', str_folder = 'GUILDAobject';
        otherwise,     str_folder = 'User';
    end
    str_js = [str_folder, '/', sct_class.Name, '.js'];
end

function cell_class_info = add_subclasses(cell_class_info)
    cell_names = cellfun(@(c) c.Name, cell_class_info, 'UniformOutput', false);
    cell_supers = cellfun(@(c) cellstr_row(c.Superclasses), cell_class_info, 'UniformOutput', false);
    for i_class = 1:numel(cell_class_info)
        bln_sub = cellfun(@(s) any(strcmp(s, cell_names{i_class})), cell_supers);
        cell_class_info{i_class}.Subclasses = cell_names(bln_sub);
    end
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
        if any(strcmp(cellstr_row(sct_i.Superclasses), 'PowerSystemModel'))
            cell_models{end+1} = sct_i.Name; %#ok<AGROW>
        end
    end
    cell_categories = [intersect(cell_preferred, cell_models, 'stable'), sort(setdiff(cell_models, cell_preferred))];
end

function write_text_file(str_file_name, str_content)
    str_folder = fileparts(str_file_name);
    if ~isfolder(str_folder)
        mkdir(str_folder);
    end
    file_id = fopen(str_file_name, 'w', 'n', 'UTF-8');
    if file_id < 0
        error('export_class_database:FileOpenFailed', 'Failed to open output file: %s', str_file_name);
    end
    fprintf(file_id, '%s', str_content);
    fclose(file_id);
end



%% Folder tree
function cell_tree = build_tree(sct_scan, sct_ctx)
    % One folder node per root, holding the .m files found by the scan.
    map_file  = containers.Map('KeyType', 'char', 'ValueType', 'char');
    map_class_dir = containers.Map('KeyType', 'char', 'ValueType', 'char');
    for i_class = 1:numel(sct_scan.Classes)
        sct_class = sct_scan.Classes(i_class);
        map_file(sct_class.File) = sct_class.Name;
        [str_dir, ~] = fileparts(sct_class.File);
        [~, str_dir_name] = fileparts(str_dir);
        if startsWith(str_dir_name, '@')
            map_class_dir(str_dir) = sct_class.Name;
        end
    end
    sct_link = struct('file', map_file, 'class_dir', map_class_dir);

    cell_tree = cell(1, 0);
    cell_all = {sct_scan.Files.Path};
    for i_root = 1:numel(sct_scan.Roots)
        sct_root = sct_scan.Roots(i_root);
        cell_files = cell_all(startsWith(cell_all, [sct_root.Path, filesep]));
        if isempty(cell_files) && strcmp(sct_root.Origin, 'User')
            continue
        end
        cell_tree{end+1} = build_folder_node(sct_root.Name, sct_root.Path, cell_files, sct_link, sct_ctx); %#ok<AGROW>
    end
end

function sct_node = build_folder_node(str_name, str_folder, cell_files, sct_link, sct_ctx)
    n_skip = numel(str_folder) + 2;
    cell_rest = cellfun(@(f) f(n_skip:end), cell_files, 'UniformOutput', false);
    bln_direct = ~contains(cell_rest, filesep);

    cell_children = cell(1, 0);
    cell_sub = reshape(unique(cellfun(@(r) extractBefore(r, filesep), cell_rest(~bln_direct), 'UniformOutput', false)), 1, []);
    [~, iv_order] = sort(lower(cell_sub));
    for str_sub = cell_sub(iv_order)
        bln_in = startsWith(cell_rest, [str_sub{1}, filesep]);
        cell_children{end+1} = build_folder_node(str_sub{1}, fullfile(str_folder, str_sub{1}), ...
            cell_files(bln_in), sct_link, sct_ctx); %#ok<AGROW>
    end
    cell_direct = reshape(cell_files(bln_direct), 1, []);
    [~, iv_order] = sort(lower(cell_direct));
    for str_file = cell_direct(iv_order)
        cell_children{end+1} = build_file_node(str_file{1}, sct_link, sct_ctx); %#ok<AGROW>
    end
    sct_node = struct('Name', str_name, 'Kind', 'folder', 'Path', relative_path(str_folder, sct_ctx), ...
        'Children', {cell_children});
end

function sct_node = build_file_node(str_file, sct_link, sct_ctx)
    [str_dir, str_base, str_ext] = fileparts(str_file);
    sct_node = struct('Name', [str_base, str_ext], 'Kind', 'file', 'Path', relative_path(str_file, sct_ctx), ...
        'Children', {cell(1, 0)});
    if isKey(sct_link.file, str_file)
        sct_node.Class = sct_link.file(str_file);
    elseif isKey(sct_link.class_dir, str_dir)
        sct_node.Class  = sct_link.class_dir(str_dir);
        sct_node.Method = str_base;
    else
        [str_parent, str_dir_name] = fileparts(str_dir);
        if strcmp(str_dir_name, 'private') && isKey(sct_link.class_dir, str_parent)
            sct_node.Class = sct_link.class_dir(str_parent);
        end
    end
end



function [sct_info, sct_validation, sct_coverage] = export_class_doc(str_class_name, sct_ctx)
    % Combine MATLAB reflection (meta.class) with the comments in the
    % source files and write one JavaScript file for the class.
    meta_class = get_meta_class(str_class_name, sct_ctx);
    if isempty(meta_class)
        error('export_class_database:ClassNotFound', 'Class not found on the MATLAB path: %s', str_class_name);
    end

    sct_doc_data = struct( ...
        'schema', struct('name', 'GUILDA class document', 'version', 5), ...
        'ClassName', str_class_name, ...
        'properties', [], ...
        'methods', [], ...
        'events', [], ...
        'enumeration', [], ...
        'validation', struct('Warnings', {{}}, 'Errors', {{}}) ...
    );
    [cell_props, cell_prop_diagnostics, rv_prop_cov] = build_meta_section(meta_class.PropertyList, str_class_name, "property", sct_ctx);
    [cell_methods, cell_method_diagnostics, rv_method_cov] = build_meta_section(meta_class.MethodList, str_class_name, "method", sct_ctx);
    sct_doc_data.properties  = cell_props;
    sct_doc_data.methods     = cell_methods;
    sct_doc_data.events      = build_name_list(meta_class.EventList, sct_ctx);
    sct_doc_data.enumeration = build_name_list(meta_class.EnumerationMemberList, sct_ctx);
    [sct_info, cell_class_diagnostics] = build_class_info(str_class_name, meta_class, sct_ctx);
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
    str_js = get_js_path(struct('Name', str_class_name, 'Origin', sct_ctx.origins(str_class_name)));
    str_file_name  = fullfile(sct_ctx.root, '_GUILDAdoc', 'database', strrep(str_js, '/', filesep));
    sct_info.path  = ['./database/', str_js];
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
    if ~isKey(sct_ctx.guilda, str_class_name)
        str_file = which(str_class_name);
        sct_ctx.guilda(str_class_name) = ~isempty(str_file) && startsWith(str_file, sct_ctx.root);
    end
    bln_guilda = sct_ctx.guilda(str_class_name);
end

function meta_class = get_meta_class(str_class_name, sct_ctx)
    if ~isKey(sct_ctx.metas, str_class_name)
        sct_ctx.metas(str_class_name) = meta.class.fromName(str_class_name);
    end
    meta_class = sct_ctx.metas(str_class_name);
end

function str_file = get_class_file(str_class_name, sct_ctx)
    if isKey(sct_ctx.files, str_class_name)
        str_file = sct_ctx.files(str_class_name);
    else
        str_file = which(str_class_name);
    end
end

function str_rel = relative_path(str_file, sct_ctx)
    % Relative to the GUILDA root with "/"; absolute outside it (User).
    str_rel = '';
    if isempty(str_file)
        return
    end
    if startsWith(str_file, [sct_ctx.root, filesep])
        str_rel = str_file(numel(sct_ctx.root)+2:end);
    else
        str_rel = str_file;
    end
    str_rel = strrep(str_rel, '\', '/');
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

function [cell_section, cell_diagnostics, rv_coverage] = build_meta_section(meta_list, str_class_name, str_kind, sct_ctx)
    cell_section = cell(1, 0);
    cell_diagnostics = cell(0,1);
    rv_coverage = [0 0];
    for i_item = 1:numel(meta_list)
        meta_item = meta_list(i_item);
        str_defining = meta_item.DefiningClass.Name;
        if strcmp(meta_item.Name, 'empty') || ~is_guilda_class(str_defining, sct_ctx)
            continue
        end
        [sct_info_i, cell_diagnostics_i] = build_meta_info(meta_item, str_class_name, str_kind, sct_ctx);
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

function [sct_info, cell_diagnostics] = build_meta_info(meta_item, str_class_name, str_kind, sct_ctx)
    str_member   = meta_item.Name;
    str_defining = meta_item.DefiningClass.Name;
    str_def_file = get_class_file(str_defining, sct_ctx);
    sct_class_src = get_source(str_def_file, "classdef", sct_ctx);

    if str_kind == "property"
        sct_info = struct( ...
            'Name',      str_member, ...
            'Defining',  str_defining, ...
            'Group',     '', ...
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
            'Unit',      '', ...
            'File',      relative_path(str_def_file, sct_ctx), ...
            'Line',      0 ...
            );
        str_raw_help = '';
        if isKey(sct_class_src.props, str_member)
            sct_decl = sct_class_src.props(str_member);
            str_raw_help = sct_decl.Comment;
            if isempty(strtrim(str_raw_help))
                str_raw_help = sct_decl.Inline;
            end
            sct_info.Group = sct_decl.Group;
            sct_info.Line  = sct_decl.Line;
            sct_info.DefaultCode = sct_decl.Entry.Default;
            if isempty(sct_info.Validation.Class) && isempty(sct_info.Validation.Size)
                sct_info.Validation = struct('Class', sct_decl.Entry.Class, 'Size', sct_decl.Entry.Size, ...
                    'Validators', {split_validators(sct_decl.Entry.Validators)});
            end
        else
            sct_info.Group = access_group_label(sct_info);
            if ~sct_class_src.found
                str_raw_help = sanitize_help_text(try_help(str_class_name + "." + string(str_member)));
            end
        end
        [sct_info.Unit, str_raw_help] = take_unit(str_raw_help);
    else
        bln_constructor = strcmp(str_member, short_class_name(str_defining));
        sct_info = struct( ...
            'Name',      str_member, ...
            'Defining',  str_defining, ...
            'Group',     method_group(str_member, bln_constructor), ...
            'Access',    organize_access(meta_item.Access), ...
            'Static',    meta_item.Static, ...
            'Abstract',  meta_item.Abstract, ...
            'Sealed',    meta_item.Sealed, ...
            'Hidden',    meta_item.Hidden, ...
            'IsConstructor', bln_constructor, ...
            'InputNames',  {reshape(cellstr(meta_item.InputNames), 1, [])}, ...
            'OutputNames', {reshape(cellstr(meta_item.OutputNames), 1, [])}, ...
            'Arguments', {cell(1, 0)}, ...
            'Outputs',   {cell(1, 0)}, ...
            'Signature', '', ...
            'File',      '', ...
            'Line',      0, ...
            'ImplementedIn', '', ...
            'Overrides', get_overrides(str_member, str_defining, bln_constructor, sct_ctx), ...
            'Throws',    {cell(1, 0)} ...
            );
        [str_raw_help, sct_fn, str_src_file, sct_info.ImplementedIn, sct_info.Line] = ...
            get_method_source(str_member, str_def_file, sct_class_src, sct_ctx);
        sct_info.File = relative_path(str_src_file, sct_ctx);
        if isempty(sct_fn) && ~meta_item.Abstract
            sct_info.ImplementedIn = '';
        end
        if ~isempty(sct_fn)
            if ~isempty(sct_fn.Inputs),  sct_info.InputNames  = sct_fn.Inputs;  end
            if ~isempty(sct_fn.Outputs), sct_info.OutputNames = sct_fn.Outputs; end
            sct_info.Arguments = num2cell(sct_fn.Arguments);
            sct_info.Outputs   = num2cell(sct_fn.OutputArguments);
            sct_info.Throws    = sct_fn.Throws;
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
    [sct_info, cell_diagnostics] = apply_help_tags(sct_info, str_raw_help, str_kind, str_context, sct_ctx.strict);

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
        if ~sct_info.Abstract && ~sct_info.IsConstructor && isempty(sct_fn)
            cell_diagnostics{end+1,1} = sprintf('WARNING: %s: method is declared but no implementation was found.', str_context);
        end
    end
end

function str_group = method_group(str_member, bln_constructor)
    % Verb prefix of the name: set_x -> "set"; "Other" without one.
    if bln_constructor
        str_group = 'Constructor';
        return
    end
    str_group = regexp(str_member, '^[A-Za-z][A-Za-z0-9]*(?=_)', 'match', 'once');
    if isempty(str_group)
        str_group = 'Other';
    end
end

function str_group = access_group_label(sct_info)
    % Group of a property without a source declaration: its attributes.
    cell_attr = {};
    if ~strcmp(sct_info.GetAccess, 'public'), cell_attr{end+1} = ['GetAccess = ', sct_info.GetAccess]; end
    if ~strcmp(sct_info.SetAccess, 'public'), cell_attr{end+1} = ['SetAccess = ', sct_info.SetAccess]; end
    if sct_info.Constant,  cell_attr{end+1} = 'Constant';  end
    if sct_info.Dependent, cell_attr{end+1} = 'Dependent'; end
    if isempty(cell_attr)
        str_group = 'Public';
    else
        str_group = strjoin(cell_attr, ', ');
    end
end

function str_overrides = get_overrides(str_member, str_defining, bln_constructor, sct_ctx)
    % Nearest GUILDA ancestor of the defining class that defines the method.
    str_overrides = '';
    if bln_constructor
        return
    end
    str_key = [str_defining, '>', str_member];
    if isKey(sct_ctx.overrides, str_key)
        str_overrides = sct_ctx.overrides(str_key);
        return
    end
    meta_def = get_meta_class(str_defining, sct_ctx);
    if ~isempty(meta_def)
        for str_ancestor = get_ancestors(meta_def)
            if is_guilda_class(str_ancestor{1}, sct_ctx) ...
                    && any(strcmp(get_own_methods(str_ancestor{1}, sct_ctx), str_member))
                str_overrides = str_ancestor{1};
                break
            end
        end
    end
    sct_ctx.overrides(str_key) = str_overrides;
end

function cell_names = get_own_methods(str_class_name, sct_ctx)
    if ~isKey(sct_ctx.own_methods, str_class_name)
        meta_class = get_meta_class(str_class_name, sct_ctx);
        cell_names = {};
        if ~isempty(meta_class)
            meta_list = meta_class.MethodList;
            bln_own = arrayfun(@(m) strcmp(m.DefiningClass.Name, str_class_name), meta_list);
            cell_names = {meta_list(bln_own).Name};
        end
        sct_ctx.own_methods(str_class_name) = cell_names;
    end
    cell_names = sct_ctx.own_methods(str_class_name);
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

function [str_help, sct_fn, str_src_file, str_where, r_line] = get_method_source(str_member, str_def_file, sct_class_src, sct_ctx)
    % Method comments are read from, in order:
    %   1. the method file @Class/<method>.m (comment lines after "function"),
    %   2. a function defined inside the classdef file (same rule),
    %   3. @Class/private/<method>.m for a declared method implemented there,
    %   4. comment lines above a signature declared in a methods block.
    % str_where is "file", "classdef" or "private" (ImplementedIn).
    str_help = '';
    sct_fn = [];
    str_src_file = '';
    str_where = '';
    r_line = 0;
    [str_dir, ~] = fileparts(str_def_file);
    [~, str_dir_name] = fileparts(str_dir);
    str_method_file = fullfile(str_dir, [str_member, '.m']);
    if startsWith(str_dir_name, '@') && isfile(str_method_file) && ~strcmp(str_method_file, str_def_file)
        sct_fn = get_source(str_method_file, "function", sct_ctx);
        str_src_file = str_method_file;
        str_where = 'file';
    elseif isKey(sct_class_src.funcs, str_member)
        sct_fn = sct_class_src.funcs(str_member);
        str_src_file = str_def_file;
        str_where = 'classdef';
    elseif startsWith(str_dir_name, '@') && isfile(fullfile(str_dir, 'private', [str_member, '.m']))
        str_src_file = fullfile(str_dir, 'private', [str_member, '.m']);
        sct_fn = get_source(str_src_file, "function", sct_ctx);
        str_where = 'private';
    end
    if ~isempty(sct_fn)
        str_help = sct_fn.Comment;
        r_line = sct_fn.Line;
    end
    if isKey(sct_class_src.decls, str_member)
        sct_decl = sct_class_src.decls(str_member);
        if isempty(strtrim(str_help))
            str_help = sct_decl.Comment;
        end
        if isempty(str_where)
            % Declared only (abstract, or the implementation is missing).
            str_src_file = str_def_file;
            str_where = 'classdef';
            r_line = sct_decl.Line;
        end
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

function [sct_info, cell_diagnostics] = build_class_info(str_class_name, meta_class, sct_ctx)
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
    % Folder: where the class lives on the path (the parent of @Class).
    str_folder = fileparts(str_file);
    [str_parent, str_dir_name] = fileparts(str_folder);
    if startsWith(str_dir_name, '@')
        str_folder = str_parent;
    end
    str_origin = '';
    if isKey(sct_ctx.origins, str_class_name)
        str_origin = sct_ctx.origins(str_class_name);
    end
    sct_src = get_source(str_file, "classdef", sct_ctx);

    sct_info = struct( ...
        'Name',         str_class_name, ...
        'Origin',       str_origin, ...
        'Folder',       relative_path(str_folder, sct_ctx), ...
        'Category',     str_package, ...
        'Type',         str_type, ...
        'Model',        str_model, ...
        'Parent',       strjoin(cell_supers, ', '), ...
        'Superclasses', {cell_supers}, ...
        'Ancestors',    {cell_ancestors}, ...
        'Subclasses',   {cell(1, 0)}, ...
        'Package',      str_package, ...
        'File',         relative_path(str_file, sct_ctx), ...
        'Line',         sct_src.ClassLine, ...
        'Abstract',     meta_class.Abstract, ...
        'Sealed',       meta_class.Sealed, ...
        'Hidden',       meta_class.Hidden ...
    );
    str_help = sct_src.ClassComment;
    if isempty(strtrim(str_help)) && ~sct_src.found
        str_help = sanitize_help_text(try_help(str_class_name));
    end
    % meta.class.Description is only used without a readable source file:
    % it would turn a section line such as "%% Properties" into a summary.
    if isempty(strtrim(str_help)) && ~sct_src.found
        str_help = sanitize_help_text([meta_class.Description, newline, meta_class.DetailedDescription]);
    end
    [sct_info, cell_diagnostics] = apply_help_tags(sct_info, str_help, "class", str_class_name, sct_ctx.strict);
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
        'ClassLine', 0, ...
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
    sct_src.ClassLine = idx_classdef;
    [sct_src.ClassComment, i] = collect_following_comment_lines(cell_lines, idx_classdef + 1);

    str_state = 'class';
    str_group = '';
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
                str_block = regexp(str_code, '^(properties|methods|events|enumeration)\>(.*)$', 'tokens', 'once');
                if ~isempty(str_block)
                    str_state = str_block{1};
                    % "properties (SetAccess = protected) % Parameters"
                    str_group = strtrim(str_comment);
                    if isempty(str_group)
                        str_group = attribute_label(str_block{2});
                    end
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
                i_decl = i;
                [str_decl, str_inline, i] = join_continued_lines(cell_lines, i);
                sct_entry = parse_declaration(str_decl);
                if ~isempty(sct_entry.Name)
                    sct_src.props(sct_entry.Name) = struct( ...
                        'Comment', normalize_comment_lines(cell_buffer), ...
                        'Inline',  strtrim(str_inline), ...
                        'Group',   str_group, ...
                        'Line',    i_decl, ...
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
                    i_decl = i;
                    [str_decl, ~, i] = join_continued_lines(cell_lines, i);
                    sct_header = parse_function_header(['function ', str_decl]);
                    if ~isempty(sct_header.Name)
                        sct_src.decls(sct_header.Name) = struct( ...
                            'Comment', normalize_comment_lines(cell_buffer), 'Line', i_decl);
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

function str_label = attribute_label(str_attributes)
    % "(SetAccess = protected, Hidden)" -> 'SetAccess = protected, Hidden';
    % no attributes -> 'Public'.
    str_label = strtrim(regexprep(strtrim(str_attributes), '^\((.*)\)$', '$1'));
    str_label = regexprep(str_label, '\s*=\s*', ' = ');
    str_label = regexprep(str_label, '\s*,\s*', ', ');
    if isempty(str_label)
        str_label = 'Public';
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
    % Local functions of a method file are only reachable from the method.
    sct_fn.Throws = find_error_ids(cell_lines(idx_function:end));
end

function sct_fn = empty_function_info()
    sct_fn = struct('Name', '', 'Inputs', {cell(1, 0)}, 'Outputs', {cell(1, 0)}, ...
        'Comment', '', 'Arguments', empty_argument_struct(), ...
        'OutputArguments', empty_argument_struct(), 'Line', 0, 'Throws', {cell(1, 0)});
end

function [sct_fn, i_next] = parse_function_at(cell_lines, i_function)
    % Read "function ..." at i_function, the comment block after it, and the
    % arguments blocks; i_next is the line after the function's end.
    [str_header, ~, i] = join_continued_lines(cell_lines, i_function);
    sct_fn = parse_function_header(str_header);
    sct_fn.Line = i_function;
    [sct_fn.Comment, i] = collect_following_comment_lines(cell_lines, i);
    sct_args = parse_arguments_blocks(cell_lines, i);
    bln_output = strcmp({sct_args.Kind}, 'Output');
    sct_fn.Arguments       = sct_args(~bln_output);
    sct_fn.OutputArguments = sct_args(bln_output);
    i_next = skip_function_body(cell_lines, i_function);
    sct_fn.Throws = find_error_ids(cell_lines(i_function:min(i_next-1, numel(cell_lines))));
end

function cell_ids = find_error_ids(cell_lines)
    % IDs of error('pkg:id', ...) and MException('pkg:id', ...); an
    % error() with a single text argument has no ID.
    cell_ids = cell(1, 0);
    for i_line = find(contains(cell_lines, {'error', 'MException'}))
        str_code = split_code_comment(cell_lines{i_line});
        cell_tok = regexp(str_code, ...
            '(?<![\w.])(?:error|MException)\s*\(\s*([''"])([A-Za-z][\w-]*(?::[\w-]+)+)\1\s*,', 'tokens');
        cell_ids = [cell_ids, cellfun(@(t) t{2}, cell_tok, 'UniformOutput', false)]; %#ok<AGROW>
    end
    if numel(cell_ids) > 1
        cell_ids = unique(cell_ids, 'stable');
    end
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
        if contains(str_code, 'Output')
            str_block = 'Output';
        elseif contains(str_code, 'Repeating')
            str_block = 'Repeating';
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
    [str_unit, str_description] = take_unit(str_description);
    sct_arg = struct( ...
        'Name', str_name, ...
        'Kind', str_kind, ...
        'Struct', str_struct, ...
        'Size', sct_entry.Size, ...
        'Class', sct_entry.Class, ...
        'Validators', {split_validators(sct_entry.Validators)}, ...
        'Default', sct_entry.Default, ...
        'Required', strcmp(str_kind, 'Positional') && isempty(sct_entry.Default), ...
        'Unit', str_unit, ...
        'Description', str_description ...
    );
end

function sct_args = empty_argument_struct()
    sct_args = struct('Name', {}, 'Kind', {}, 'Struct', {}, 'Size', {}, 'Class', {}, ...
        'Validators', {}, 'Default', {}, 'Required', {}, 'Unit', {}, 'Description', {});
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



%% Help text and tags
function [sct_info, cell_diagnostics] = apply_help_tags(sct_info, str_raw_help, str_kind, str_context, bln_strict)
    % Summary, Desc and SeeAlso come from the help text; the tags of the
    % kind (get_tag_schema) are added as fields, '' when absent.
    sct_schema = get_tag_schema();
    cell_tags  = sct_schema.(char(str_kind));
    [sct_parsed_tags, cell_source_tags, str_preamble] = parse_tagged_help(str_raw_help);
    cell_diagnostics = cell(0,1);

    % Removed tags are errors under "strict" and warnings otherwise, and
    % say what replaces them.
    sct_removed = sct_schema.removed;
    if bln_strict
        str_level = 'ERROR';
    else
        str_level = 'WARNING';
    end
    if isempty(cell_source_tags)
        cell_unique_tags = {};
    else
        cell_unique_tags = unique(cell_source_tags, 'stable');
    end
    cell_removed_used = cell_unique_tags(isfield(sct_removed, cell_unique_tags));
    for i_tag = 1:numel(cell_removed_used)
        cell_diagnostics{end+1,1} = sprintf( ...
            '%s: %s: <@%s> is no longer supported; %s.', ...
            str_level, str_context, cell_removed_used{i_tag}, sct_removed.(cell_removed_used{i_tag})); %#ok<AGROW>
    end

    cell_unknown_tags = cell_unique_tags(~ismember(cell_unique_tags, [cell_tags(:); cell_removed_used(:)]));
    for i_tag = 1:numel(cell_unknown_tags)
        cell_diagnostics{end+1,1} = sprintf( ...
            'WARNING: %s: unknown %s tag <@%s>.', ...
            str_context, str_kind, cell_unknown_tags{i_tag}); %#ok<AGROW>
    end

    for i_tag = 1:numel(cell_unique_tags)
        if sum(strcmp(cell_source_tags, cell_unique_tags{i_tag})) > 1
            cell_diagnostics{end+1,1} = sprintf( ...
                'WARNING: %s: duplicate tag <@%s>; the last value is used.', ...
                str_context, cell_unique_tags{i_tag}); %#ok<AGROW>
        end
    end

    % Untagged text: H1 line, body and "See also" line. The removed
    % Summary, Desc and Notes tags still fill in while sources move to the
    % conventions; they are reported above.
    [str_summary, str_desc, cell_see_also] = split_help_text(str_preamble);
    if isempty(str_summary) && isfield(sct_parsed_tags, 'Summary')
        str_summary = strtrim(sct_parsed_tags.Summary);
    end
    if isempty(str_desc) && isfield(sct_parsed_tags, 'Desc')
        [str_first, str_rest, cell_see_tagged] = split_help_text(sct_parsed_tags.Desc);
        str_desc = strtrim(strjoin({str_first, str_rest}, newline));
        cell_see_also = [cell_see_also, cell_see_tagged];
    end
    if isfield(sct_parsed_tags, 'Notes') && ~isempty(strtrim(sct_parsed_tags.Notes))
        str_desc = strtrim(strjoin({str_desc, strtrim(sct_parsed_tags.Notes)}, [newline, newline]));
    end
    sct_info.Summary = str_summary;
    sct_info.Desc    = str_desc;
    if numel(cell_see_also) > 1
        cell_see_also = unique(cell_see_also, 'stable');
    end
    sct_info.SeeAlso = cell_see_also;

    for i_tag = 1:numel(cell_tags)
        str_tag_name = cell_tags{i_tag};
        if isfield(sct_parsed_tags, str_tag_name)
            sct_info.(str_tag_name) = sct_parsed_tags.(str_tag_name);
        else
            sct_info.(str_tag_name) = '';
        end
    end
end

function [str_summary, str_desc, cell_see_also] = split_help_text(str_text)
    % First non-empty line -> summary; the rest -> description, without
    % "See also" lines, which give the SeeAlso list.
    str_summary = '';
    str_desc = '';
    cell_see_also = cell(1, 0);
    cell_lines = regexp(char(str_text), '\n', 'split');

    bln_keep = true(size(cell_lines));
    i_line = 1;
    while i_line <= numel(cell_lines)
        cell_tok = regexp(cell_lines{i_line}, '^\s*See also\>:?(.*)$', 'tokens', 'once', 'ignorecase');
        if isempty(cell_tok)
            i_line = i_line + 1;
            continue
        end
        % "See also A, B," continues on the next line.
        str_list = strtrim(cell_tok{1});
        bln_keep(i_line) = false;
        while endsWith(str_list, ',') && i_line < numel(cell_lines) && ~isempty(strtrim(cell_lines{i_line+1}))
            i_line = i_line + 1;
            str_list = [str_list, ' ', strtrim(cell_lines{i_line})]; %#ok<AGROW>
            bln_keep(i_line) = false;
        end
        cell_items = regexp(str_list, '[,\s]+', 'split');
        cell_items = regexprep(cell_items, '\.$', '');
        cell_see_also = [cell_see_also, cell_items(~cellfun(@isempty, cell_items))]; %#ok<AGROW>
        i_line = i_line + 1;
    end
    cell_lines = cell_lines(bln_keep);

    i_first = find(~cellfun(@(s) isempty(strtrim(s)), cell_lines), 1, 'first');
    if isempty(i_first)
        return
    end
    str_summary = strtrim(cell_lines{i_first});
    str_desc = strtrim(strjoin(cell_lines(i_first+1:end), newline));
end

function [str_unit, str_text] = take_unit(str_text)
    % "[MVA] Base power." -> 'MVA', 'Base power.' (not a Markdown link "[a](b)").
    str_unit = '';
    cell_tok = regexp(str_text, '^\s*\[([^\]\n]+)\](?!\()[ \t]*', 'tokens', 'once');
    if isempty(cell_tok)
        return
    end
    str_unit = strtrim(cell_tok{1});
    str_text = regexprep(str_text, '^\s*\[[^\]\n]+\][ \t]*', '', 'once');
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


function sct_schema = get_tag_schema()
    % Tags read per kind, and removed tags with what replaces them.
    persistent sct_cached
    if ~isempty(sct_cached)
        sct_schema = sct_cached;
        return
    end
    sct_schema = struct();
    sct_schema.class    = {'Examples', 'Deprecated'};
    sct_schema.property = {'Type', 'Deprecated'};
    sct_schema.method   = {'Examples', 'Deprecated'};
    sct_schema.removed  = struct( ...
        'Summary',     'write the summary as the first comment line (H1 line)', ...
        'Desc',        'write the description as the comment lines after the H1 line', ...
        'Role',        'the role is derived from the class hierarchy', ...
        'Category',    'the category is derived from the package', ...
        'Constructor', 'document the constructor method and use <@Examples>', ...
        'Notes',       'write notes in the description', ...
        'SeeAlso',     'write a "See also A, B" line', ...
        'Since',       'record changes in the Update log', ...
        'Signatures',  'signatures are derived from the function line and arguments blocks', ...
        'Parameters',  'describe inputs with comments in an arguments block', ...
        'Returns',     'describe outputs with comments in an arguments (Output) block', ...
        'Calls',       'calls are no longer documented', ...
        'Throws',      'error IDs are collected from error(...) and MException(...) calls', ...
        'Size',        'state the size in the declaration', ...
        'Default',     'state the default value in the declaration', ...
        'Constraints', 'state constraints with validators in the declaration', ...
        'Unit',        'start the comment with the unit, e.g. "[MVA] Base power."', ...
        'Model',       'describe the model in the H1 line or the description', ...
        'Abst',        'write the summary as the first comment line (H1 line)', ...
        'Description', 'write the description as the comment lines after the H1 line', ...
        'varargin',    'describe inputs with comments in an arguments block', ...
        'varargout',   'describe outputs with comments in an arguments (Output) block', ...
        'DetailsCode', 'write details in the description', ...
        'Example',     'use <@Examples>', ...
        'Seealso',     'write a "See also A, B" line' ...
    );
    sct_cached = sct_schema;
end

function bln_public = is_public_access(str_access)
    str_access = lower(strtrim(char(string(str_access))));
    bln_public = strcmp(str_access, 'public') || isempty(str_access);
end
