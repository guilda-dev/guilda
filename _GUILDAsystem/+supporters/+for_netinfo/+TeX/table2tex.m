function out = table2tex(data,Row)
    if nargin<2
        Row = [];
    end
    if numel(data)==0
        out = ['No Data',newline];
    else
        % tableデータに関数パラメータを取得
            nc = size(data,1);
            nv = size(data,2);
        
        % タブスペースのchar配列を定義
        tab  = '    ';
        tab2 = '        ';

        TextCell = cell(3+nc,1+2*nv);

        TextCell(  1:3,         1) = {[tab2,'&']}; 
        TextCell(4:end,         1) = tools.arrayfun(@(i)[Row,num2str(i),'&'],1:nc);
        TextCell(    2, 2:2:end-1) = tools.cellfun(@(r) ['\textbf{',repstr(r,1),'}'], data.Properties.VariableNames);
        TextCell(    :, 3:2:end-2) = {' & '};
        TextCell(1:end,       end) = {['\\',newline]};
        TextCell{    3,       end} =  ['\\',newline,tab2,'\hline',newline];

        for i = 1:nc
        for j = 1:nv
            TextCell{3+i,2*j} = repstr(revise(data{i,j}));
        end
        end

        Content = reshape(TextCell',1,[]);
    
        out = [...
            ... % --header--
            '\footnotesize',newline,...
            '\begin{center}',newline,...
            tab,'\begin{longtable}[H]{|c||',repmat('l|',[1,1+nv]),'}',newline,...
            ... % ----------
            ...
                    ... % --Data--
                    tab2,'\hline',newline,...
                    horzcat(Content{:}),...
                    tab2,'\hline',newline,...
                    ... % --------
            ...
            ... % --footer--
            tab,'\end{longtable}',newline,...
            '\end{center}\leavevmode',newline,...
            '\normalsize' ...
            ... % ----------
            ];
    end
    
end

function Out = revise(In)
    if isempty(In)
        Out = '';
        return
    end

    switch class(In)
        case 'char'
            Out = In;
        case {'string','datetime','function_handle'}
            Out = char(In);
        case {'table','timetable','struct'}
            Out = MatStr(In,class(In));
        case 'cell'
            if size(In,1)==1
                Out = tools.hcellfun(@(c)[revise(c),', '],In);
                Out = Out(1:end-2);
            else
                Out = MatStr(In,'table');
            end
        otherwise
            if isnumeric(In)
                if numel(In)==1 && isnan(In)
                    Out = '';
                else
                    In(abs(In) < 1e-12) = 0;
                    Out = num2str(In);
                    
                    if (isreal(In) && numel(Out) > 7) || (~isreal(In) && numel(Out) > 14)
                        Out = num2str(In,'%.3f');
                    end
                end
            else
                Out = class(In);
            end
    end
    
    function Out = MatStr(In,cls)
        sz = size(In);
        Out = [num2str(sz(1)),'x',num2str(sz(2)),' ',cls];
    end
end

function Out = repstr(In,transOpt)
    
    % option
    if nargin>1 && transOpt
        In = replace( In, {'Vabs','Iabs'},{'|V|','|I|'});
        In = replace( In, {'Varg','Iarg'},    {'\angle V','\angle I'});
        In = replace( In, {'Vangle','Iangle'},{'\angle V','\angle I'});
        In = replace( In, {'RealPower','ActivePower','ReactivePower'},{'P','P','Q'});
        In = replace( In, {'ApparentPower','PowerFactor'},{'|P+jQ|','\angle P+jQ'});
    end
        

    old = { '_', '#', '&', '{', '}',       '^',       '~',       '<',       '>',        '|'};
    new = {'\_','\#','\&','\{','\}','\verb|^|','\verb|~|','\verb|<|','\verb|>|','\textbar '};
    Out = replace(In,old,new);

end


   

% function str = val2str(value)
% 
%     try
%         if isnan(value)
%             str = ' ';
%         else
%             if isa(value,'double') && (value~=floor(value))
%                 if numel(num2str(value)) ~= 1
%                     nword = numel(num2str(value));
%                     value = vpa(value,min([nword,3]));
%                 end
%             end
%             str = string(value);
%         end
%     catch
%         switch class(value)
%             case 'cell'
%                 if numel(value)==1
%                     str = val2str(value{1});
%                     str = cut(str);
%                 else
%                     str = 'cell data';
%                 end
%             case 'sym'
%                 str = ['$',latex(value),'$'];
%             otherwise
%                 str = cut(class(value));
%         end
%     end
%     str = char(str);
% end

