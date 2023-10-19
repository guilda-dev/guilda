classdef parallel < supporters.for_simulate.options.Abstract

    methods
        function obj = parallel(p,t,option)
            obj.parent = p;
            obj.tlim = t;
            data = option.parallel_component;
            if ~isempty(data)
                switch class(data)
                    case 'cell'
                    cellfun(@(d) obj.add(d), data);
                    case 'struct'
                    arrayfun(@(i) obj.add(data(i)), (1:numel(data))');
                end
            end
        end

        function add(obj,data)
            n = 1+numel(obj.data);
            if nargin == 1
                id = input('     Bus index : ');
                 t ma= input('          Time : ');
                onoff = input(' "on" or "off" : ' ,'s');
                obj.data(n) = struct(...
                            'time', t,...
                            'index', id ,...
                            'onoff'  , onoff);
            else
                switch class(data)
                    case 'cell'
                        if islogical(data{3})
                            onoff = ["off","on"];
                            data{3} = onoff(data{3}+1);
                        end
                        obj.data(n).time = data{1};
                        obj.data(n).index = data{2};
                        obj.data(n).onoff = data{3};
                    case 'struct'
                        obj.data(n).time = data.time;
                        obj.data(n).index = data.index;
                        obj.data(n).index = data.onoff;
                    otherwise
                        if isempty(data)
                            return
                        else
                            error('')
                        end
                end

                if islogical(obj.data(n).onoff) || isnumeric(obj.data(n).onoff)
                    onoff = ["off","on"];
                    temp = obj.data(n).onoff ~= 0;
                    obj.data(n).onoff = onoff(temp+1);
                end
            end
        end


        % simulation中に使用するメソッド
            function idx = get_bus_list(obj)
                idx = tools.hcellfun(@(b) strcmp(b.component.parallel,'off'),obj.network.a_bus);
                idx = find(idx);
            end
    
            function tend = get_next_tend(obj,t)
                tlist = tools.harrayfun(@(d) d.time(:)', 1:numel(obj.data));
                tlist = unique(tlist,"sorted");
                tend  = tlist(find(tlist>t,1,"first"));
            end
            
            function set_time(obj,t)
                for i = 1:numel(obj.data)
                    if ismember(t, obj.data(i).time)
                        idx = obj.data(i).index;
                        if strcmp(obj.data(i).onoff,"on")
                            arrayfun(@(i) obj.network.a_bus{i}.component.connect,idx)
                        elseif strcmp(obj.data(i).onoff,"off")
                            arrayfun(@(i) obj.network.a_bus{i}.component.disconnect,idx)
                        end
                    end
                end
            end
    
            function op = export_option(obj)
                op = obj.data;
            end

        
        % データ閲覧用のメソッド
    
            function out = timetable(obj)
                blist = obj.get_all_bus;
                tlist = [tools.harrayfun(@(i) obj.data(i).time(:)',1:numel(obj.data)),obj.tlim(:)'];
                [~,prior] = sort(tlist);
                ilist = [tools.harrayfun(@(i) i*ones(1,numel(obj.data(i).time)),1:numel(obj.data)),0,0];
                ilist = ilist(prior);
                tlist = unique(tlist,'sorted');
                
                tab   = true(numel(blist), numel(tlist));
                for i = 1:numel(tlist)
                    if ilist(i) ~= 0
                        id    = obj.data(ilist(i));
                        ibus  = ismember(blist,id.index); 
                        tab(ibus,i:end) = strcmp(id.onoff,'on');
                    end
                end
                row = tools.varrayfun(@(i) string(obj.network.a_bus{i}.component.Tag) + i, blist);
                out = array2table(tab,"RowNames",row,"VariableNames", arrayfun(@(c)string(c),tlist) );
            end
    
            function plot(obj,ax)
                [tlist,tab] = obj.timetable;
    
                if nargin<2
                    figure
                    ax = gca;
                end
                nbus = numel(obj.network.a_bus);
                xlim(ax,[obj.time(1),obj.time(end)])
                ylim(ax,[0,nbus])
                grid(ax,'on')
                hold(ax,'on')
                set( ax,'YTick', 1:nbus,...
                        'XTick', tlist,...
                        'YTickLabel',"bus"+(nbus:-1:1));
                ax.XAxis.FontSize = 8;
                ax.YAxis.FontSize = 8;
                xlabel(ax,'Time(s)');
                line = tools.varrayfun(@(i) { plot( tlist, (nbus+1-i)*ones(size(tlist)),'r-','LineWidth',2)}, 1:nbus);
                for i = 2:numel(tlist)
                    itab = tab{:,i}-tab{:,i-1};
                    ibus = find(itab==1);
                    plot(tlist(i)*ones(size(ibus)),(nbus+1)-ibus,'rx','LineWidth',2)
                    for idx = find(itab==0 & tab{:,i}==1)'
                        line{idx}.YData(i) = nan;
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
                    case {'Japanese','Ja','ja'}
                        ww = {'解列','並列'};
                        w = {@(i) ['機器',num2str(i),'の並列(parallel on)/解列(parallel off) \n'],...
                             @(t) ['　　時間　：',tools.harrayfun( @(i) [num2str(i),' '], t(:)'),'秒 \n'],...
                             @(b) ['　機器番号：',mat2str(b),'\n'], ...
                             @(p) ['　　状態　：',ww{strcmp(p,"on")+1},'\n \n']};
                    otherwise  %'English'
                        w = {@(i) [num2str(i),'-th parallel setting\n'],...
                             @(t) ['     Time : ',tools.harrayfun( @(i) [num2str(i),' '], t(:)'),'(s) \n'],...
                             @(b) ['   number : ',mat2str(b),'\n'], ...
                             @(p) [' parallel : ',char(p),'\n \n']};
                end
    
                word = cell(1,numel(obj.data));
                for i = 1:numel(obj.data)
                    it = obj.data(i).time(:)';
                    ib = obj.data(i).index(:)';
                    ip = obj.data(i).onoff;
                    word{i} = [w{1}(i),w{2}(it),w{3}(ib),w{4}(ip)];
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