function data_type = count_line_of_directory(filename)
%引数無しの場合、現在いるディレクトリ内のファイルを探索

fprintf('\n\n')
if nargin<1
    currentFolder = pwd;
    idx_slash = find(currentFolder == '/',1,'last');
    filename = ['../',currentFolder(idx_slash+1:end)];
    fprintf(['File name : ',currentFolder(idx_slash+1:end),'\n'])
else
    fprintf(['File name',filename,'\n'])
end
disp('===================================================')
data_type = struct();
[tl,tf,data_type] = reserch_dir(filename,'  ',data_type);
disp('---------------------------------------------------')
disp(' ')
disp(['total : ',num2str(tf),' files'])
disp(['total : ',num2str(tl),' lines'])
fprintf('\n\n')
disp('each type of file ↓')
disp('---------------------------------------------------')
disp_data_type(data_type)
disp('---------------------------------------------------')
data_type.total.num = tf;
data_type.total.line = tl;
end

function [total_line,total_file,data_type] = reserch_dir(filename,pre_word,data_type)
    total_line = 0;
    total_file = 0;
    data = dir(filename);
    n_file = numel(data);
    for idx = 1:n_file
        if ~(data(idx).name(1) == '.')
            if  ~data(idx).isdir
                line = get_lines([filename,'/',data(idx).name]);
                word_line = num2str(line);
                if numel(word_line)<7
                    word_line = [char(zeros(1,6-numel(word_line))),word_line];
                end
                fprintf([pre_word,word_line,' lines "',data(idx).name,'"\n'])
                if ~isnan(line)
                    total_line = total_line + line;
                end
                total_file = total_file + 1;
                file_type_name = get_ftype(data(idx).name);
                data_type = insert_field(data_type,file_type_name,line);
            else
                fprintf([pre_word,' ┌-directory:',data(idx).name,'\n']);
                pw = ['　　　',pre_word];
                [tl,tf,data_type] = reserch_dir([filename,'/',data(idx).name],pw,data_type);
                total_line = total_line + tl;
                total_file = total_file + tf;
                fprintf([pre_word,' └--→total_line=',num2str(tl),',total_file=',num2str(tf),'\n'])
            end
        end
    end
end

function y = get_lines(filename)
    [~,cmdout] = unix(['wc ',filename]);
    line = '';
    on_off = false;
    getting = true;
    idx = 0;
    while getting
        idx = idx+1;
        if cmdout(idx)~= ' ' && ~on_off
            on_off = true;
        end
        if cmdout(idx)== ' ' && on_off 
            on_off = false;
            getting = false;
        end
        if on_off
            line = [line,cmdout(idx)];
        end
    end
    y = str2double(line);
end

function y = get_ftype(fname)
    y = '';
    while_switch = true;
    idx = 0;
    while while_switch
        word = fname(end-idx);
        if word == '.'
            while_switch = false;
        else
            y = [word,y];
        end
        idx = idx + 1;
        if idx==numel(fname)
            while_switch = false;
            y = 'else';
        end
    end
    y = ['file_',y];
end

function y = insert_field(data,fname,lines)
    if isnan(lines)
        lines = 0;
    end
    if isfield(data,fname)
        x = getfield(data,fname);
        x.num = x.num+1;
        x.line = x.line+lines;
    else
        x.num = 1;
        x.line = lines;
    end
    y = setfield(data,fname,x);
end

function y = disp_data_type(data)
    type_name = fieldnames(data);
    max_n = max(arrayfun(@(b) numel(type_name{b}),(1:numel(type_name))'));
    for idx = 1:numel(type_name)
        tn = type_name{idx};
        n = num2str(getfield(data,tn,'num'));
        l = num2str(getfield(data,tn,'line'));
        tn = tn(6:end);
        if numel(tn)==4
            if all(tn == 'else') 
                tn = [' ',tn];
            else
                tn = ['.',tn];
            end
        else
            tn = ['.',tn];
        end
        tn = [char(zeros(1,max_n-numel(tn))),tn];
        if numel(n)<7
            n = [char(zeros(1,6-numel(n))),n];
        end
        if numel(l)<7
            l = [char(zeros(1,6-numel(l))),l];
        end
        fprintf([tn,' file :',n,' files,',l,' lines\n'])
    end
end


