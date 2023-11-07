classdef input < supporters.for_simulate.options.Abstract

    properties(Access=private)
        method
    end

    methods
        function obj = input(p,t,uidx,u,option)
            obj.parent = p;
            obj.method = option.method;
            obj.tlim = t;
            
            if ~isempty(data)
               switch class(data)
                    case 'cell'
                        cellfun(@(d) obj.add(d), option.u);
                    case 'struct'
                        arrayfun(@(i) abj.add(option.u(i)), (1:numel(option.u))');
                    otherwise
                        error('')
               end
            end
            obj.add('index',uidx,'u',u);
        end

        function add(obj,varargin)
            if nargin == 1
                id = input(' Bus index : ');
                t  = input('Time Table : ');
                u  = input('Input Data : ');
                m  = input('    Method : ','s');
                newdata = struct('time',t,'index',id,'u',u,'method',m,'function',[]);
            else
                p = inputParser;
                p.CaseSensitive = false;
                addParameter(p, 'time'    , obj.tlim);
                addParameter(p, 'index'   , []);
                addParameter(p, 'u'       , []);
                addParameter(p, 'method'  , obj.method);
                addParameter(p, 'function', []);
                parse(p, varargin{:});
                newdata = p.Results;
            end

            if isa(newdata.function,'function_handle')
                newdata.u = [];
                newdata.method = [];
                if isempty(newdata.index)
                    disp(newdata)
                    error('indexが指定されていません')
                end
                u = f(newdata.time(1));
                nu = numel(u);
            else
                if size(newdata.u,2)~=numel(newdata.time)
                    if size(newdata.u,1)==numel(newdata.time)
                        newdata.u = newdata.u.';
                    else
                        disp(newdata)
                        error('配列サイズが時間ステップと一致しません')
                    end
                end
                nu = size(newdata.u,1);
            end
            idx = newdata.index;
            a_nu = tools.vcellfun(@(b) b.component.get_nu, obj.network.a_bus(idx));
            if sum(a_nu)==nu
                cell_nu = tools.arrayfun(@(n) true(n,1), a_nu);
                l = blkdiag(cell_nu{:});
            elseif all((a_nu-a_nu(1))==0) && a_nu(1)==nu
                l = true(nu,numel(idx));
            else
                error('入力の配列数が指定されたインデックスの機器の入力ポート数と一致しません')
            end
            newdata.logimat = l;
            n = 1+numel(obj.data);
            obj.data(n) = newdata;
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
                tlist = tools.harrayfun(@(d) d.time(:)', 1:numel(obj.data));
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
                op = rmfield(obj.data,'logimat');
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