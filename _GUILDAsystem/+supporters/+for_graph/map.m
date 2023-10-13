classdef map < handle

    properties

        a_bus
        a_component
        a_branch
        a_busline
        
        Graph
        Quiver
        
        ColorMap = turbo;
        Colorbar

    end

    properties(Dependent)
        ZLim
        XLim
        YLim
    end

    properties(Access=protected)
        G
        Axes
        net
        nbus
        nbr
        Edge_idx_branch
        Edge_idx_BusLine
        Edge_idx_nonunit
        normalize_range = 2;
    end

    methods
        function obj = map(net,ax)
            % blue = linspace(1,0.2,128);
            % red  = linspace(0.2,1,128);
            % obj.ColorMap = [ [zeros(128,2),blue'];...
            %                  [ red',zeros(128,2)] ];
            obj.net = net;
            
            if nargin < 2
                figure;
                obj.Axes = gca;
            else
                obj.Axes = ax;
            end
            %obj.Axes.tightPosition = [0,0,1,1];

            obj.build_graph;
        end

        function build_graph(obj)
            n_bus = numel(obj.net.a_bus);
            n_br = numel(obj.net.a_branch);
            
            % グラフストラクチャの作成
                %obj.G = graph(diag(ones(2*n_bus,1)), 'omitselfloops');
                from = [tools.hcellfun(@(br) br.from,obj.net.a_branch) , 1:n_bus];
                to   = [tools.hcellfun(@(br) br.to  ,obj.net.a_branch) ,(1:n_bus)+n_bus];
                admittance =  tools.hcellfun(@(br) abs(br.x)  ,obj.net.a_branch);
                EndNodes = [from;to]';
                Weight   = [normalize(admittance,'range',[2,3]), ones(1,n_bus)]';
                idx      = (1:n_bus+n_br)';
                obj.G = graph(table(EndNodes,Weight,idx));
    
                Edge_idx = obj.G.Edges.idx;
                [~,Edge_idx] = sort(Edge_idx);
                obj.Edge_idx_branch  = Edge_idx( 1:n_br);
                obj.Edge_idx_BusLine = Edge_idx((1:n_bus)+n_br);
                is_nonunit = tools.vcellfun(@(b) isa(b.component,'component_empty'), obj.net.a_bus);
                obj.Edge_idx_nonunit = Edge_idx(find(is_nonunit)+n_br);

            % グラフプロット
                obj.Graph = plot(obj.Axes,obj.G,'-');
                layout(obj.Graph,'force','WeightEffect','direct')
            
            % 初期設定
                % XYデータの初期設定
                    obj.Graph.XData = [obj.Graph.XData(1:n_bus),obj.Graph.XData(1:n_bus)];
                    obj.Graph.YData = [obj.Graph.YData(1:n_bus),obj.Graph.YData(1:n_bus)];
                    obj.Graph.ZData = [zeros(1,n_bus),ones(1,n_bus)];
                % ラインの太さの初期設定
                    obj.Graph.LineWidth     = ones(n_br+n_bus, 1);
                % ラインスタイルの初期設定
                    LS = cell(n_br+n_bus, 1);
                    LS(:) = {'-'};
                    obj.Graph.LineStyle     = LS;
                % ラインの色の初期設定
                    obj.Graph.EdgeColor     = zeros(n_br+n_bus, 3);
                % ノードの形の初期設定
                    M = cell(n_bus*2, 1);
                    M(:) = {'o'};
                    obj.Graph.Marker        = M;
                % ノードの色の初期設定
                    obj.Graph.NodeColor     = zeros(2*n_bus,3);
                % ノードサイズのの初期設定
                    obj.Graph.MarkerSize    = 10*ones(2*n_bus,1);
    
                % ノードラベルの初期設定
                    Marker_tag                  = cell(1,2*n_bus);
                    Marker_tag(:) = {''};
                    obj.Graph.NodeLabel         = Marker_tag;
                    obj.Graph.NodeFontSize      = 8*ones(n_bus*2,1);
                    obj.Graph.NodeFontWeight    = 'bold';
    
                % エッジの透明度を調整
                    obj.Graph.EdgeAlpha = 0.7;

            % ノード・エッジpropertiesの管理クラスの生成
                c = obj.net.a_bus;
                obj.a_bus       = tools.arrayfun(@(i) supporters.for_graph.elements.graph_node(obj.Graph,i      ,obj,i,c{i})          , (1:n_bus)');
                obj.a_component = tools.arrayfun(@(i) supporters.for_graph.elements.graph_node(obj.Graph,i+n_bus,obj,i,c{i}.component), (1:n_bus)');
                obj.a_branch    = tools.arrayfun(@(i) supporters.for_graph.elements.graph_edge(obj.Graph,Edge_idx(i)     ,obj,i), (1:n_br )');
                obj.a_busline   = tools.arrayfun(@(i) supporters.for_graph.elements.graph_edge(obj.Graph,Edge_idx(i+n_br),obj,i), (1:n_bus)');
            
        end

        function initialize(obj)
            culcP = @(c) real(c.V_equilibrium*conj(c.I_equilibrium));
    
            cellfun(@(b) set(b,'marker', 's' ), obj.a_bus)
            cellfun(@(b) set(b,'color' , [0.5,0.5,0.5] ), obj.a_bus)
            cellfun(@(b) set(b,'size' , 7 ), obj.a_bus)
            cellfun(@(b) set(b,'Label' , [b.object.Tag,num2str(b.number)] ), obj.a_bus)
            
            cellfun(@(c) set(c,'marker', supporters.for_graph.function.marker.subject2CompType(c.object)), obj.a_component)

            not_empty = tools.vcellfun(@(b) ~isa(b.component,'component.empty'), obj.net.a_bus);
            cellfun(@(c) set(c,'ZData' , sign(culcP(c.object))), obj.a_component(not_empty));
            cellfun(@(c) set(c,'size' , 20), obj.a_component);
            cellfun(@(c) set(c,'color' , supporters.for_graph.function.Color.subject2CompType(c.object)), obj.a_component);
            cellfun(@(c) set(c,'Label' , [c.object.Tag,num2str(c.number)] ), obj.a_component( not_empty))
            cellfun(@(c) set(c,'Label' , ''                               ), obj.a_component(~not_empty))

            cellfun(@(b) set(b,'width',2), obj.a_branch)
            cellfun(@(b) set(b,'width',0.1), obj.a_busline)
            cellfun(@(b) set(b,'style','none'), obj.a_busline(~not_empty))

            view(obj.Axes,0,50)
            obj.ZLim = 3;
            axis(obj.Axes,'off')
        end

        function remove_margin(obj)
            obj.Axes.InnerPosition = [0,0,1,1];
        end

        function set.ZLim(obj,data)
            if numel(data)==1
                data = data*[-1,1];
            end
            zlim(obj.Axes,data)
        end

        function set.XLim(obj,data)
            if numel(data)==1
                data = data*[-1,1];
            end
            xlim(obj.Axes,data)
        end

        function set.YLim(obj,data)
            if numel(data)==1
                data = data*[-1,1];
            end
            ylim(obj.Axes,data)
        end
        
    
        %機器の種類に応じて色付けする。
        function set_Color_subject2BusType(obj)
            for i = 1:numel(obj.net.a_bus)
                c = obj.net.a_bus{i};
                obj.a_bus{i} = supporters.for_graph.function.Color.subject2BusType(c);
            end
        end

        %機器の種類に応じて色付けする。
        function set_Color_subject2CompType(obj)
            for i = 1:numel(obj.net.a_bus)
                c = obj.net.a_bus{i}.component;
                obj.a_component{i} = supporters.for_graph.function.Color.subject2CompType(c);
            end
        end

        function data = normalize(~,data,varargin)

            p = inputParser;
            p.CaseSensitive = false;
            
            addParameter(p, 'mean'  , nan);
            addParameter(p, 'sigma' , nan);
        
            addParameter(p, 'base'  , 0);
            addParameter(p, 'scale' , 0.5);
            addParameter(p, 'range' , [-1,1]);
            
            parse(p, varargin{:});
            op = p.Results;
            
            
            if isnan(op.mean)
                op.mean = mean(data,'all');
            end
        
            if isnan(op.sigma)
                op.sigma = sqrt( sum( (data-op.mean).^2, "all") /numel(data) );
            end
        
            data = (data-op.mean)/op.sigma;
            data = op.base + data*op.scale;
            
            data(data<=op.range(1)) = op.range(1);
            data(data>=op.range(2)) = op.range(2);
            
        end

        function cidx = val2color(obj,data,cMap)

            if nargin<3
                cMap = obj.ColorMap;
            end
            ncolor = size(cMap,1);

            data(data<-1) = -1;
            data(data> 1) =  1;
            
            cidx = data*ncolor/2 + ncolor/2;
            cidx = round(cidx);
            cidx(cidx<=0) = 1;

        end

    end


    methods(Access = protected)

        %カラーバーを作成する関数
        function set_colorbar(obj,location,Position)
            obj.Colorbar = colorbar('Location',location,'Position',Position,'TickLabels',{});
            obj.Colorbar.Parent.Colormap = obj.ColorMap;
            obj.Colorbar.TickLabels  = {'-','o','+'};
            obj.Colorbar.Limits      = [0,1];
            obj.Colorbar.Ticks       = [0,0.5,1];
            obj.Colorbar.FontWeight  = 'bold';
            %obj.Colorbar.AxesLocation= 'in';
            obj.Colorbar.FontSize    = 10;
            %obj.Colorbar.FontAngle   = 'italic';
        end

        %bus mainのグラフプロット上にグレーの円盤を作成する関数
        function plt = plot_circle(obj)
            meanX  = mean(obj.Graph.XData);
            meanY  = mean(obj.Graph.YData);
            radius = 1.25 * max(abs([obj.Graph.XData-meanX,obj.Graph.YData-meanY]));

            dd =500;
            [x,y] = meshgrid(linspace(meanX-radius,meanX+radius,dd),...
                             linspace(meanY-radius,meanY+radius,dd));
            z = zeros(dd,dd);
            z( ((x-meanX).^2 +  (y-meanY).^2) >radius^2) = nan;
            hold(obj.Axes,'on')
            plt = surf(obj.Axes,x,y,z,'EdgeColor','none','FaceAlpha',0.1,'FaceColor','#7E2F8E');
            hold(obj.Axes,'off')

        end



        %component mainのグラフプロットに電力の方向を表した矢印をプロット
        function set_quiver(obj,ax)
            
            if nargin<2
                ax = gca;
            end
            hold(ax,'on')

            obj.Quiver = plot(ax,graph(diag(ones(1,obj.nbus)),'omitselfloops'));
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

    end
end