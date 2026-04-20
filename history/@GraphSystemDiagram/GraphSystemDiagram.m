classdef GraphSystemDiagram < auxiliary
    % <@Desc> 
    % <@Role> 
    % Layer Structure
    % <@Constructor> 
    % None (This class should not be instantiated directly.)

    properties
        NodeFontSize   (1,1) double = 10;
        NodeFontWeight (1,1) string = "bold";
        LineWidth      (1,1) double = 4;
        MarkerSize     (1,1) double = 10; 
        colormap       (:,3) double = turbo;
        EdgeColor      (1,1) string {mustBeMember(EdgeColor, ["none", "Loss", "current"])} = "current";
        MarkerColor    (1,1) string {mustBeMember(MarkerColor, ["none", "Vmag", "Varg", "Vimag", "P", "Q", "Pabs", "Qabs", "I"])} = "none";
    end
    properties(SetAccess = private)
        ax
        plt
    end
    properties(Access = private)
        a_PowerNetwork
        im_edge
    end
        

    methods
        function obj = GraphSystemDiagram(net)
            obj.a_PowerNetwork = net;
        end

        function plot(obj, ax)
            arguments
                obj
                ax (1,1) matlab.graphics.axis.Axes = gca
            end

            obj.ax = ax;
            if isempty(obj.plt) || ~isvalid(obj.plt)
                obj.draw_topology();
            end

            % Apply styles to the graph
            obj.EdgeColor      = obj.EdgeColor;    
            obj.MarkerColor    = obj.MarkerColor;  
            obj.NodeFontSize   = obj.NodeFontSize; 
            obj.NodeFontWeight = obj.NodeFontWeight;
            obj.LineWidth      = obj.LineWidth;     
            obj.MarkerSize     = obj.MarkerSize;
        end
    end

    methods (Access = private)
        function h_plot = draw_topology(obj)
            net = obj.a_PowerNetwork;

            a_Bus    = net.a_Bus;
            str_node = string(a_Bus);
            get_axis = @(para) [para.Xaxis; para.Yaxis];
            rm_axis  = tools.hcellfun(@(b) get_axis(b.para_graph), a_Bus);

            str_edge    = tools.hcellfun(@(bra) string(bra.a_Bus), net.a_Branch);
            [~,obj.im_edge] = ismember(str_edge, str_node);
            
            s = obj.im_edge(1,:); 
            t = obj.im_edge(2,:); 
            
            G = digraph(s, t, [], str_node);
            

            cm_Vst  = tools.hcellfun(@(b) b.cv_Vequilibrium   , obj.a_PowerNetwork.a_Branch);
            rm_Varg = angle(cm_Vst);
            lr_Varg = (rm_Varg(2,:)-rm_Varg(1,:)) >= 0;

            for i = 1:numel(lr_Varg)
                from = obj.im_edge(1,i);
                to   = obj.im_edge(2,i);
                if lr_Varg(i)
                    if ~findedge(G, from, to)
                        G = flipedge(G, to, from);
                    end
                else
                    if ~findedge(G, to, from)
                        G = flipedge(G, from, to);
                    end
                end
            end


            cla(obj.ax)
            if any(isnan(rm_axis(:)), 'all')
                h_plot = plot(obj.ax, G);
            else
                X_coords = rm_axis(1,:);
                Y_coords = rm_axis(2,:);
                h_plot = plot(obj.ax, G, 'XData', X_coords, 'YData', Y_coords);
            end
            h_plot.Marker = tools.hcellfun(@(b) b.para_graph.Marker, a_Bus);
            obj.plt = h_plot;
            

            title(obj.ax, 'Power System Topology', 'FontSize', 14);
            axis(obj.ax, 'equal');
            axis(obj.ax, 'off');
        end

        function flag = validate(obj)
            flag = isempty(obj.plt) || ~isvalid(obj.plt) || ~isgraphics(obj.ax);
        end
        
    end


    % Semethods for applying styles to the graph
    methods
        function set.colormap(obj, cmap)
            % カラーマップの適用
            obj.colormap    = cmap;
            obj.EdgeColor   = obj.EdgeColor;   %#ok
            obj.MarkerColor = obj.MarkerColor; %#ok
        end

        function set.EdgeColor(obj, edge_color)
            obj.EdgeColor = edge_color;
            if obj.validate; return; end

            n_edge = size(obj.plt.EdgeColor,1);%#ok
            if edge_color == "none"
                obj.plt.EdgeColor = zeros(n_edge,3);%#ok
                return
            end
            
            net     = obj.a_PowerNetwork;%#ok
            cv_Ist  = tools.vcellfun(@(b) b.cv_Iequilibrium(1), net.a_Branch);
            switch edge_color
                case "Loss"
                    rv_R     = tools.vcellfun(@(b) b.para_dynamics.R, net.a_Branch);
                    rv_order = rv_R .* cv_Ist .* conj(cv_Ist);
                case "current"
                    rv_order = abs(cv_Ist);
            end
            rm_color = obj.colormap;%#ok
            rv_order = rv_order + min(rv_order);
            rv_order = rv_order/max(rv_order) * (size(rm_color,1)-1) + 1;
            rv_order = round(rv_order);
            obj.plt.EdgeColor = rm_color(rv_order,:);%#ok
        end
        function set.MarkerColor(obj, marker_color)
            obj.MarkerColor = marker_color;
            if obj.validate; return; end

            n_node = size(obj.plt.XData,1);%#ok
            if marker_color == "none"
                obj.plt.NodeColor = zeros(n_node,3);%#ok
                return
            end
            
            net     = obj.a_PowerNetwork; %#ok
            cv_Vst  = net.cv_Vequilibrium;
            cv_Ist  = net.cv_Iequilibrium;
            % "Vmag", "Varg", "Vimag", "P", "Q", "Pabs", "Qabs", "I"])} = "none";
            switch marker_color
                case "Vmag"
                    rv_order = abs(cv_Vst);
                case "Varg"
                    rv_order = angle(cv_Vst);
                case "Vimag"
                    rv_order = imag(cv_Vst);
                case "P"
                    rv_order = real(cv_Vst .* conj(cv_Ist));
                case "Q"
                    rv_order = imag(cv_Vst .* conj(cv_Ist));
                case "Pabs"
                    rv_order = abs(real(cv_Vst .* conj(cv_Ist)));
                case "Qabs"
                    rv_order = abs(imag(cv_Vst .* conj(cv_Ist)));
                case "I"
                    rv_order = abs(cv_Ist);
            end
            rm_color = obj.colormap;%#ok
            rv_order = rv_order - min(rv_order);
            rv_order = rv_order/max(rv_order) * (size(rm_color,1)-1) + 1;
            rv_order = round(rv_order);
            obj.plt.NodeColor = rm_color(rv_order,:); %#ok
        end
        function set.NodeFontSize(obj, font_size)
            obj.NodeFontSize = font_size;
            if obj.validate; return; end

            obj.plt.NodeFontSize = font_size;%#ok
        end
        function set.NodeFontWeight(obj, font_weight)
            obj.NodeFontWeight = font_weight;
            if obj.validate; return; end
            
            obj.plt.NodeFontWeight = font_weight;%#ok
        end
        function set.LineWidth(obj, line_width)
            obj.LineWidth = line_width;
            if obj.validate; return; end

            obj.plt.ArrowSize = line_width*3; %#ok
            obj.plt.LineWidth = line_width;   %#ok
        end
        function set.MarkerSize(obj, sz)
            obj.MarkerSize = sz;
            if obj.validate; return; end

            obj.plt.MarkerSize = sz;%#ok
        end
    end
end