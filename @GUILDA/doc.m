function doc(option)
    arguments
        option.update (1,1) logical = false
        option.open   (1,1) logical = true
        option.strict (1,1) logical = false
    end

    str_doc_path = fullfile(GUILDA.pwd(), '_GUILDAdoc', 'index.html');
    str_doc_path = strrep(str_doc_path, '\\', '/');

    if option.update
        tab_class_list = GUILDA.dictionary("PowerSystemModel", "disp", false);
        export_class_database(["LayerPackage"; tab_class_list.filename], "strict", option.strict);
        export_update_log();
        str_doc_path_for_cmd = strrep(str_doc_path, '''', '''''');
        fprintf('  Document Page : <a href="matlab:web(''%s'', ''-browser'')">%s</a>\n', str_doc_path_for_cmd, '/_GUILDAdoc/index.html');
    end
    if option.open
        web(str_doc_path, '-browser')
    end
end
