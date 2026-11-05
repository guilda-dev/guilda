function doc(option)
% Open the GUILDA documentation in the browser.
%
% >> GUILDA.doc                        % rebuild the class reference if the source changed, then open
% >> GUILDA.doc("class", "PowerNetwork")
% >> GUILDA.doc("update", true)        % always rebuild
% >> GUILDA.doc("update", false)       % never rebuild
%
% With update "auto", the classes whose files changed since the last export
% (see database/manifest.json) are exported again with their descendants,
% and everything when the exporter changed. The scan covers _GUILDAsystem,
% _GUILDAobject and user classes on the path, and the class images
% @Class/image.svg.
    arguments (Input)
        option.update (1,1) string {mustBeMember(option.update, ["auto","always","never","true","false"])} = "auto"  % "auto" rebuilds changed classes; true/"always" rebuilds everything; false/"never" skips the check.
        option.open   (1,1) logical = true   % Open the page in the browser.
        option.strict (1,1) logical = false  % Removed tags are errors and errors stop the export.
        option.class  (1,1) string = ""      % Class whose reference page is opened; "" opens the top page.
    end

    s_doc_root   = fullfile(GUILDA.pwd(), '_GUILDAdoc');
    s_doc_path   = fullfile(s_doc_root, 'index.html');
    s_doc_path   = strrep(s_doc_path, '\\', '/');

    switch option.update
        case {"always", "true"}
            bln_update = true;
            sct_scan = find_doc_classes();
        case {"never", "false"}
            bln_update = false;
        otherwise
            [bln_update, s_reason, sct_scan] = is_database_stale(GUILDA.pwd());
            if bln_update
                fprintf('  Class reference is out of date (%s).\n', s_reason);
            end
    end

    if bln_update
        export_class_database(sct_scan, "strict", option.strict, ...
            "full", ismember(option.update, ["always", "true"]));
        s_doc_path_for_cmd = strrep(s_doc_path, '''', '''''');
        fprintf('  Document Page : <a href="matlab:web(''%s'', ''-browser'')">%s</a>\n', s_doc_path_for_cmd, '/_GUILDAdoc/index.html');
    end
    if option.open
        if strlength(option.class) == 0
            web(s_doc_path, '-browser')
        else
            open_class_page(s_doc_root, option.class)
        end
    end
end

function [bln_stale, s_reason, sct_scan] = is_database_stale(s_root)
    % Scan the source and user folders, reusing database/manifest.json for
    % unchanged files, and compare with the last export.
    bln_stale = true;
    s_db = fullfile(s_root, '_GUILDAdoc', 'database');
    sct_manifest = [];
    if isfile(fullfile(s_db, 'list_Classes.js')) && isfile(fullfile(s_db, 'manifest.json'))
        try
            sct_manifest = jsondecode(fileread(fullfile(s_db, 'manifest.json'), 'Encoding', 'UTF-8'));
        catch
            sct_manifest = [];
        end
    end
    if ~isstruct(sct_manifest) || ~all(isfield(sct_manifest, {'exporter', 'files', 'classes'}))
        sct_scan = find_doc_classes();
        s_reason = 'no database';
        return
    end
    sct_scan = find_doc_classes("cache", sct_manifest.files);

    if ~strcmp(sct_manifest.exporter, sct_scan.Tool)
        s_reason = 'the exporter was changed';
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
        s_reason = sprintf('%s was added, removed or edited', strrep(cell_changed{1}, [s_root, filesep], ''));
        if numel(cell_changed) > 1
            s_reason = sprintf('%s and %d more', s_reason, numel(cell_changed) - 1);
        end
        return
    end
    cell_classes = {};
    if ~isempty(sct_manifest.classes)
        cell_classes = {sct_manifest.classes.Name};
    end
    cell_diff = setxor(cell_classes, {sct_scan.Classes.Name});
    if ~isempty(cell_diff)
        s_reason = sprintf('class %s was added or removed', cell_diff{1});
        return
    end
    % Class images (@Class/image.svg) are not .m files: compare them apart.
    cell_old_images = {};
    if isfield(sct_manifest, 'images') && ~isempty(sct_manifest.images)
        cell_old_images = strcat({sct_manifest.images.Class}, '|', {sct_manifest.images.Hash});
    end
    cell_new_images = strcat({sct_scan.Images.Class}, '|', {sct_scan.Images.Hash});
    cell_diff = setxor(cell_old_images, cell_new_images);
    if ~isempty(cell_diff)
        s_reason = sprintf('the image of %s was added, removed or edited', extractBefore(cell_diff{1}, '|'));
        return
    end
    bln_stale = false;
    s_reason = '';
end

function open_class_page(s_doc_root, s_class_name)
    s_class_path   = fullfile(s_doc_root, 'class.html');
    s_class_path   = strrep(s_class_path, '\\', '/');
    s_class_url = "file://" + s_class_path + "?class=" + s_class_name;

    % macOS removes URL parameters while handing a local file to an
    % external browser. Let a temporary page perform the final navigation.
    s_redirect_path   = string(tempname) + ".html";
    s_redirect_html   = "<!doctype html><meta charset=""utf-8"">" + ...
        "<script>location.replace(" + jsonencode(char(s_class_url)) + ");</script>";

    fid = fopen(s_redirect_path, 'w', 'n', 'UTF-8');
    if fid == -1
        error(msg("GUILDA:doc:RedirectFile"));
    end
    file_cleanup = onCleanup(@() fclose(fid));
    fprintf(fid, '%s', s_redirect_html);
    clear file_cleanup

    web(s_redirect_path, '-browser')
end
