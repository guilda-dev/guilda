classdef fault < supporters.for_simulate.option.base

    methods
        function obj = fault(net,t,data)
            obj@supporters.for_simulate.option.base(net,t,data);
        end
            
        function [tlist,out] = timetable(obj)
            tlist = obj.timelist;
            nbus  = numel(obj.network.a_bus);
            tab   = false(nbus, numel(tlist));
            for i = 1:numel(obj.data)
                itime = obj.data(i).time;
                ibus  = obj.data(i).index;
                idx   = tlist>=itime(1) & tlist< itime(2);
                tab(ibus,idx) = true;
            end
            out = array2table(tab,"RowNames","bus"+(1:nbus));
        end

        function plot(obj,ax)
            tlist = obj.timelist;

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
            for i = 1:numel(obj.data)
                itime = obj.data(i).time;
                ibus  = obj.data(i).index;
                for j = ibus(:)'
                    plot(itime,(nbus+1-j)*ones(size(itime)),'rx-','LineWidth',2)
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
                         @(b) ['　　母線番号：',mat2str(b),'\n']};
                otherwise  %'English'
                    w = {@(i) [num2str(i),'-th fault\n'],...
                         @(t) ['  time span  :',num2str(t(1)),'~',num2str(t(2)),'(s) \n'],...
                         @(b) ['  bus number :',mat2str(b),'\n']};
            end

            word = cell(1,numel(obj.data));
            for i = 1:numel(obj.data)
                it = obj.data(i).time;
                ib = obj.data(i).index;
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

    methods(Access=protected)
        function organize(obj)
            fault = obj.data;
            switch class(fault)
                case 'cell'
                    out = struct('time',[],'index',[]);
                    for i = 1:numel(fault)
                        out(i).time  = fault{i}{1}(:).';
                        out(i).index = fault{i}{2}(:).';
                    end
                case 'struct'
                    out = fault;
                case 'table'
                    out = table2struct(fault);
                otherwise
                    out = struct('time',[],'index',[]);
            end
            if ~all(ismember({'time','index'},fieldnames(out)))
                error("The 'time','index' field must be set for the condition on the fault")
            end

            obj.data = out;
        end
    end
end