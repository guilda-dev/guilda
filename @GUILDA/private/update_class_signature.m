function update_class_signature()

    tab_list        = GUILDA.dictionary("PowerSystemModel", "disp", false, "output", ["Component", "Branch"]);
    tab_comp_list   = tab_list{1};
    tab_branch_list = tab_list{2};

    disp(newline+" === Update Key List === ")
    disp(newline+"  @Component: ")
    [str_comp_cases,  str_comp_list  ] = make_class_signature(string(tab_comp_list.filename));
    disp(newline+"  @Branch: ")
    [str_branch_cases,str_branch_list] = make_class_signature(string(tab_branch_list.filename));

    str_GUILDApath         = GUILDA.pwd();
    str_path_add_component = fullfile(str_GUILDApath, '_GUILDAsystem', '@Bus', 'add_component');
    str_path_rep_component = fullfile(str_GUILDApath, '_GUILDAsystem', '@Bus', 'replace_component');
    str_path_add_branch    = fullfile(str_GUILDApath, '_GUILDAsystem', '@PowerNetwork', 'add_branch');

    update_signature(str_path_add_component, str_comp_list  , str_comp_cases  )
    update_signature(str_path_rep_component, str_comp_list  , str_comp_cases  )
    update_signature(str_path_add_branch   , str_branch_list, str_branch_cases)
end

function update_signature(str_filepath, str_list, str_cases)
    str_json_template      = string(fileread(str_filepath+".template"));
    str_json = replace(str_json_template,["___KEY_LIST___","___KEY_CASES___"], [str_list,str_cases]); 
    file_id = fopen(str_filepath+".m", 'w', 'n', 'UTF-8');
    fprintf(file_id, '%s', char(str_json));
    fclose(file_id);
end

function [str_cases,str_list] = make_class_signature(str_class)
    n_class = numel(str_class);
    str_key  = repmat("__",n_class,1);
    for i = 1:n_class
        str_keyi = string(eval(str_class(i) + ".key"));
        if ~isempty(str_keyi)
            str_key(i) = str_keyi;
        end
    end
    lv_noKey  = str_key=="__";
    str_class = str_class(~lv_noKey);
    str_key   = str_key( ~lv_noKey);
    str_list  = join("'"+str_key+"'", ",");
    n_keyword = strlength(str_key);
    n_maxword = max(n_keyword);
    str_cases = "";
    for i = 1:numel(str_class)
        padding   = string(repmat(' ', 1, n_maxword - n_keyword(i)+1));
        str_cases = str_cases + ...
        "        case '" + str_key(i) + "';" + padding + "mkInst = @" + str_class(i) +";"+ newline;

        disp( "  addkey: <key> "+str_key(i)+ padding + " --> <class> " + str_class(i))
    end
end