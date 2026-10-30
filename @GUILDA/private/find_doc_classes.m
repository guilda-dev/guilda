function sct_classes = find_doc_classes()
% Find every class that MATLAB can reach under the GUILDA source folders.
%
% The search follows MATLAB's path rules instead of a class tree, so new
% classes appear without changing this file:
%   - folders listed in @GUILDA/config/ListPath.txt under _GUILDAsystem or
%     _GUILDAobject are on the path,
%   - +pkg folders add a package prefix, @Class folders hold Class.m,
%   - private folders and plain subfolders that are not on the path are
%     skipped (for example archive/ or history/ folders).
%
% Output: struct array with fields Name (e.g. 'component.generator.park')
% and File (absolute path of the classdef file), sorted by Name.

    str_root  = GUILDA.pwd();
    cell_path = get_source_path_folders(str_root);

    sct_classes = struct('Name', {}, 'File', {});
    for i_path = 1:numel(cell_path)
        sct_classes = [sct_classes, scan_folder(cell_path{i_path}, '')]; %#ok<AGROW>
    end

    if isempty(sct_classes)
        return
    end
    [~, iv_unique] = unique({sct_classes.Name}, 'stable');
    sct_classes = sct_classes(sort(iv_unique));
    [~, iv_order] = sort(lower({sct_classes.Name}));
    sct_classes = sct_classes(iv_order);
end

function cell_path = get_source_path_folders(str_root)
    cell_roots = {'_GUILDAsystem', '_GUILDAobject'};
    str_list = fullfile(str_root, '@GUILDA', 'config', 'ListPath.txt');
    cell_list = {};
    if isfile(str_list)
        cell_list = strsplit(strtrim(fileread(str_list)));
    end
    cell_list = cell_list(startsWith(cell_list, cell_roots));
    cell_list = unique([cell_roots, cell_list], 'stable');
    cell_path = cellfun(@(p) fullfile(str_root, strrep(p, '/', filesep)), cell_list, 'UniformOutput', false);
    cell_path = cell_path(cellfun(@isfolder, cell_path));
end

function sct_classes = scan_folder(str_folder, str_package)
    sct_classes = struct('Name', {}, 'File', {});
    sct_list = dir(str_folder);
    for i_item = 1:numel(sct_list)
        str_name = sct_list(i_item).name;
        if str_name(1) == '.'
            continue
        end
        str_path = fullfile(str_folder, str_name);
        if sct_list(i_item).isdir
            if str_name(1) == '+'
                sct_classes = [sct_classes, scan_folder(str_path, [str_package, str_name(2:end), '.'])]; %#ok<AGROW>
            elseif str_name(1) == '@'
                str_class = str_name(2:end);
                str_file  = fullfile(str_path, [str_class, '.m']);
                if isfile(str_file) && is_classdef_file(str_file)
                    sct_classes(end+1) = struct('Name', [str_package, str_class], 'File', str_file); %#ok<AGROW>
                end
            end
            continue
        end
        [~, str_base, str_ext] = fileparts(str_name);
        if strcmp(str_ext, '.m') && is_classdef_file(str_path)
            sct_classes(end+1) = struct('Name', [str_package, str_base], 'File', str_path); %#ok<AGROW>
        end
    end
end

function bln_classdef = is_classdef_file(str_file)
    bln_classdef = false;
    try
        cell_lines = splitlines(string(fileread(str_file)));
    catch
        return
    end
    for i_line = 1:numel(cell_lines)
        str_line = strtrim(cell_lines(i_line));
        if strlength(str_line) == 0 || startsWith(str_line, '%')
            continue
        end
        bln_classdef = ~isempty(regexp(str_line, '^classdef\>', 'once'));
        return
    end
end
