function tab_out = dictionary(headword,opt)
% Search classes implemented in this software
%
% Prints the class tree under headword. Each row starts with a [doc] link, which opens
% the reference page of the class (GUILDA.doc("class", name)), whether the class is
% abstract, and its model key (the Constant property `key`; blank for a class without
% a key, such as PowerNetwork or an abstract class). The returned table lists the
% descendants of the classes in output with their keys; GUILDA.keymap is built from it.
%
% <@Examples>
% ```matlab
% GUILDA.dictionary("Component")                          % class tree under Component
% tab = GUILDA.dictionary("Component", "disp", false);    % No, filename, superclass, Key
% tab(tab.Key ~= "", ["filename","Key"])                  % classes that have a key
% ```
%
% See also GUILDA.keymap, GUILDA.doc
    arguments (Input)
        headword   (1,1) string {mustBeMember(headword,  ["PowerSystemModel","PowerNetwork","Branch","Component","Controller","LocalController","GlobalController","auxiliary"])} = "PowerSystemModel"  % Root class of the displayed class tree.
        opt.disp   (1,1) logical = true  % Print the class tree to the Command Window.
        opt.output (1,:) string {mustBeMember(opt.output,["PowerSystemModel","PowerNetwork","Branch","Component","Controller","LocalController","GlobalController","auxiliary"])} = headword  % Root classes whose descendants are returned.
    end
    arguments (Output)
        tab_out  % Table of descendant classes (No, filename, superclass, Key; Key is "" for a class without a model key); a cell of tables when several outputs are requested.
    end

    char_class = char(headword);

    filename      = "handle";
    superclass    = "";
    Key           = "";
    class_list    = make_classlist(table(filename,superclass,Key),cell(0), opt.disp);

    if opt.disp
        % width of the Key column: the longest key in the displayed tree
        sv_tree = string(char_class);
        sv_new  = sv_tree;
        while ~isempty(sv_new)
            sv_new  = class_list.filename(ismember(class_list.superclass, sv_new));
            sv_tree = [sv_tree; sv_new]; %#ok<AGROW>
        end
        n_key = max(strlength(["Key"; class_list.Key(ismember(class_list.filename, sv_tree))]));
        bar = "================================================================";
        disp(' ')
        disp("Search for '" + char_class + "' class")
        disp(bar)
        disp("  Link   Type        " + pad("Key", n_key) + "  class tree")
        disp(bar)
        print_row(char_class, class_key(headword), n_key);
        fprintf('%s\n', char_class)
        print_tree(class_list,string(char_class),'',n_key);
        disp(bar)
    end

    n_out   = numel(opt.output);
    tab_out = cell(n_out,1);
    for i = 1:n_out
        l_flag      = true;
        sv_parent   = opt.output(i);
        tab_outi    = class_list([],:);   % keeps the filename/superclass/Key columns when nothing is found
        while l_flag
            l_flag = false;
            lv_child = ismember(class_list.superclass,sv_parent);
            if any(lv_child)
                l_flag = true;
                tab_add    = class_list(lv_child,:);
                [~,iv_add] = sort(tab_add.superclass);
                tab_outi   = [tab_outi; tab_add(iv_add,:)]; %#ok
                class_list = class_list(~lv_child,:);
                sv_parent  = tab_add.filename;
            end
        end
        No = (1:size(tab_outi,1))';
        tab_out{i} = [table(No), tab_outi];
    end
    if n_out==1
        tab_out = tab_out{1};
    end
end

function data = make_classlist(data, cell_dirlist, l_disp)

    % Old load classes kept for reference only (same names as the current ones)
    if isequal(cell_dirlist, {'_GUILDAobject','+component','+load','history'})
        return
    end

    list = dir(fullfile( GUILDA.pwd, cell_dirlist{:} ));
    for idx = 1:numel(list)
        char_name = list(idx).name;


        %　隠しファイルの場合：スキップ
        if char_name(1) == '.'
            continue
        end
        

        % 保管用の archive フォルダ：スキップ (旧ファイルは現行クラスと同名のことがある)
        if  list(idx).isdir && strcmp(char_name, 'archive')
            continue
        end

        % 検証・教科書のフォルダ：スキップ (ルートの _GUILDAverification、_GUILDAtextbook)
        if  list(idx).isdir && ismember(char_name, {'_GUILDAverification', '_GUILDAtextbook'})
            continue
        end

        % ディレクトリの場合：フォルダ内を探索
        if  list(idx).isdir
            data = make_classlist( data, [cell_dirlist, {char_name}], l_disp);
            continue
        end
        

        [~, char_filename, char_exp] = fileparts(char_name);
        filename = string(char_filename);
        
        % .mファイル以外の場合：スキップ
        if ~strcmp(char_exp,'.m')
            continue
        end


        % ファイル名から呼び出し名に変換
        for i = numel(cell_dirlist):-1:1
            if cell_dirlist{i}(1)=='+'
                filename = cell_dirlist{i}(2:end)+"."+filename;
            end
        end

        % 既に検出されているクラスの場合：スキップ  (普通は起きえないが同一名のクラスを定義している場合を考慮)
        if any( data.filename == filename )
            if l_disp
                disp("A class with the same name was detected :"+filename)
            end
            continue
        end

        
        try
            superclass_list = superclasses(filename);
        catch ME
            show_msg("warning", "GUILDA:dictionary:ClassNotLoaded", filename, ME.message);
            superclass_list = {};
        end

        if numel(superclass_list)>0
            superclass = string(superclass_list{1});
            Key        = class_key(filename);
            data = [data; table(filename,superclass,Key)]; %#ok
        end
    
    end
end

function print_tree(data,superclass,char_preword,n_key)
    idx_list = find(data.superclass == superclass);
    for idx = idx_list.'
        
        char_filename = char( data{idx,'filename'} );
        print_row(char_filename, data.Key(idx), n_key);

        filelink = ['<a href="matlab:open(''',char_filename,''');">',char_filename,'</a>\n'];
        if idx == idx_list(end)
            fprintf([char_preword,'  ┗━━ ',filelink])
            print_tree(data,string(char_filename),[char_preword,'    '],n_key);
        else
            fprintf([char_preword,'  ┣━━ ',filelink])
            print_tree(data,string(char_filename),[char_preword,'  ┃ '],n_key);
        end
    end
end


function print_row(char_filename, s_key, n_key)
    % Start a row of the tree: the [doc] link, Abstract/Concrete and the model key
    char_filename_for_cmd = strrep(char_filename, '''', '''''');
    fprintf('  <a href="matlab:GUILDA.doc(''class'', ''%s'')">[doc]</a>  ', char_filename_for_cmd)
    c = meta.class.fromName(char_filename);
    if ~isempty(c) && c.Abstract
        fprintf("-:Abstract  ")
    else
        fprintf("o:Concrete  ")
    end
    fprintf("%s  ", pad(string(s_key), n_key))
end
