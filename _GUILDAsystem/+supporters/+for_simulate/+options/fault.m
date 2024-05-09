classdef fault < supporters.for_simulate.options.Abstract

    methods
        function obj = fault(p,data)
            obj.parent = p;
            if ~isempty(data)
               switch class(data)
                    case 'cell'
                        cellfun(@(d) obj.add(d), data);
                    case 'struct'
                        arrayfun(@(i) obj.add(data(i)), (1:numel(data))');
                    otherwise
                        error('')
               end
            end
        end

        function add(obj,data)
            n = 1+numel(obj.data);
            if nargin == 1
                id = input(' Bus index : ');
                ts = input('Start Time : ');
                te = input('  End Time : ');
                obj.data = [obj.data;         ...
                            struct(           ...
                            'time',[ts,te]   ,...
                            'index', id      ,...
                            'is_now' , false) ...
                           ];
            else
                switch class(data)
                    case 'cell'
                        obj.data(n).time = data{1};
                        obj.data(n).index = data{2};
                    case 'struct'
                        obj.data(n).time = data.time;
                        obj.data(n).index = data.index;
                    otherwise
                        if isempty(data)
                            return
                        else
                            error('')
                        end
                end
                obj.data(n).is_now = false;
            end
        end
        
        %% simulation中に使用するメソッド
            function idx = get_bus_list(obj)
                idx = tools.harrayfun(@(i) func(obj.data(i)), 1:numel(obj.data));
                idx = unique(idx,"sorted");

                function out = func(d)
                    if d.is_now
                        out = d.index(:)';
                    else
                        out = [];
                    end
                end
            end
    
            function tend = get_next_tend(obj,t)
                tlist = tools.harrayfun(@(i) obj.data(i).time(:)', 1:numel(obj.data));
                tlist = unique(tlist,"sorted");
                tend  = tlist(find(tlist>t,1,"first"));
            end
            
            function set_time(obj,t)
                for i = 1:numel(obj.data)
                    if t == obj.data(i).time(1)
                        obj.data(i).is_now = true;
                    elseif t == obj.data(i).time(2)
                        obj.data(i).is_now = false;
                    end
                end
            end
    
            function op = export_option(obj)
                if isempty(obj.data)
                    op = [];
                else
                    op = rmfield(obj.data,'is_now');
                end
            end


        
        %% データ閲覧用のメソッド
    
            function out = timetable(obj)
                tlist = obj.get_all_time;
                blist = obj.get_all_bus;
                tab   = false(numel(blist), numel(tlist));
                for i = 1:numel(obj.data)
                    itime = obj.data(i).time;
                    ibus  = ismember(blist,obj.data(i).index);
                    idx   = tlist>=itime(1) & tlist<= itime(2);
                    tab(ibus,idx) = true;
                end
                out = array2table(tab,"RowNames","bus"+blist(:),"VariableNames", arrayfun(@(c)string(c),tlist) );
            end
    
            function plot(obj,ax)
                tlist = obj.get_all_time;
                blist = obj.get_all_bus;
                nb = numel(blist);
                
                if nargin<2
                    figure
                    ax = gca;
                end
                xlim(ax,[tlist(1),tlist(end)])
                ylim(ax,[0,1+nb])
                grid(ax,'on')
                hold(ax,'on')
                set( ax,'YTick', 1:nb, 'XTick', tlist, 'YTickLabel',"bus"+blist(:));
                ax.XAxis.FontSize = 8;
                ax.YAxis.FontSize = 8;
                xlabel(ax,'Time(s)');
                for i = 1:numel(obj.data)
                    itime = obj.data(i).time;
                    ibus  = obj.data(i).index;
                    for j = ibus(:)'
                        idx = find(blist==j);
                        plot(itime,(nb+1-idx)*ones(size(itime)),'rx-','LineWidth',2)
                    end
                end
                hold(ax,'off')
            end
    
            function [varargout] = sentence(obj,language)
                if nargin<2
                    if contains( get(0,'lang'), 'ja')
                        language = 'Japanese';
                    else
                        language = 'English';
                    end
                end
                switch language
                    case {'Japanese','ja'}
                        w = {@(i) [num2str(i),'つ目の地絡 \n'],...
                             @(t) ['　　　時間　：',num2str(t(1)),'~',num2str(t(end)),'秒 \n'],...
                             @(b) ['　　母線番号：',mat2str(b),'\n \n']};
                    otherwise  %'English'
                        w = {@(i) [num2str(i),'-th fault\n'],...
                             @(t) ['  time span  :',num2str(t(1)),'~',num2str(t(end)),'(s) \n'],...
                             @(b) ['  bus number :',mat2str(b),'\n \n']};
                end
    
                word = cell(1,numel(obj.data));
                for i = 1:numel(obj.data)
                    it = obj.data(i).time(:)';
                    ib = obj.data(i).index(:)';
                    word{i} = [w{1}(i),w{2}(it),w{3}(ib)];
                end
                word = horzcat(word{:});
                if nargout<1
                    if ~isempty(word)
                        fprintf(word);
                    end
                else
                    varargout{1} = word;
                end
            end

    end
end