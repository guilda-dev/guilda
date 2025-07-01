function class_list = search_GUILDAclass(char_class)
arguments
    char_class (1,:) char = 'handle';
end


if strcmp(char_class([end-1,end]),'.m')
    char_class = char_class(1:end-2);
end

filename      = "handle";
superclass    = "";
class_list    = make_classlist(table(filename,superclass),cell(0));


bar = "=========================================================";
disp(' ')
disp("Search for '" + char_class + "' class")
disp(bar)
disp("     Link   　 class tree ")
disp(bar)
fprintf_doc_and_help(char_class);
disp(char_class)
print_tree(class_list,string(char_class),'  ');
disp(bar)

end

function data = make_classlist(data, cell_dirlist)

    list = dir(fullfile( config.pwd, cell_dirlist{:} ));
    for idx = 1:numel(list)
        char_name = list(idx).name;


        %　隠しファイルの場合：スキップ
        if char_name(1) == '.'
            continue
        end
        

        % ディレクトリの場合：フォルダ内を探索
        if  list(idx).isdir
            data = make_classlist( data, [cell_dirlist, {char_name}]);
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
                filename = cell_dirlist{i}(3:end)+"."+filename;
            end
        end

        % 既に検出されているクラスの場合：スキップ  (普通は起きえないが同一名のクラスを定義している場合を考慮)
        if any( data.filename == filename )
            disp(config.lang("同一名のクラスが検出されました："+filename,"A class with the same name was detected :"+filename))
            continue
        end

        
        try
            superclass_list = superclasses(filename);
        catch
            disp(config.lang("親クラスを解析できません："+filename,"Unable to analyze parent class : "+filename))
            superclass_list = {};
        end

        if numel(superclass_list)>0
            superclass = string(superclass_list{1});
            data = [data; table(filename,superclass)]; %#ok
        end
    
    end
end

function print_tree(data,superclass,char_preword)
    idx_list = find(data.superclass == superclass);
    for idx = idx_list.'
        
        char_filename = char( data{idx,'filename'} );
        fprintf_doc_and_help(char_filename);

    
        filelink = ['<a href="matlab:open(''',char_filename,''');">',char_filename,'</a>\n'];
        if idx == idx_list(end)
            fprintf([char_preword,' ┗━ ',filelink])
            print_tree(data,string(char_filename),[char_preword,'       ']);
        else
            fprintf([char_preword,' ┣━ ',filelink])
            print_tree(data,string(char_filename),[char_preword,' ┃  ']);
        end
    end
end

function fprintf_doc_and_help(char_filename)
    fprintf(' ')
    fprintf(['<a href="matlab:' ,...
             'disp('' '');',...
             'disp('' '');',...
             'disp([''help：'',''',char_filename,''']);',...
             'disp(''==================================================='');',...
             'help(''',char_filename,''');',...
             'disp(''==================================================='');',...
             'disp('' '');',...
             'disp('' '');',...
             '">[help]</a>'])
    fprintf(',')

    if ismethod(char_filename,"doc")
        fprintf(['<a href="matlab:' ,...
                 char_filename,'.doc;',...
                 '">[mlx]</a>  '])
    else
        fprintf(['<a href="matlab:' ,...
                 'doc(''',char_filename,''');',...
                 '">[doc]</a>  '])
    end
end