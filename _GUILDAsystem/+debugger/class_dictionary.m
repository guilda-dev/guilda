function class_list = class_dictionary(class_name)

if nargin == 0
    class_name = 'handle';
end

if strcmp(class_name([end-1,end]),'.m')
    class_name = class_name(1:end-2);
end
fprintf(['Search : "',class_name,'" class．．．\n\n'])

filename = ""; superclass = "";
class_list = search_superclass(table(filename,superclass),cell(0),class_name);
bar = '===================================================';

disp(' ')
disp([class_name,' class：'])
disp(bar)
disp('       Link　　　class tree')
disp(bar)
fprintf_doc_and_help(string(class_name));
space = '     ';
disp([space,class_name])
print_tree(class_list,string(class_name),[space,' ']);
disp(bar)
disp(' ')

end

function data = search_superclass(data,dir_list,class_name)
    list = dir([pwd,horzcat(dir_list{:})]);
    for idx = 1:numel(list)
        %　隠しファイルでない場合
        if ~(list(idx).name(1) == '.')
            % ディレクトリでない場合
            if  ~list(idx).isdir 
                [~,filename,~] = fileparts(list(idx).name);
                if numel(dir_list)~=0
                    for i = numel(dir_list):-1:1
                        if dir_list{i}(2)=='+'
                            filename = [dir_list{i}(3:end),'.',filename]; %#ok
                        end
                    end
                end
                filename = string(filename);
                if ~any(data{:,'filename'}==filename)
                    try
                        superclass_list = superclasses(filename);
                    catch
                        disp("Unable to analyze parent class: "+filename)
                    end
                    if numel(superclass_list)>0 && any(strcmp(superclass_list,class_name))
                        superclass = string(superclass_list{1});
                        table(filename,superclass);
                        data = vertcat(data,table(filename,superclass)); %#ok
                    end
                end
            % ディレクトリの場合
            else
                data = search_superclass(data,[dir_list,{['/',list(idx).name]}],class_name);
            end
        end
    end
end

function print_tree(data,superclass,preword)
    idx_list = find(data{:,'superclass'}==superclass);
    for idx = idx_list'
        filename = data{idx,'filename'};
        fprintf_doc_and_help(filename);
        if idx == idx_list(end)
            disp([preword,' ┗━ ',filename{:}])
        print_tree(data,filename,[preword,'       ']);
        else
            disp([preword,' ┣━ ',filename{:}])
        print_tree(data,filename,[preword,' ┃  ']);
        end
    end
end

function fprintf_doc_and_help(filename)
 fprintf(['<a href="matlab:' ,...
            'disp('' '');',...
            'disp([''help：'',''',filename{:},''']);',...
            'disp(''==================================================='');',...
            'help(''',filename{:},''');',...
            'disp(''==================================================='');',...
            'disp('' '');',...
            '"> [help]</a>'])
        fprintf(',')
        fprintf(['<a href="matlab:' ,...
            'doc(''',filename{:},''');',...
            '"> [doc]</a>'])
end

function fprintf_additional_word(filename)
    switch filename
        case "power_network"
        case "component"
        case "controller"
        case "bus"
        case "branch"
    end
end