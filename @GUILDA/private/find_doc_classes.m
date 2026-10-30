function sct_scan = find_doc_classes(option)
% Find the classes and source files documented by the class reference.
%
% System and Object classes are the classes MATLAB can reach under
% _GUILDAsystem and _GUILDAobject. The search follows MATLAB's path rules
% instead of a class tree, so new classes appear without changing this file:
%   - folders listed in @GUILDA/config/ListPath.txt under _GUILDAsystem or
%     _GUILDAobject are on the path,
%   - +pkg folders add a package prefix, @Class folders hold Class.m and
%     method files (and @Class/private),
%   - private folders and plain subfolders that are not on the path are
%     skipped (for example archive/ or history/ folders).
% User classes are found the same way in the other folders on the MATLAB
% path (not under matlabroot, not in GUILDA's own folders, not in add-ons).
% A user class is a classdef that inherits, directly or through other user
% classes, from a System or Object class; the superclass names are read
% from the classdef line, so nothing is evaluated.
%
% >> sct_scan = find_doc_classes()                  % System, Object and User
% >> sct_scan = find_doc_classes("user", false)     % System and Object only
% >> sct_scan = find_doc_classes("cache", sct_manifest.files)
%
% user  : also scan user folders (default true).
% cache : the files list of a previous scan (database/manifest.json). A file
%         whose size and time are unchanged is not read again; a file whose
%         time changed but whose size is the same is compared by checksum.
%
% Output struct:
%   Roots   : Name, Origin ("System"|"Object"|"User"), Path (absolute)
%   Classes : Name, File, Origin, Root (absolute root path), sorted by Name
%   Files   : every .m file in the scanned folders, with Path (absolute),
%             Time (POSIX seconds), Bytes, Hash, Classdef, Name (class name
%             on the classdef line), Supers, Changed (differs from cache),
%             Tracked (System/Object files and files under a User root;
%             only these concern the database)
%   Tool    : signature of the documentation tools; a change forces a full
%             rebuild of the database
    arguments
        option.user  (1,1) logical = true
        option.cache = []
    end

    str_root = GUILDA.pwd();
    sct_cache = make_cache(option.cache);

    sct_scan = struct();
    sct_scan.Roots   = struct('Name', {}, 'Origin', {}, 'Path', {});
    sct_scan.Classes = empty_class_struct();
    sct_scan.Files   = empty_file_struct();
    sct_scan.Tool    = get_tool_signature(str_root);

    % System and Object
    for str_origin = ["System", "Object"]
        str_root_path = fullfile(str_root, "_GUILDA" + lower(str_origin));
        if ~isfolder(str_root_path)
            continue
        end
        sct_scan.Roots(end+1) = struct('Name', char(str_origin), 'Origin', char(str_origin), 'Path', char(str_root_path));
        [sct_cls, sct_files] = scan_source_root(char(str_root_path), ...
            get_source_path_folders(str_root, char(str_root_path)), sct_cache);
        [sct_cls.Origin] = deal(char(str_origin));
        [sct_cls.Root]   = deal(char(str_root_path));
        sct_scan.Classes = [sct_scan.Classes, sct_cls];
        sct_scan.Files   = [sct_scan.Files, sct_files];
    end
    sct_scan.Classes = sct_scan.Classes([sct_scan.Classes.Classdef]);
    [sct_scan.Files.Tracked] = deal(true);

    % User
    if option.user
        sct_scan = add_user_classes(sct_scan, str_root, sct_cache);
    end

    sct_scan.Classes = rmfield(sct_scan.Classes, {'Classdef', 'Supers'});
    if isempty(sct_scan.Classes)
        return
    end
    [~, iv_unique] = unique({sct_scan.Classes.Name}, 'stable');
    sct_scan.Classes = sct_scan.Classes(sort(iv_unique));
    [~, iv_order] = sort(lower({sct_scan.Classes.Name}));
    sct_scan.Classes = sct_scan.Classes(iv_order);
end

function cell_path = get_source_path_folders(str_root, str_root_path)
    % Path folders under one root, the root first.
    [~, str_root_name] = fileparts(str_root_path);
    str_list = fullfile(str_root, '@GUILDA', 'config', 'ListPath.txt');
    cell_list = {};
    if isfile(str_list)
        cell_list = strsplit(strtrim(fileread(str_list)));
    end
    cell_list = cell_list(strcmp(cell_list, str_root_name) | startsWith(cell_list, [str_root_name, '/']));
    cell_list = unique([{str_root_name}, cell_list], 'stable');
    cell_path = cellfun(@(p) fullfile(str_root, strrep(p, '/', filesep)), cell_list, 'UniformOutput', false);
    cell_path = cell_path(cellfun(@isfolder, cell_path));
end

function [sct_classes, sct_files] = scan_source_root(str_root_path, cell_path, sct_cache)
    % One recursive listing of the root, filtered by the path rules: a path
    % folder, then +pkg folders, then optionally @Class (and @Class/private).
    sct_classes = empty_class_struct();
    sct_files   = empty_file_struct();
    sct_list = dir(fullfile(str_root_path, '**', '*.m'));
    sct_list = sct_list(~startsWith({sct_list.name}, '.'));
    [cell_folders, ~, iv_folder] = unique({sct_list.folder});
    sct_kind = cellfun(@(f) classify_folder(f, cell_path), cell_folders);
    for i_item = 1:numel(sct_list)
        sct_k = sct_kind(iv_folder(i_item));
        if ~sct_k.Valid
            continue
        end
        [~, str_base] = fileparts(sct_list(i_item).name);
        bln_candidate = isempty(sct_k.Class) || (~sct_k.Private && strcmp(str_base, sct_k.Class));
        sct_file = read_file_entry(sct_list(i_item), bln_candidate, sct_cache);
        sct_files(end+1) = sct_file; %#ok<AGROW>
        if isempty(sct_k.Class)
            sct_classes(end+1) = make_class([sct_k.Package, str_base], sct_file); %#ok<AGROW>
        elseif bln_candidate
            sct_classes(end+1) = make_class([sct_k.Package, sct_k.Class], sct_file); %#ok<AGROW>
        end
    end
end

function sct_kind = classify_folder(str_folder, cell_path)
    sct_kind = struct('Valid', false, 'Package', '', 'Class', '', 'Private', false);
    bln_under = cellfun(@(p) strcmp(str_folder, p) || startsWith(str_folder, [p, filesep]), cell_path);
    if ~any(bln_under)
        return
    end
    str_base = cell_path{find(bln_under, 1, 'last')};
    cell_parts = strsplit(str_folder(numel(str_base)+1:end), filesep);
    cell_parts = cell_parts(~cellfun(@isempty, cell_parts));
    if ~isempty(cell_parts) && strcmp(cell_parts{end}, 'private')
        sct_kind.Private = true;
        cell_parts(end) = [];
        if isempty(cell_parts) || ~startsWith(cell_parts{end}, '@')
            return
        end
    end
    if ~isempty(cell_parts) && startsWith(cell_parts{end}, '@')
        sct_kind.Class = cell_parts{end}(2:end);
        cell_parts(end) = [];
    end
    if ~all(startsWith(cell_parts, '+'))
        return
    end
    sct_kind.Valid = true;
    sct_kind.Package = strjoin(cellfun(@(c) [c(2:end), '.'], cell_parts, 'UniformOutput', false), '');
end

function sct_scan = add_user_classes(sct_scan, str_root, sct_cache)
    cell_folders = get_user_path_folders(str_root);
    sct_cls_all = empty_class_struct();
    cell_folder_of = {};
    for i_folder = 1:numel(cell_folders)
        [sct_cls, sct_files] = scan_folder(cell_folders{i_folder}, '', sct_cache);
        [sct_files.Tracked] = deal(false);
        sct_cls = sct_cls([sct_cls.Classdef]);
        sct_cls_all = [sct_cls_all, sct_cls]; %#ok<AGROW>
        cell_folder_of = [cell_folder_of, repmat(cell_folders(i_folder), 1, numel(sct_cls))]; %#ok<AGROW>
        sct_scan.Files = [sct_scan.Files, sct_files];
    end
    if isempty(sct_cls_all)
        return
    end

    % A class shadowed by a System or Object class of the same name is not
    % a user class.
    bln_keep = ~ismember({sct_cls_all.Name}, {sct_scan.Classes.Name});
    sct_cls_all = sct_cls_all(bln_keep);
    cell_folder_of = cell_folder_of(bln_keep);

    % Inherits from GUILDA, directly or through other user classes.
    cell_known = {sct_scan.Classes.Name};
    bln_user = false(1, numel(sct_cls_all));
    bln_grew = true;
    while bln_grew
        bln_grew = false;
        for i_cls = find(~bln_user)
            if any(ismember(sct_cls_all(i_cls).Supers, cell_known))
                bln_user(i_cls) = true;
                cell_known{end+1} = sct_cls_all(i_cls).Name; %#ok<AGROW>
                bln_grew = true;
            end
        end
    end
    sct_cls_all = sct_cls_all(bln_user);
    cell_folder_of = cell_folder_of(bln_user);
    if isempty(sct_cls_all)
        return
    end

    % Root folders: path folders with user classes that are not inside
    % another such folder.
    cell_class_folders = unique(cell_folder_of, 'stable');
    for i_folder = 1:numel(cell_class_folders)
        str_folder = cell_class_folders{i_folder};
        bln_inside = any(cellfun(@(f) ~strcmp(f, str_folder) && startsWith(str_folder, [f, filesep]), cell_class_folders));
        if bln_inside
            continue
        end
        [~, str_name] = fileparts(str_folder);
        sct_scan.Roots(end+1) = struct('Name', str_name, 'Origin', 'User', 'Path', str_folder);
    end
    cell_roots = {sct_scan.Roots(strcmp({sct_scan.Roots.Origin}, 'User')).Path};
    % Changes to other user files (scripts, unrelated classes) do not
    % concern the database.
    for i_root = 1:numel(cell_roots)
        bln_in = startsWith({sct_scan.Files.Path}, [cell_roots{i_root}, filesep]);
        [sct_scan.Files(bln_in).Tracked] = deal(true);
    end
    for i_cls = 1:numel(sct_cls_all)
        str_folder = cell_folder_of{i_cls};
        i_root = find(cellfun(@(r) strcmp(r, str_folder) || startsWith(str_folder, [r, filesep]), cell_roots), 1, 'first');
        sct_cls_all(i_cls).Origin = 'User';
        sct_cls_all(i_cls).Root   = cell_roots{i_root};
    end
    sct_scan.Classes = [sct_scan.Classes, sct_cls_all];
end

function cell_folders = get_user_path_folders(str_root)
    % Folders on the MATLAB path that belong to the user: not MATLAB's own,
    % not GUILDA's own (in this or another copy of GUILDA), not add-ons.
    cell_folders = strsplit(path, pathsep);
    str_matlab = matlabroot;
    cell_folders = cell_folders(~cellfun(@isempty, cell_folders) & ~startsWith(cell_folders, str_matlab));
    bln_keep = true(size(cell_folders));
    for i_folder = 1:numel(cell_folders)
        str_folder = cell_folders{i_folder};
        cell_parts = strsplit(str_folder, {'/', '\'});
        bln_keep(i_folder) = ~is_under(str_folder, str_matlab) ...
            && ~is_under(str_folder, str_root) ...
            && ~any(startsWith(cell_parts, {'_GUILDA', '@GUILDA'})) ...
            && ~contains(str_folder, {'MATLAB Add-Ons', 'SupportPackages'}) ...
            && isfolder(str_folder);
    end
    cell_folders = cell_folders(bln_keep);
end

function bln = is_under(str_folder, str_parent)
    bln = strcmp(str_folder, str_parent) || startsWith(str_folder, [str_parent, filesep]);
end

function [sct_classes, sct_files] = scan_folder(str_folder, str_package, sct_cache)
    % Classes (with Classdef flag) and .m files of one path folder, its +pkg
    % folders and its @Class folders.
    sct_classes = empty_class_struct();
    sct_files   = empty_file_struct();
    sct_list = dir(str_folder);
    for i_item = 1:numel(sct_list)
        str_name = sct_list(i_item).name;
        if str_name(1) == '.'
            continue
        end
        str_path = fullfile(str_folder, str_name);
        if sct_list(i_item).isdir
            if str_name(1) == '+'
                [sct_cls, sct_f] = scan_folder(str_path, [str_package, str_name(2:end), '.'], sct_cache);
                sct_classes = [sct_classes, sct_cls]; %#ok<AGROW>
                sct_files   = [sct_files, sct_f]; %#ok<AGROW>
            elseif str_name(1) == '@'
                [sct_cls, sct_f] = scan_class_folder(str_path, [str_package, str_name(2:end)], sct_cache);
                sct_classes = [sct_classes, sct_cls]; %#ok<AGROW>
                sct_files   = [sct_files, sct_f]; %#ok<AGROW>
            end
            continue
        end
        [~, str_base, str_ext] = fileparts(str_name);
        if ~strcmp(str_ext, '.m')
            continue
        end
        sct_file = read_file_entry(sct_list(i_item), true, sct_cache);
        sct_files(end+1) = sct_file; %#ok<AGROW>
        sct_classes(end+1) = make_class([str_package, str_base], sct_file); %#ok<AGROW>
    end
end

function [sct_classes, sct_files] = scan_class_folder(str_folder, str_class, sct_cache)
    sct_classes = empty_class_struct();
    sct_files   = empty_file_struct();
    [~, str_short] = fileparts(str_folder);
    str_short = str_short(2:end);
    sct_list = [dir(fullfile(str_folder, '*.m')); dir(fullfile(str_folder, 'private', '*.m'))];
    for i_item = 1:numel(sct_list)
        bln_classdef_file = strcmp(sct_list(i_item).folder, str_folder) && strcmp(sct_list(i_item).name, [str_short, '.m']);
        sct_file = read_file_entry(sct_list(i_item), bln_classdef_file, sct_cache);
        sct_files(end+1) = sct_file; %#ok<AGROW>
        if bln_classdef_file
            sct_classes(end+1) = make_class(str_class, sct_file); %#ok<AGROW>
        end
    end
end

function sct_class = make_class(str_name, sct_file)
    sct_class = struct('Name', str_name, 'File', sct_file.Path, 'Origin', '', 'Root', '', ...
        'Classdef', sct_file.Classdef, 'Supers', {sct_file.Supers});
end

function sct_classes = empty_class_struct()
    sct_classes = struct('Name', {}, 'File', {}, 'Origin', {}, 'Root', {}, 'Classdef', {}, 'Supers', {});
end

function sct_files = empty_file_struct()
    sct_files = struct('Path', {}, 'Time', {}, 'Bytes', {}, 'Hash', {}, ...
        'Classdef', {}, 'Name', {}, 'Supers', {}, 'Changed', {}, 'Tracked', {});
end



%% File entries
function sct_cache = make_cache(val)
    % Path -> entry of the previous scan.
    sct_cache = containers.Map('KeyType', 'char', 'ValueType', 'any');
    if isempty(val) || ~isstruct(val)
        return
    end
    for i = 1:numel(val)
        sct_cache(val(i).Path) = val(i);
    end
end

function sct_file = read_file_entry(sct_dir, bln_candidate, sct_cache)
    % bln_candidate: the file may be a classdef file, so its first code line
    % is read for the class and superclass names.
    str_path = fullfile(sct_dir.folder, sct_dir.name);
    r_time   = round((sct_dir.datenum - 719529) * 86400);
    sct_file = struct('Path', str_path, 'Time', r_time, 'Bytes', sct_dir.bytes, 'Hash', '', ...
        'Classdef', false, 'Name', '', 'Supers', {cell(1, 0)}, 'Changed', true, 'Tracked', true);

    if isKey(sct_cache, str_path)
        sct_old = sct_cache(str_path);
        if sct_old.Bytes == sct_file.Bytes && (sct_old.Time == r_time ...
                || strcmp(sct_old.Hash, file_hash(read_bytes(str_path))))
            % Unchanged content: a file rewritten with the same text (for
            % example a generated file) only gets the new time.
            sct_file.Hash     = sct_old.Hash;
            sct_file.Classdef = logical(sct_old.Classdef);
            sct_file.Name     = sct_old.Name;
            if ~isempty(sct_old.Supers)
                sct_file.Supers = reshape(cellstr(sct_old.Supers), 1, []);
            end
            sct_file.Changed  = false;
            return
        end
    end

    u8_bytes = read_bytes(str_path);
    sct_file.Hash = file_hash(u8_bytes);
    if bln_candidate
        [sct_file.Classdef, sct_file.Name, sct_file.Supers] = parse_classdef_line(char(native2unicode(u8_bytes(:)', 'UTF-8')));
    end
end

function u8_bytes = read_bytes(str_path)
    u8_bytes = zeros(0, 1, 'uint8');
    file_id = fopen(str_path, 'r');
    if file_id < 0
        return
    end
    u8_bytes = fread(file_id, Inf, '*uint8');
    fclose(file_id);
end

function str_hash = file_hash(u8_bytes)
    % Two position-weighted sums; exact in double precision for files below
    % about 6 MB, enough to tell an edited file from a rewritten one.
    r_bytes = double(u8_bytes(:));
    n = numel(r_bytes);
    str_hash = sprintf('%d-%d', sum(r_bytes), sum(r_bytes .* (n:-1:1)'));
end

function [bln_classdef, str_name, cell_supers] = parse_classdef_line(str_text)
    % "classdef (Attributes) Name < Super1 & pkg.Super2" on the first code
    % line, with "..." continuations.
    bln_classdef = false;
    str_name = '';
    cell_supers = cell(1, 0);
    cell_lines = splitlines(str_text);
    str_code = '';
    for i_line = 1:numel(cell_lines)
        str_line = strtrim(regexprep(cell_lines{i_line}, '%.*$', ''));
        if isempty(str_line) && isempty(str_code)
            continue
        end
        str_code = [str_code, ' ', str_line]; %#ok<AGROW>
        if ~endsWith(str_line, '...')
            break
        end
        str_code = str_code(1:end-3);
    end
    str_code = strtrim(str_code);
    if isempty(regexp(str_code, '^classdef\>', 'once'))
        return
    end
    bln_classdef = true;
    str_rest = strtrim(regexprep(str_code, '^classdef\s*', '', 'once'));
    if startsWith(str_rest, '(')
        i_close = find(str_rest == ')', 1, 'first');
        if isempty(i_close), return, end
        str_rest = strtrim(str_rest(i_close+1:end));
    end
    cell_parts = strsplit(str_rest, '<');
    str_name = strtrim(cell_parts{1});
    if numel(cell_parts) > 1
        cell_supers = strtrim(strsplit(strjoin(cell_parts(2:end), '<'), '&'));
        cell_supers = cell_supers(~cellfun(@isempty, cell_supers));
    end
end

function str_signature = get_tool_signature(str_root)
    % Content checksums of the exporter and this file.
    cell_files = {'export_class_database.m', 'find_doc_classes.m'};
    cell_hash = cellfun(@(f) file_hash(read_bytes(fullfile(str_root, '@GUILDA', 'private', f))), ...
        cell_files, 'UniformOutput', false);
    str_signature = strjoin(cell_hash, '|');
end
