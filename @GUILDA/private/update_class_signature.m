function update_class_signature()

    tab_list        = GUILDA.dictionary("PowerSystemModel", "disp", false, "output", ["Component", "Branch"]);
    tab_comp_list   = tab_list{1};
    tab_branch_list = tab_list{2};

    disp(newline+" === Update Key List === ")
    disp(newline+"  @Component: ")
    [s_comp_cases,  s_comp_list    ] = make_class_signature(string(tab_comp_list.filename));
    disp(newline+"  @Branch: ")
    [s_branch_cases,s_branch_list] = make_class_signature(string(tab_branch_list.filename));

    s_GUILDApath           = GUILDA.pwd();
    s_path_add_component   = fullfile(s_GUILDApath, '_GUILDAsystem', '@Bus', 'add_component');
    s_path_rep_component   = fullfile(s_GUILDApath, '_GUILDAsystem', '@Bus', 'replace_component');
    s_path_add_branch      = fullfile(s_GUILDApath, '_GUILDAsystem', '@PowerNetwork', 'add_branch');

    update_signature(s_path_add_component, s_comp_list    , s_comp_cases    )
    update_signature(s_path_rep_component, s_comp_list    , s_comp_cases    )
    update_signature(s_path_add_branch     , s_branch_list, s_branch_cases)

    % A new copy's first session cannot see the files written above without this
    rehash path
end

function update_signature(s_filepath, s_list, s_cases)
    s_json_template        = string(fileread(s_filepath+".template"));
    s_json = replace(s_json_template,["___KEY_LIST___","___KEY_CASES___"], [s_list,s_cases]); 
    % Unchanged content is not written again (keeps the file and its time stamp as they are)
    if isfile(s_filepath+".m") && string(fileread(s_filepath+".m", "Encoding", "UTF-8")) == s_json
        return
    end
    file_id = fopen(s_filepath+".m", 'w', 'n', 'UTF-8');
    fprintf(file_id, '%s', char(s_json));
    fclose(file_id);
end

function [s_cases,s_list] = make_class_signature(sv_class)
    n_class = numel(sv_class);
    sv_key   = repmat("__",n_class,1);
    for i = 1:n_class
        s_keyi = string(eval(sv_class(i) + ".key"));
        if ~isempty(s_keyi)
            sv_key(i) = s_keyi;
        end
    end
    lv_noKey  = sv_key=="__";
    sv_class  = sv_class(~lv_noKey);
    sv_key    = sv_key( ~lv_noKey);
    s_list    = join("'"+sv_key+"'", ",");
    n_keyword = strlength(sv_key);
    n_maxword = max(n_keyword);
    s_cases   = "";
    for i = 1:numel(sv_class)
        padding   = string(repmat(' ', 1, n_maxword - n_keyword(i)+1));
        s_cases   = s_cases + ...
        "        case '" + sv_key(i) + "';" + padding + "mkInst = @" + sv_class(i) +";"+ newline;

        disp( "  addkey: <key> "+sv_key(i)+ padding + " --> <class> " + sv_class(i))
    end
end