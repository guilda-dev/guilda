classdef switch_cg < supporters.for_simulate.option.base

    methods
        function obj = switch_cg(net,t,data)
            obj@supporters.for_simulate.option.base(net,t,data);
        end
            
        function [tlist,out] = timetable(obj)
            tlist = obj.timelist;
            nbus  = numel(obj.network.a_bus);
            tab   = true(nbus, numel(tlist));
            for idx = 1:numel(tlist)
                for i = 1:numel(obj.data)
                    itime = obj.data(i).time;
                    ibus  = obj.data(i).index;
                    ip    = obj.data(i).parallel;
                    if itime==tlist(idx)
                        tab(ibus,idx:end) = strcmp(ip,'on');
                    end
                end
            end
            out = array2table(tab,"RowNames","bus"+(1:nbus));
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
                case 'Japanese'
                    w = {@(i) ['機器',num2str(i),'の並列(parallel on)/解列(parallel off) \n'],...
                         @(t) ['　　　時間　：',num2str(t(1)),'~',num2str(t(2)),'秒 \n'],...
                         @(b) ['　　母線番号：',mat2str(b),'\n'], ...
                         @(p) ['　並列・解列：',p,'\n']};
                otherwise  %'English'
                    w = {@(i) [num2str(i),'-th parallel setting\n'],...
                         @(t) ['  time span      :',num2str(t(1)),'~',num2str(t(2)),'(s) \n'],...
                         @(b) ['  bus number     :',mat2str(b),'\n'], ...
                         @(p) ['  parallel on/off:',p,'\n']};
            end

            word = cell(1,numel(obj.data));
            for i = 1:numel(obj.data)
                it = obj.data(i).time;
                ib = obj.data(i).index;
                ip = obj.data(i).parallel;
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

    methods(Access=protected)
        function organize(obj)
            indata = obj.data;
            switch class(indata)
                case 'cell'
                    out = struct('time',[],'index',[],'parallel',[]);
                    for i = 1:numel(indata)
                        out(i).time     = indata{i}{1}(:).';
                        out(i).index    = indata{i}{2}(:).';
                        if numel(indata{i})<3
                            out(i).parallel = false;
                        else
                            out(i).parallel = indata{i}{3};
                        end
                    end
                case 'struct'
                    out = indata;
                case 'table'
                    out = table2struct(indata);
                otherwise
                    out = struct('time',[],'index',[],'parallel',[]);
            end
        
            if ~all(ismember({'time','index','parallel'},fieldnames(out)))
                error("The 'time','index','parallel' field must be set for the condition on the parallels")
            end
            
            nanidx = [];
            i = 0;
            while i < numel(out)
                i = i+1;
                % check 'parallel' data
                val = out(i).parallel;
                if isnumeric(val)
                    tf = logical(val);
                elseif islogical(val)
                    tf = val;
                elseif ismember(val,{'on','off'})
                    tf = strcmp(tf,'on');
                else
                    warning(['The ',num2str(i),'-th condition for a parallel is ignored because it is indistinguishable'])
                    nanidx = [nanidx,i];%#ok
                    continue
                end
                if tf
                    out(i).parallel = 'on';
                else
                    out(i).parallel = 'off';
                end

                itime = out(i).time;
                if numel(itime)==2
                    iout = out(i);
                    iout.time = iout.time(2);
                    iout.parallel = strrep('onoff',iout.parallel,[]);
                    out(i).time = out(i).time(1);
                    if i~=numel(out)
                        out = [out(1:i),iout,out(i+1:end)];
                    else
                        out = [out(1:i),iout];
                    end
                    i = i+1;
                elseif numel(itime)>2
                    warning(['The ',num2str(i),'-th condition for a parallel is ignored because it is indistinguishable'])
                    nanidx = [nanidx,i];%#ok
                    continue
                end
            end
            out(nanidx) = [];
            obj.data = out;
        end
    end
end