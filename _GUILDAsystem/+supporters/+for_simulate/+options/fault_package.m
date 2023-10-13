classdef fault_package < handle
    properties 
        a_fault
    end

    methods
        function obj = fault_package(data)
           switch class(data)
                case 'cell'
                    f = tools.arrayfun(@(i) supporters.for_simulate.options.fault_unit(data{i}), (1:numel(daata))');
                case 'struct'
                    f = tools.arrayfun(@(i) supporters.for_simulate.options.fault_unit(data(i)), (1:numel(daata))');
                case 'supporters.for_simulate.options.fault_package'
                    f = data.a_fault;
                case 'supporters.for_simulate.options.fault_unit'
                    f = {data};
                otherwise
                    error('')
            end
            obj.a_fault = f; 
        end

        % simulation中に使用するメソッド
        function idx = get_bus_list(obj,t)
            idx = tools.hcellfun(@(f) f.get_bus_idx(t), obj.a_fault);
            idx = unique(idx,"sorted");
        end

        function tlist = get_time_list(obj)
            tlist = tools.hcellfun(@(f) f.time(:)', obj.a_fault);
            tlist = unique(tlist,"sorted");
        end

        
        % データ閲覧用のメソッド
        function idx = get_all_bus(obj)
            idx = tools.hcellfun(@(f) f.bus_idx(:)', obj.a_fault);
            idx = unique(idx,'sorted');
        end

        function [tlist,out] = timetable(obj)
            tlist = obj.get_time_list;
            blist = obj.get_all_bus;
            tab   = false(numel(blist), numel(tlist));
            for i = 1:numel(obj.a_fault)
                itime = obj.a_fault{i}.time;
                ibus  = blist == obj.a_fault{i}.bus_idx;
                idx   = tlist>=itime(1) & tlist< itime(2);
                tab(ibus,idx) = true;
            end
            out = array2table(tab,"RowNames","bus"+blist(:));
        end

        function plot(obj,ax)
            tlist = obj.get_time_list;
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
            set( ax,'YTick', nb:-1:1, 'XTick', tlist, 'YTickLabel',"bus"+blist(:));
            ax.XAxis.FontSize = 8;
            ax.YAxis.FontSize = 8;
            xlabel(ax,'Time(s)');
            for i = 1:numel(obj.a_fault)
                itime = obj.a_fault{i}.time;
                ibus  = obj.a_fault{i}.bus_idx;
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
                case 'Japanese'
                    w = {@(i) [num2str(i),'つ目の地絡 \n'],...
                         @(t) ['　　　時間　：',num2str(t(1)),'~',num2str(t(2)),'秒 \n'],...
                         @(b) ['　　母線番号：',mat2str(b),'\n \n']};
                otherwise  %'English'
                    w = {@(i) [num2str(i),'-th fault\n'],...
                         @(t) ['  time span  :',num2str(t(1)),'~',num2str(t(2)),'(s) \n'],...
                         @(b) ['  bus number :',mat2str(b),'\n \n']};
            end

            word = cell(1,numel(obj.a_fault));
            for i = 1:numel(obj.a_fault)
                it = obj.a_fault{i}.time(:)';
                ib = obj.a_fault{i}.bus_idx(:)';
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