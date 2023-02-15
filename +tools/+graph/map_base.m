classdef map_base < handle

    properties

        function_BusSize        = @(obj, V, I)     10;
        function_CompSize       = @(obj,t,x,V,I,u) 15;

        function_BusHeigth      = @(obj, V, I)      0;
        function_CompHeight     = @(obj,t,x,V,I,u)  1;

        function_BusColor       = @(obj, V, I)     nan;
        function_CompColor      = @(obj,t,x,V,I,u) nan;

        function_BusLineColor   = @(obj, V, I)     nan;
        function_BranchColor    = @(obj,Vfrom,Vto) nan;

        function_BusLineWidth   = @(obj, V, I)     2;
        function_BranchWidth    = @(obj,Vfrom,Vto) 2;
        
        Graph
        Quiver
        
        ColorMap = turbo;

    end

    properties(Access=protected)
        G
        net
        nbus
        nbr
        Edge_idx_branch
        Edge_idx_BusLine
        normalize_range = 1.5;
        Colorbar
    end

    methods
        function obj = map_base(net)
            obj.net = net;
            obj.initialize;
        end

        function initialize(obj)
            obj.nbus = numel(obj.net.a_bus);
            obj.nbr = numel(obj.net.a_branch);
            
            % グラフストラクチャの作成
            %obj.G = graph(diag(ones(2*obj.nbus,1)), 'omitselfloops');
            from = [tools.hcellfun(@(br) br.from,obj.net.a_branch) , 1:obj.nbus];
            to   = [tools.hcellfun(@(br) br.to  ,obj.net.a_branch) ,(1:obj.nbus)+obj.nbus];
            admittance =  tools.hcellfun(@(br) abs(1/br.x)  ,obj.net.a_branch);
            EndNodes = [from;to]';
            Weight   = [admittance, ones(1,obj.nbus)]';
            idx      = (1:obj.nbus+obj.nbr)';
            obj.G = graph(table(EndNodes,Weight,idx));

            Edge_idx = obj.G.Edges.idx;
            [~,Edge_idx] = sort(Edge_idx);
            obj.Edge_idx_branch  = Edge_idx( 1:obj.nbr);
            obj.Edge_idx_BusLine = Edge_idx((1:obj.nbus)+obj.nbr);

            % グラフプロット
            obj.Graph = plot(obj.G);
            axis off
            %layout(obj.Graph,'force','WeightEffect','direct')
            % XYデータの初期設定
                obj.Graph.XData = 10*[obj.Graph.XData(1:obj.nbus),obj.Graph.XData(1:obj.nbus)];
                obj.Graph.YData = 10*[obj.Graph.YData(1:obj.nbus),obj.Graph.YData(1:obj.nbus)];
            % ラインの太さの初期設定
                obj.Graph.LineWidth     = ones(obj.nbr+obj.nbus, 1);
            % ラインスタイルの初期設定
                LS = cell(obj.nbr+obj.nbus, 1);
                LS(:) = {'-'};
                obj.Graph.LineStyle     = LS;
            % ラインの色の初期設定
                obj.Graph.EdgeColor     = zeros(obj.nbr+obj.nbus, 3);
            % ノードの形の初期設定
                M = cell(obj.nbus*2, 1);
                M(:) = {'o'};
                obj.Graph.Marker        = M;
            % ノードの色の初期設定
                obj.Graph.NodeColor     = zeros(2*obj.nbus,3);
            % ノードサイズのの初期設定
                obj.Graph.MarkerSize    = ones(2*obj.nbus,1);

            % ノードラベルの初期設定
                Marker_tag                          = cell(1,2*obj.nbus);
                Marker_tag(1:obj.nbus)              = tools.arrayfun(@(i) ['Bus',num2str(i)], 1:obj.nbus);
                Marker_tag(obj.nbus+(1:obj.nbus))   = {''};
                obj.Graph.NodeLabel                 = Marker_tag;
                obj.Graph.NodeFontSize              = 6*ones(obj.nbus*2,1);
                obj.Graph.NodeFontWeight            = 'bold';

            % カラーバーの初期設定
                Position = obj.Graph.Parent.Position;
                Position(1) = Position(1) + 0.1*Position(3);
                Position(3) = 0.8*Position(3);
                Position(2) = Position(2) + 0.05;
                Position(4) = 0.01;
                obj.Colorbar = colorbar('Location','south','Position',Position,'TickLabels',{});
                obj.Colorbar.Parent.Colormap = obj.ColorMap;

            % エッジの透明度を調整
                obj.Graph.EdgeAlpha = 0.8;
        end

        function set_equilibrium(obj)
            [x,u] = obj.format_xu([],[]);
            [V,I] = obj.format_VI([],[]);
            t = 0;
            already_foramt = true;

            obj.set({ ...
                'BusSize'  , 'CompSize'  , ...
                'BusHeigth', 'CompHeight', ...
                'BusColor' , 'CompColor' , ...
                'BusLineColor', 'BranchColor', ...
                'BusLineWidth', 'BranchWidth', ...
                }, t,x,V,I,u,already_foramt)
        end

        function set(obj, target, t, x, V, I, u, already_format)
            if nargin<8
                already_format =false;
            end

            if iscell(target)
                cellfun(@(target_) obj.set(target_,t,x,V,I,u,already_format),target)

            elseif ischar(target) || isstring(target)
                if ~ already_format
                    [x,u] = obj.format_xu(x,u);
                    [V,I] = obj.format_VI(V,I);
                end
                f = obj.(['function_',target]);
                f_is_cell = iscell(obj.(['function_',target]));
                if isa(f,'double')
                    f = @(varargin) f;
                end

                if contains(target, 'Comp')
                    data = zeros(obj.nbus,1);
                    for i = 1:obj.nbus
                        c = obj.net.a_bus{i}.component;
                        if f_is_cell
                            f = obj.(['function_',target]){i};
                        end
                        data(i) = f(c, t, x{i}, V{i}, I{i}, u{i});
                    end
                elseif contains(target, 'Bus')
                    data = zeros(obj.nbus,1);
                    for i = 1:obj.nbus
                        b = obj.net.a_bus{i};
                        if f_is_cell
                            f = obj.(['function_',target]){i};
                        end
                        data(i) = f(b, V{i}, I{i});
                    end
                elseif contains(target, 'Branch')
                    data = zeros(obj.nbr,1);
                    for i = 1:obj.nbr
                        br = obj.net.a_branch{i};
                        if f_is_cell
                            f = obj.(['function_',target]){i};
                        end
                        data(i) = f(br, V{br.from}, V{br.to});
                    end
                end
    
                if contains(target,'Height')
                    data = obj.normalize( data, [-1,1]);
                    data(isnan(data)) = 0;
                elseif contains(target,'Size')
                    data = obj.normalize( data, [10,30], false);
                    data(isnan(data)) = 10;
                elseif contains(target,'Color')
                    if all(data>=0,'all')
                        temp = round( obj.normalize( data, 1+[-255,255]));
                    else
                        temp = round( obj.normalize( data, [1,256]));
                    end
                    data = zeros(numel(data),3);
                    data(~isnan(temp),:) = obj.ColorMap(temp(~isnan(temp)),:);
                elseif contains(target,'Width')
                    data = obj.normalize( data, [2,8], false);
                    data(isnan(data)) = 2;
                end
    
                switch target
                    case 'BusSize'
                        obj.Graph.MarkerSize(1:obj.nbus)            = data;
                    case 'CompSize'
                        obj.Graph.MarkerSize(obj.nbus+(1:obj.nbus)) = data;
                    case 'BusHeigth'
                        obj.Graph.ZData(1:obj.nbus)                 = data;
                    case 'CompHeight'
                        obj.Graph.ZData(obj.nbus+(1:obj.nbus))      = data;
                    case 'BusColor'
                        obj.Graph.NodeColor(1:obj.nbus,:)           = data;
                    case 'CompColor'
                        obj.Graph.NodeColor(obj.nbus+(1:obj.nbus),:)= data;
                    case 'BusLineColor'
                        obj.Graph.EdgeColor(obj.Edge_idx_BusLine,:) = data;
                    case 'BranchColor'
                        obj.Graph.EdgeColor(obj.Edge_idx_branch,:)  = data;
                    case 'BusLineWidth'
                        obj.Graph.LineWidth(obj.Edge_idx_BusLine)   = data;
                    case 'BranchWidth'
                        obj.Graph.LineWidth(obj.Edge_idx_branch)    = data;
                end

                if contains(target,'Height') && ~isempty(obj.Quiver)
                    obj.refresh_quiver;
                end
            end
        end

    end


    methods(Access = protected)

        %bus mainのグラフプロット上にグレーの円盤を作成する関数
        function plt = plot_circle(obj)
            hold on
            meanX  = mean(obj.Graph.XData);
            meanY  = mean(obj.Graph.YData);
            radius = 1.25 * max(abs([obj.Graph.XData-meanX,obj.Graph.YData-meanY]));

            dd =500;
            [x,y] = meshgrid(linspace(meanX-radius,meanX+radius,dd),...
                             linspace(meanY-radius,meanY+radius,dd));
            z = zeros(dd,dd);
            z( ((x-meanX).^2 +  (y-meanY).^2) >radius^2) = nan;
            plt = surf(x,y,z,'EdgeColor','none','FaceAlpha',0.1,'FaceColor','#7E2F8E');
        end



        %component mainのグラフプロットに電力の方向を表した矢印をプロット
        function set_quiver(obj)
            hold on
            
            obj.Quiver = plot(graph(diag(ones(1,obj.nbus)),'omitselfloops'));
            obj.Quiver.MarkerSize = 5 * obj.Graph.LineWidth(obj.Edge_idx_BusLine);
            obj.Quiver.NodeColor  =     obj.Graph.EdgeColor(obj.Edge_idx_BusLine,:);
            obj.Quiver.NodeLabel  = '';
            obj.Quiver.Marker     = arrayfun(@(i) {'v'}, 1:obj.nbus);
            
            obj.Quiver.XData = obj.Graph.XData(1:obj.nbus);
            obj.Quiver.YData = obj.Graph.YData(1:obj.nbus);
            obj.Quiver.ZData =(obj.Graph.ZData(1:obj.nbus) + obj.Graph.ZData(obj.nbus+(1:obj.nbus)) )/2;
        end

        function refresh_quiver(obj)
            if numel(obj.Quiver) ~=0
                obj.Quiver.ZData =(obj.Graph.ZData(1:obj.nbus) + obj.Graph.ZData(obj.nbus+(1:obj.nbus)) )/2;
            end
        end


        %%%% グラフパラメータのセット %%%

        function [x_,u_] = format_xu(obj,x,u)
            if isempty(x)
                x = obj.net.x_equilibrium;
            end
            xidx = 0;
            uidx = 0;
            x_ = cell(obj.nbus,1);
            u_ = cell(obj.nbus,1);
            for i = 1:obj.nbus
                nx = obj.net.a_bus{i}.component.get_nx;
                nu = obj.net.a_bus{i}.component.get_nu;
                x_{i} = x(xidx+(1:nx));
                if isempty(u)
                    u_{i} = zeros(nu,1);
                else
                    u_{i} = u(uidx+(1:nu));
                end
                xidx = xidx + nx;
                uidx = uidx + nu;
            end
        end

        function [V,I] = format_VI(obj,V,I)
            if isempty(V)
                if ~isempty(I)
                    warning('Iのみの指定では計算することができません。定常潮流状態の値に置き換えます。')
                end
                V = obj.net.V_equilibrium;
                I = obj.net.I_equilibrium;

            elseif ~isempty(V) && isempty(I)
                Y = obj.net.get_admittance_matrix;
                if numel(V) == obj.nbus
                    I = Y*V;
                elseif numel(V) == obj.nbus*2
                    I = Y * tools.vec2complex(V);
                else
                    error('Vの要素数が合っていません');
                end

            else
                if numel(V) == 2*obj.nbus
                    V = tools.vec2complex(V);
                elseif numel(V) ~= obj.nbus
                    error('Vの要素数が合っていません');
                end

                if numel(I) == 2*obj.nbus
                    I = tools.vec2complex(I);
                elseif numel(I) ~= obj.nbus
                    error('Iの要素数が合っていません');
                end

            end

            V = arrayfun(@(idx) [real(V(idx));imag(V(idx))], (1:obj.nbus)','UniformOutput',false);
            I = arrayfun(@(idx) [real(I(idx));imag(I(idx))], (1:obj.nbus)','UniformOutput',false);
        end

        function data_raw = normalize(obj, data_raw, min_max, zerobase)
            if ~ all( isnan(data_raw), "all")
                data = data_raw(~isnan(data_raw));
                if ~ all( (data-data(1))==0  , "all")
                    if nargin < 4
                        zerobase = true;
                    end
                    
                    if zerobase
                        data = normalize(data,'center',0);
                    else
                        data = normalize(data);
                    end
                    nlim = abs(obj.normalize_range);
                    data = min(max(data,-nlim),nlim);
                    data = mean(min_max) + ( data/nlim * diff(min_max)/2 );
                    data_raw(~isnan(data_raw)) = data;
                end
            end
        end
    end
end