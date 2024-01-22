function text = getTeX_eachClass(a_class,TabData,TabParameter,TabXEquilibrium,TabUEquilibrium)

    if isempty(TabData)
        text  = 'No Class';
        return
    end

    [a_name,first_idx,a_idx] = unique(TabData{:,'class'},'stable');
    n_name = numel(a_name);

    text_cell = cell( 6, n_name);

    getText_Tabi = @(tab,idx) supporters.for_netinfo.TeX.table2tex( rmVar(tab(idx,:)),[],find(idx));
    for i = 1:n_name
        % 1. クラス名のサブセクション定義
        text_cell{1,i} = [newline,...
                         '\Large',newline,...
                         '\underline{\textbf{',TeXstr(char(a_name(i))),'}}',newline,...
                         '\normalsize\\ \\',newline];
        % 2. help
        str = help(a_class{first_idx(i)});
        idx1 = find(str==newline,2,"first");
        idx2 = find(str==newline,5,"last");
        str = TeXstr(str(idx1(2)+1:idx2(1)));
        text = replace(str,{' ','　',newline},{'\ ','\ \ \ ',['\\',newline]});
        text_cell{2,i} = ['\begin{itembox}[l]{help}',newline,text,newline,'\end{itembox}',newline,newline];   
        % 3. ダイナミクスの出力
        doc = a_class{first_idx(i)}.get_TeXdoc;
        text_cell{3,i} = ['$\cdot$\textbf{Discription : }',newline,doc,newline,newline];
        % 4. パラメータ
        para = getText_Tabi(TabParameter, a_idx==i );
        text_cell{4,i} = ['$\cdot$\textbf{Parameter : }',newline,para,newline,newline];
        % 5. xの平衡点
        eq = getText_Tabi(TabXEquilibrium, a_idx==i );
        if strcmp(eq,['No Data',newline])
            text_cell{5,i} = ['$\cdot$\textbf{Equilibrium of state : }State variable does not exist.',newline,newline,newline];
        else
            text_cell{5,i} = ['$\cdot$\textbf{Equilibrium of state : }',newline,eq,newline,newline,newline];
        end
        % 6. uの平衡点
        if nargin>4
            eq = getText_Tabi(TabUEquilibrium, a_idx==i );
            if strcmp(eq,['No Data',newline])
                text_cell{6,i} = ['$\cdot$\textbf{Equilibrium of input : }Port variable does not exist.',newline,newline,newline];
            else
                text_cell{6,i} = ['$\cdot$\textbf{Equilibrium of input : }',newline,eq,newline,newline,newline];
            end
            
        end
    end

    list = [supporters.for_netinfo.TeX.table2tex(TabData),newline];
    text = [list, horzcat(text_cell{:})];

end

function out = rmVar(data)
    rmidx = tools.harrayfun(@(i) all(isnan(data{:,i})), 1:size(data,2));
    out   = data(:,~rmidx);
end


function Out = TeXstr(In)
    old = { '_', '#', '&', '{', '}',       '^',       '~',       '<',       '>',        '|'};
    new = {'\_','\#','\&','\{','\}','\verb|^|','\verb|~|','\verb|<|','\verb|>|','\textbar '};
    Out = replace(In,old,new);
end