classdef parallel_package < handle
    properties 
        a_parallel = {};
    end

    methods
        function obj = parallel_package(data,net)
           switch class(data)
                case 'cell'
                    f = tools.arrayfun(@(i) supporters.for_simulate.options.parallel_unit(data{i}), (1:numel(daata))');
                case 'struct'
                    f = tools.arrayfun(@(i) supporters.for_simulate.options.parallel_unit(data(i)), (1:numel(daata))');
               case 'supporters.for_simulate.options.parallel_package'
                    f = data.a_fault;
               case 'supporters.for_simulate.options.parallel_unit'
                    f = {data};
               otherwise
                    f = {};
            end
            obj.a_parallel = f;
            cellfun(@(p) p.register_net(net), obj.a_parallel);
        end

        % simulation中に使用するメソッド
        function set_time(obj,t)
            cellfun(@(p) p.set_time(t), obj.a_parallel);
        end

        
        % データ閲覧用のメソッド
        function idx = get_all_bus(obj)
            idx = tools.hcellfun(@(f) f.index(:)', obj.a_parallel);
            idx = unique(idx,'sorted');
        end

        % function [tlist,out] = timetable(obj)
        %     tlist = tools.hcellfun(@(p) p.time(:)' , obj.a_parallel);
        %     [~,prior] = sort(tlist);
        %     tlist = unique(tlist,'sorted');
        %     blist = tools.hcellfun(@(p) p.index(:)', obj.a_parallel);
        % 
        %     tab = repmat(,)
        %     tab   = true(nbus, numel(tlist));
        %     for idx = 1:numel(tlist)
        %         for i = 1:numel(obj.data)
        %             itime = obj.data(i).time;
        %             ibus  = obj.data(i).index;
        %             ip    = obj.data(i).parallel;
        %             if itime==tlist(idx)
        %                 tab(ibus,idx:end) = strcmp(ip,'on');
        %             end
        %         end
        %     end
        %     out = array2table(tab,"RowNames","bus"+(1:nbus));
        % end
        % 
        % function plot(obj,ax)
        %     [tlist,tab] = obj.timetable;
        % 
        %     if nargin<2
        %         figure
        %         ax = gca;
        %     end
        %     nbus = numel(obj.network.a_bus);
        %     xlim(ax,[obj.time(1),obj.time(end)])
        %     ylim(ax,[0,nbus])
        %     grid(ax,'on')
        %     hold(ax,'on')
        %     set( ax,'YTick', 1:nbus,...
        %             'XTick', tlist,...
        %             'YTickLabel',"bus"+(nbus:-1:1));
        %     ax.XAxis.FontSize = 8;
        %     ax.YAxis.FontSize = 8;
        %     xlabel(ax,'Time(s)');
        %     line = tools.varrayfun(@(i) { plot( tlist, (nbus+1-i)*ones(size(tlist)),'r-','LineWidth',2)}, 1:nbus);
        %     for i = 2:numel(tlist)
        %         itab = tab{:,i}-tab{:,i-1};
        %         ibus = find(itab==1);
        %         plot(tlist(i)*ones(size(ibus)),(nbus+1)-ibus,'rx','LineWidth',2)
        %         for idx = find(itab==0 & tab{:,i}==1)'
        %             line{idx}.YData(i) = nan;
        %         end
        %     end
        %     hold(ax,'off')
        % end

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
                         @(p) ['　並列・解列：',p,'\n \n']};
                otherwise  %'English'
                    w = {@(i) [num2str(i),'-th parallel setting\n'],...
                         @(t) ['  time span      :',num2str(t(1)),'~',num2str(t(2)),'(s) \n'],...
                         @(b) ['  bus number     :',mat2str(b),'\n'], ...
                         @(p) ['  parallel on/off:',p,'\n \n']};
            end

            word = cell(1,numel(obj.a_parallel));
            for i = 1:numel(obj.a_parallel)
                it = obj.a_parallel{i}.time(:)';
                ib = obj.a_parallel{i}.index(:)';
                ip = obj.a_parallel{i}.onoff;
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