function doc(option)
% Open the GUILDA documentation in the browser.
%
% >> GUILDA.doc                        % rebuild the class reference if the source changed, then open
% >> GUILDA.doc("class", "PowerNetwork")
% >> GUILDA.doc("update", true)        % always rebuild
% >> GUILDA.doc("update", false)       % never rebuild
%
% update : "auto" (default) rebuilds _GUILDAdoc/database when it is missing,
%          was written by an older exporter, or is older than any file in
%          _GUILDAsystem or _GUILDAobject. true/"always" and false/"never"
%          force the choice.
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
        case {"never", "false"}
            bln_update = false;
        otherwise
            [bln_update, str_reason] = is_database_stale(GUILDA.pwd());
            if bln_update
                fprintf('  Class reference is out of date (%s).\n', str_reason);
            end
    end

    if bln_update
        export_class_database(find_doc_classes(), "strict", option.strict);
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

function [bln_stale, str_reason] = is_database_stale(str_root)
    % Compare modification times: the index file against every file and
    % folder under the source roots (a folder's time changes when a file in
    % it is added, renamed or deleted) and against the exporter itself.
    bln_stale = true;
    str_index = fullfile(str_root, '_GUILDAdoc', 'database', 'list_Classes.js');
    if ~isfile(str_index)
        str_reason = 'no database';
        return
    end
    sct_index = dir(str_index);

    sct_sources = [ ...
        dir(fullfile(str_root, '_GUILDAsystem', '**')); ...
        dir(fullfile(str_root, '_GUILDAobject', '**')); ...
        dir(fullfile(str_root, '@GUILDA', 'private', 'export_class_database.m')); ...
        dir(fullfile(str_root, '@GUILDA', 'private', 'find_doc_classes.m')) ...
    ];
    sct_sources = sct_sources(~strcmp({sct_sources.name}, '..'));
    [r_newest, i_newest] = max([sct_sources.datenum]);
    if r_newest > sct_index.datenum
        str_reason = sprintf('%s was changed', fullfile(sct_sources(i_newest).folder, sct_sources(i_newest).name));
        str_reason = strrep(str_reason, [str_root, filesep], '');
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
