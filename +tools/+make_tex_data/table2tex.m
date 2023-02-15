function text_data = table2tex(data)
    if numel(data)==0
        text_data = ['No Data',newline];
    else
        VarName = data.Properties.VariableNames;
    
        text_data = tools.hcellfun(@(name) [cut(name),'& '],VarName,'UniformOutput',false);
        text_data = [text_data(1:end-2),'\\',newline,'\hline\hline',newline];
    
        for i = 1:size(data,1)
            for j = 1:size(data,2)
                text_data = [text_data, val2str(data{i,j}),'& '];
            end
            text_data = [text_data(1:end-2),'\\',newline];
        end
    
        text_data = finishing_touches(text_data,numel(VarName));
    end
    
end

function str = cut(str)
    str(str=='_') = ' ';
end
    
function out = finishing_touches(value_data,n_column)
    head = [...
        '\footnotesize',newline,...
        '\begin{center}',...
        newline,...
        '\begin{longtable}[H]{c',repmat('l',[1,n_column-1]),'}',...
        newline,...
        '\hline',...
        newline];

    foot = [...
        '\hline',...
        newline,...
        '\end{longtable}',...
        newline,...
        '\end{center}\leavevmode',...
        newline,...
        '\normalsize'];

    out = [head,value_data,foot];
end

   

function str = val2str(value)
    
    try
        if isnan(value)
            str = ' ';
        else
            if isa(value,'double') && (value~=floor(value))
                if numel(num2str(value)) ~= 1
                    nword = numel(num2str(value));
                    value = vpa(value,min([nword,3]));
                end
            end
            str = string(value);
        end
    catch
        switch class(value)
            case 'cell'
                if numel(value)==1
                    str = val2str(value{1});
                else
                    str = 'cell data';
                end
            case 'sym'
                str = ['$',latex(value),'$'];
            otherwise
                str = cut(class(value));
        end
    end
    str = char(str);
end

