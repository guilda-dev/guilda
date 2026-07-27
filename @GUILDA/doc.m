function doc(option)
    arguments
        option.update (1,1) logical = false
        option.open   (1,1) logical = true
        option.strict (1,1) logical = false
        option.class  (1,1) string = ""
    end

    str_doc_root = fullfile(GUILDA.pwd(), '_GUILDAdoc');
    str_doc_path = fullfile(str_doc_root, 'index.html');
    str_doc_path = strrep(str_doc_path, '\\', '/');

    if option.update
        tab_po = GUILDA.dictionary("PowerSystemModel", "disp", false);
        tab_au = GUILDA.dictionary("auxiliary", "disp", false);
        export_class_database(["LayerPackage"; tab_au.filename; tab_po.filename], "strict", option.strict);
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
