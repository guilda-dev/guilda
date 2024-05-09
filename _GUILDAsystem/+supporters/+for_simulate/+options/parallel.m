classdef parallel < supporters.for_simulate.options.Abstract

    methods
        function obj = parallel(p,option)
            obj.parent = p;
            f = {   'parallel_sys','parallel_branch','parallel_con_local','parallel_con_global'};
            type = {'component'   ,'branch'         ,'controller_local'  ,'controller_global'  };
            for itype=1:4
                data = option.(f{itype});
                if ~isempty(data)
                    arrayfun(@(i) obj.add(data(i),type{itype}), (1:numel(data))');
                end
            end
        end

        function add(obj,data,type)
            n = 1+numel(obj.data);
            if nargin == 1
                id = input('     Bus index : ');
                 t = input('          Time : ');
                onoff = input(' "on" or "off" : ' ,'s');
                obj.data = [obj.data;
                            struct(        ...
                            'type' , type ,...
                            'time' , t    ,...
                            'index', id   ,...
                            'onoff', onoff)...
                           ];
            else
                if isstruct(data)
                    obj.data(n).type  = type;
                    obj.data(n).time  = data.time;
                    obj.data(n).index = data.index;
                    obj.data(n).onoff = data.onoff;
                elseif isempty(data)
                    return
                else
                    error('')
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
                tlist = tools.harrayfun(@(i) obj.data(i).time(:)', 1:numel(obj.data));
                tlist = unique(tlist,"sorted");
                tend  = tlist(find(tlist>t,1,"first"));
            end
            
            function set_time(obj,t)
                for i = 1:numel(obj.data)
                    if ismember(t, obj.data(i).time)
                        idx   = obj.data(i).index;
                        onoff = obj.data(i).onoff;
                        switch obj.data(i).type
                            case 'component'
                                arrayfun(@(i) connect(obj.network.a_bus{i}.component    , onoff), idx)
                            case 'branch'
                                arrayfun(@(i) connect(obj.network.a_branch{i}           , onoff), idx)
                            case 'controller_local'
                                arrayfun(@(i) connect(obj.network.a_controller_local{i} , onoff), idx)
                            case 'controller_global'
                                arrayfun(@(i) connect(obj.network.a_controller_global{i}, onoff), idx)
                        end
                    end
                end
            end
    
            function op = export_option(obj)
                if isempty(obj.data)
                    op = [];
                else
                    op = obj.data;
                end
            end

        
        % データ閲覧用のメソッド
    
            function [out,tlist] = timetable(obj)
                blist = obj.get_all_bus;
                tlist = [tools.harrayfun(@(i) obj.data(i).time(:)',1:numel(obj.data)),obj.tlim([1,end])];
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
                if isempty(row)
                    out = array2table(tab,"VariableNames", arrayfun(@(c)string(c),tlist) );
                else
                    out = array2table(tab,"RowNames",row,"VariableNames", arrayfun(@(c)string(c),tlist) );
                end
            end
    
            function plot(obj,ax)
                [tab,tlist] = obj.timetable;
    
                if nargin<2
                    figure
                    ax = gca;
                end
                
                t0 = obj.tlim(1);
                te = obj.tlim(end);
                nbus = numel(obj.network.a_bus);
                
                %座標軸の設定
                xlim(ax,[t0,te])
                ylim(ax,[0,nbus])
                grid(ax,'on')
                hold(ax,'on')
                set( ax,'YTick', 1:nbus,...
                        'XTick', tlist,...
                        'YTickLabel',"bus"+(nbus:-1:1));
                ax.XAxis.FontSize = 8;
                ax.YAxis.FontSize = 8;
                xlabel(ax,'Time(s)');

                %ラインを追加
                line = tools.varrayfun(@(i) { plot( [t0,te], (nbus+1-i)*[1,1],'g-','LineWidth',2)}, 1:nbus);

                for i = 1:numel(tlist)
                    if i==1
                        itab = tab{:,i} - true(size(tab,1),1);
                    else
                        itab = tab{:,i} - tab{:,i-1};
                    end

                    for idx = 1:numel(itab)
                        yval = nbus+1-idx;
                        xval = tlist(i);
                        switch itab(idx)
                            case 0
                            case -1 %解列した機器のline
                                plot(xval,yval,'rx','LineWidth',2)
                                line{idx}.XData(2) = xval;
                                line{idx} = plot([xval,te], yval*[1,1], 'r-', 'LineWidth',2);
                            case 1 %並列した機器のline
                                plot(xval,yval,'go','LineWidth',2, 'MarkerFaceColor','g')
                                line{idx}.XData(2) = xval;
                                line{idx} = plot([xval,te], yval*[1,1], 'g-', 'LineWidth',2);
                        end
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


function connect(c,onoff)
    switch onoff
        case 'on'
            c.connect
        case 'off'
            c.disconnect
    end
end