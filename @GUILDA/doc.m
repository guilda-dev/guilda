function doc(option)
% Open the GUILDA documentation in the browser.
%
% >> GUILDA.doc                        % rebuild the class reference if the source changed, then open
% >> GUILDA.doc("class", "PowerNetwork")
% >> GUILDA.doc("update", true)        % always rebuild
% >> GUILDA.doc("update", false)       % never rebuild
%
% update : "auto" (default) exports again the classes whose files changed
%          since the last export (see database/manifest.json), with their
%          descendants, and everything when the exporter changed. The scan
%          covers _GUILDAsystem, _GUILDAobject and user classes on the path.
%          true/"always" rebuilds everything; false/"never" skips the check.
    arguments
        option.update (1,1) string {mustBeMember(option.update, ["auto","always","never","true","false"])} = "auto"
        option.open   (1,1) logical = true
        option.strict (1,1) logical = false
        option.class  (1,1) string = ""
    end

    str_doc_root = fullfile(GUILDA.pwd(), '_GUILDAdoc');
    str_doc_path = fullfile(str_doc_root, 'index.html');
    str_doc_path = strrep(str_doc_path, '\\', '/');

    switch option.update
        case {"always", "true"}
            bln_update = true;
            sct_scan = find_doc_classes();
        case {"never", "false"}
            bln_update = false;
        otherwise
            [bln_update, str_reason, sct_scan] = is_database_stale(GUILDA.pwd());
            if bln_update
                fprintf('  Class reference is out of date (%s).\n', str_reason);
            end
    end

    if bln_update
        export_class_database(sct_scan, "strict", option.strict, ...
            "full", ismember(option.update, ["always", "true"]));
        str_doc_path_for_cmd = strrep(str_doc_path, '''', '''''');
        fprintf('  Document Page : <a href="matlab:web(''%s'', ''-browser'')">%s</a>\n', str_doc_path_for_cmd, '/_GUILDAdoc/index.html');
    end
    if option.open
        if strlength(option.class) == 0
            web(str_doc_path, '-browser')
        else
            open_class_page(str_doc_root, option.class)
        end
    end
end

function [bln_stale, str_reason, sct_scan] = is_database_stale(str_root)
    % Scan the source and user folders, reusing database/manifest.json for
    % unchanged files, and compare with the last export.
    bln_stale = true;
    str_db = fullfile(str_root, '_GUILDAdoc', 'database');
    sct_manifest = [];
    if isfile(fullfile(str_db, 'list_Classes.js')) && isfile(fullfile(str_db, 'manifest.json'))
        try
            sct_manifest = jsondecode(fileread(fullfile(str_db, 'manifest.json'), 'Encoding', 'UTF-8'));
        catch
            sct_manifest = [];
        end
    end
    if ~isstruct(sct_manifest) || ~all(isfield(sct_manifest, {'exporter', 'files', 'classes'}))
        sct_scan = find_doc_classes();
        str_reason = 'no database';
        return
    end
    sct_scan = find_doc_classes("cache", sct_manifest.files);

    if ~strcmp(sct_manifest.exporter, sct_scan.Tool)
        str_reason = 'the exporter was changed';
        return
    end
    % Only tracked files count (System, Object, and files in User roots).
    cell_old = {};
    if ~isempty(sct_manifest.files)
        sct_old_files = sct_manifest.files([sct_manifest.files.Tracked]);
        cell_old = {sct_old_files.Path};
    end
    sct_files = sct_scan.Files([sct_scan.Files.Tracked]);
    cell_new = {sct_files.Path};
    cell_changed = [cell_new([sct_files.Changed]), setxor(cell_old, cell_new)];
    if ~isempty(cell_changed)
        str_reason = sprintf('%s was added, removed or edited', strrep(cell_changed{1}, [str_root, filesep], ''));
        if numel(cell_changed) > 1
            str_reason = sprintf('%s and %d more', str_reason, numel(cell_changed) - 1);
        end
        return
    end
    cell_classes = {};
    if ~isempty(sct_manifest.classes)
        cell_classes = {sct_manifest.classes.Name};
    end
    cell_diff = setxor(cell_classes, {sct_scan.Classes.Name});
    if ~isempty(cell_diff)
        str_reason = sprintf('class %s was added or removed', cell_diff{1});
        return
    end
    bln_stale = false;
    str_reason = '';
end

function open_class_page(str_doc_root, str_class_name)
    str_class_path = fullfile(str_doc_root, 'class.html');
    str_class_path = strrep(str_class_path, '\\', '/');
    str_class_url = "file://" + str_class_path + "?class=" + str_class_name;

    % macOS removes URL parameters while handing a local file to an
    % external browser. Let a temporary page perform the final navigation.
    str_redirect_path = string(tempname) + ".html";
    str_redirect_html = "<!doctype html><meta charset=""utf-8"">" + ...
        "<script>location.replace(" + jsonencode(char(str_class_url)) + ");</script>";

    fid = fopen(str_redirect_path, 'w', 'n', 'UTF-8');
    if fid == -1
        error('GUILDA:doc:RedirectFile', ...
            'Unable to create the documentation redirect file.');
    end
    file_cleanup = onCleanup(@() fclose(fid));
    fprintf(fid, '%s', str_redirect_html);
    clear file_cleanup

    web(str_redirect_path, '-browser')
end
