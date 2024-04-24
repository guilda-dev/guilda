classdef response < handle

    properties
        state_line
        state_list
        OutputFcn
        % OutputFcnの入力値を補正したものを入れる
        stockFcn = [];

        time_interval = 0.1;
        colororder = [colororder;...
                    [ 51,  34, 136;...
                     136, 204, 238;...
                      68, 170, 153;...
                      17, 119,  51;...
                     153, 153,  51;...
                     221, 204, 119;...
                     204, 102, 119;...
                     136,  34,  58;...
                     170,  68, 153;...
                     221, 221, 221]./256 ...
                     ];

        linestyle = ["-", "--", ":", "-."];

        odefactory

        last_time = 0;
        stash = struct('time',[],'data',{[]})
        network
        ax
        tlim
        fig_all
        fig_unique
    end

    methods
        function obj = response(parent,tlim, outputfcn)
            obj.odefactory = parent;
            net = parent.network;
            obj.network = net;
            obj.tlim = tlim;
            
            stockFcn = struct;
            n = numel(outputfcn);
            state_list = unique(tools.hcellfun(@(b) b.component.get_state_name, net.a_bus));
            obj.state_list = state_list;

            %OutputFcnの入力補正(入力値:Fig, para, busidx)
            if ~isempty(outputfcn)
                for k = 1:n

                    % paraをstockFcnの構造体に入力
                    para_i = outputfcn(k).para;
                    stockFcn(k).para = para_i;
                    bus_idx = [];

                    % para_iの値に合わせてbus_idxの指定
                    if isfield(outputfcn(k),'bus_idx')
                        if ~isempty(outputfcn(k).bus_idx)
                            bus_idx = outputfcn(k).bus_idx;
                        else
                            switch para_i
                            case state_list
                                bus_idx = find(arrayfun(@(i) strcmp(net.a_bus{i}.component.Tag, 'Gen'), 1:numel(net.a_bus)));
                                
                            case {'Vreal','Vimag','Vabs','Vangle',...
                                  'Ireal','Iimag','Iabs','Iangle',...
                                  'P','Q','S'}
                                bus_idx = 1:numel(net.a_bus);

                            case {'Pmech', 'Vfield'}
                                % ひとまず全てのGenを出力対象とした
                                bus_idx = find(arrayfun(@(i) strcmp(net.a_bus{i}.component.Tag, 'Gen'), 1:numel(net.a_bus)));
                            end
                        end
                        
                    else
                        switch para_i
                            case state_list
                                bus_idx = find(arrayfun(@(i) strcmp(net.a_bus{i}.component.Tag, 'Gen'), 1:numel(net.a_bus)));

                            case {'Vreal','Vimag','Vabs','Vangle',...
                                  'Ireal','Iimag','Iabs','Iangle',...
                                  'P','Q','S'}
                                bus_idx = 1:numel(net.a_bus);

                            case {'Pmech', 'Vfield'}
                                % ひとまず全てのGenを出力対象とした
                                bus_idx = find(arrayfun(@(i) strcmp(net.a_bus{i}.component.Tag, 'Gen'), 1:numel(net.a_bus)));
                        end
                    end

                    stockFcn(k).bus_idx = bus_idx;

                    % Figの指定
                    if isfield(outputfcn(k),'Fig')
                        stockFcn(k).Fig = outputfcn(k).Fig;
                    else
                        stockFcn(k).Fig = k;
                    end
                end

                % Figの中でフィールドにはあるが抜けている情報の補間
                idx_Fig_none = find(arrayfun(@(i) isempty(stockFcn(i).Fig), 1:n), 1);
                if ~isempty(idx_Fig_none)
                    idx_Fig = setdiff(1:n,idx_Fig_none);
                    max_Fig = max(arrayfun(@(i)stockFcn(i).Fig, idx_Fig));
                    for l = 1:numel(idx_Fig_none)
                        idx_Fig_none_ = idx_Fig_none(l);
                        stockFcn(idx_Fig_none_).Fig = max_Fig + l;
                    end
                end

                obj.stockFcn = stockFcn;
            end

            if isempty(obj.stockFcn)
                obj.OutputFcn = @(t,x,flag) [];
            else
                obj.init_plot;
                obj.stash.time = [];
                obj.stash.data = cell(n,1);
                obj.time_interval = (tlim(end)-tlim(1))/100;
                obj.OutputFcn = @(t,x,flag) obj.plotFcn(t,x,flag);
            end
        end

        function init_plot(obj)
            % Figの数を抽出
            obj.fig_all = tools.harrayfun(@(i) obj.stockFcn(i).Fig, 1:numel(obj.stockFcn));
            obj.fig_unique = unique(obj.fig_all);

            for i = 1:numel(obj.fig_unique)
                fig_uni = obj.fig_unique(i);
                fig_idx = find(ismember(obj.fig_all,fig_uni));
                f = figure(fig_uni);
                obj.ax = tiledlayout(f,'flow','TileSpacing','compact');

                % ylabelの作成
                y_label = obj.stockFcn(fig_idx(1)).para;
                if numel(fig_idx) >1
                    for j = 1:(numel(fig_idx) - 1)
                        y_label_ = [y_label,', ', obj.stockFcn(fig_idx(j+1)).para];
                        y_label = y_label_;
                    end
                end
                nexttile
                hold on
                grid on
                xlim(obj.tlim([1,end]))
                xlabel('Time(s)',    'FontSize', 15, 'FontWeight', 'bold')
                ylabel(y_label,'FontSize', 15, 'FontWeight', 'bold')
                
                % busidxの設定
                busidx = tools.harrayfun(@(i) obj.stockFcn(fig_idx(i)).bus_idx, 1:numel(fig_idx));

                nbus = numel(busidx);

                obj.state_line{i} = cell(nbus,1);
                b = 0;
                label = [];
                for l = 1:numel(fig_idx)
                    busidx_l = obj.stockFcn(fig_idx(l)).bus_idx;
                    for jj = 1:numel(busidx_l)
                        j = busidx_l(jj);
                        idx_color = 1+ mod( j-1, size(obj.colororder,1) );
                        obj.state_line{i}{b+jj} = animatedline('LineWidth',2,'Color',obj.colororder(idx_color,:), 'LineStyle',obj.linestyle(l));
                    end
                    b = b+numel(busidx_l);
                    label_l = tools.arrayfun(@(i)[obj.stockFcn(fig_idx(l)).para,':bus/mac ',num2str(i)], busidx_l);
                    label = [label,label_l];
                end
            lgd = legend(obj.ax.Children(end).Children(end:-1:1),label);
            lgd.Layout.Tile = 'east';
            lgd.NumColumns = ceil(nbus/30);
            end
        end

        function out = plotFcn(obj,t,x,~)
            if isempty(obj.ax) || ~isgraphics(obj.ax)
                obj.init_plot
            end
            if numel(t) ==1
                % データの保存
                for i = 1:numel(obj.fig_unique)
                    fig_i = obj.fig_unique(i);
                    fig_idx = find(arrayfun(@(j) isequal(obj.stockFcn(j).Fig,fig_i),1:numel(obj.fig_all)));
                    newdata = [];
                    for k = 1:numel(fig_idx)
                        fig_k = fig_idx(k);
                        newdata_k = obj.access(fig_k,x);
                        newdata = [newdata;newdata_k];
                    end
                    obj.stash.data{i} = [obj.stash.data{i}, newdata];
                end
                obj.stash.time = [obj.stash.time, t];

                if ( t - obj.last_time ) > obj.time_interval
                    obj.add_plot
                    obj.last_time = t;
                end
            end
            out = false;
        end

        function add_plot(obj)
            for i  = 1:numel(obj.fig_unique)
                iline = obj.state_line{i};
                [s,~] = size(obj.stash.data{i});
                for ibus = 1:s
                    addpoints(iline{ibus}, obj.stash.time, obj.stash.data{i}(ibus,:) );
                end
                obj.stash.data{i} = [];
            end
            obj.stash.time = [];
            drawnow limitrate
        end

        function out = access(obj,idx,x)
            % 指定されたstockFcn{idx}におけるparaのデータを出力するもの
            para = obj.stockFcn(idx).para;
            busidx = obj.stockFcn(idx).bus_idx;
            nbus = numel(busidx);
            net = obj.network;
            [X,Xcl,Xcg,V,I,~] = obj.odefactory.expand_Xode(x, busidx, 1:numel(net.a_controller_local), 1:numel(net.a_controller_global));
            
            % 最初にparaの種類で出力を分けてみる
            switch para
                case obj.state_list
                    idx_state = arrayfun(@(i) find(strcmp(get_state_name(net.a_bus{i}.component),para)), busidx);
                    out = tools.varrayfun(@(i) X{i}(idx_state(1,i)), 1:nbus);

                case 'Ireal'
                    out = tools.varrayfun(@(i) I{i}(1), busidx);

                case 'Iimag'
                    out = tools.varrayfun(@(i) I{i}(2), busidx);

                case 'Iabs'
                    out = tools.varrayfun(@(i) norm(I{i}), busidx);

                case 'Iangle'
                    out = tools.varrayfun(@(i) angle(I{i}(1)+I{i}(2)*1j), busidx);

                case 'Vreal'
                    out = tools.varrayfun(@(i) V{i}(1), busidx);

                case 'Vimag'
                    out = tools.varrayfun(@(i) V{i}(2), busidx);

                case 'Vabs'
                    out = tools.varrayfun(@(i) norm(V{i}), busidx);

                case 'Vangle'
                    out = tools.varrayfun(@(i) angle(V{i}(1)+V{i}(2)*1j), busidx);

                case 'P'
                    out = tools.varrayfun(@(i) dot(V{i},I{i}), busidx);
                
                case 'Q'
                    out = tools.varrayfun(@(i) det([I{i},V{i}]), busidx);
            end
        end
    end
end