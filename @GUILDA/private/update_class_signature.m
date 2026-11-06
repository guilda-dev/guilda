function update_class_signature()

    tab_list        = GUILDA.dictionary("PowerSystemModel", "disp", false, "output", ["Component", "Branch", "LocalController", "GlobalController"]);
    tab_comp_list   = tab_list{1};
    tab_branch_list = tab_list{2};
    tab_lcon_list   = tab_list{3};
    tab_gcon_list   = tab_list{4};

    disp(newline+" === Update Key List === ")
    disp(newline+"  @Component: ")
    [s_comp_cases,  s_comp_list    ] = make_class_signature(string(tab_comp_list.filename));
    disp(newline+"  @Branch: ")
    [s_branch_cases,s_branch_list] = make_class_signature(string(tab_branch_list.filename));
    disp(newline+"  @LocalController: ")
    [s_lcon_cases,  s_lcon_list  ] = make_class_signature(string(tab_lcon_list.filename));
    disp(newline+"  @GlobalController: ")
    [s_gcon_cases,  s_gcon_list  ] = make_class_signature(string(tab_gcon_list.filename));

    s_systempath = fullfile(GUILDA.pwd(), '_GUILDAsystem');
    update_signature(fullfile(s_systempath, '@Bus')         , "add_component"    , s_comp_list  , s_comp_cases  )
    update_signature(fullfile(s_systempath, '@Bus')         , "replace_component", s_comp_list  , s_comp_cases  )
    update_signature(fullfile(s_systempath, '@PowerNetwork'), "add_branch"       , s_branch_list, s_branch_cases)
    update_signature(fullfile(s_systempath, '@Component')   , "add_local_controller" , s_lcon_list, s_lcon_cases)
    update_signature(fullfile(s_systempath, '@PowerNetwork'), "add_global_controller", s_gcon_list, s_gcon_cases)

    % A new copy's first session cannot see the files written above without this
    rehash path
end

function update_signature(s_classpath, s_name, s_list, s_cases)
    % The template is <class>/template/<name>.template; the generated method is <class>/<name>.m
    s_json_template = string(fileread(fullfile(s_classpath, "template", s_name+".template")));
    s_filepath      = fullfile(s_classpath, s_name);
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