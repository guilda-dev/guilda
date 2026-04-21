classdef DrawerNetDiagram < auxiliary
    % 3D system diagram renderer implemented without digraph plot.

    properties
        ColorLim       (1,2) double = [0,2];
        ColorMap       (:,3) double = turbo;
        ColorMode      (1,1) string {mustBeMember(ColorMode, [...
                                            "none",               ...
                                            "Loss",               ...
                                            "I (current)",        ...
                                            "P (active power)",   ...
                                            "Q (reactive power)", ...
                                            "User defined"])} = "I (current)";
        NodeFontSize      (1,1) double = 3;
        NodeFontWeight    (1,1) string = "bold";
        EdgeWidthSclae    (1,1) double = 0.15;
        EdgeWidthOffset   (1,1) double = 1.5;
        EdgeWidthMode     (1,1) string {mustBeMember(EdgeWidthMode, ["none","G", "B", "Y", "SvdMaxYmat"])} = "SvdMaxYmat";
        MarkerSize        (1,1) double = 5;
        NodeHeightMode    (1,1) string {mustBeMember(NodeHeightMode, ["none", "Vmag", "Varg", "Vsin", "P", "Q"])} = "Varg";
        NodeB_ColorVal    (:,1) double = [];
        NodeC_ColorVal    (:,1) double = [];
        EdgeB2B_ColorVal  (:,1) double = [];
        EdgeB2C_ColorVal  (:,1) double = [];
        NodeLabelB        (:,1) string = [];
        NodeLabelC        (:,1) string = [];
        NodeLabelVisible  (1,1) logical = false;

        EdgeB2B_forward   (:,1) double = [];
        EdgeB2C_forward   (:,1) double = [];
    end

    % Properties for storing graphics objects
    properties
        ax
    end
    properties(SetAccess = private)
        plt
        flag_new
    end

    % Private properties for storing parameters of the system
    properties(Access = private)
        im_edge
        
        cm_Ymat

        tab_bus
        tab_branch
        tab_component

        n_bus
        n_branch
        n_component

        str_bus
        str_branch
        str_component

        cm_Vbus2Ibranch
        cm_Vbus2Vbranch
    end

    % Properties for storing values for current state
    properties(Access = private)
        cv_Vbus
        cv_Ibus
        rv_Pbus
        rv_Qbus

        cm_Vbranch
        cm_Ibranch
        rm_Pbranch
        rm_Qbranch

        cv_Vcomp
        cv_Icomp
        rv_Pcomp
        rv_Qcomp
    end


    methods
        function obj = DrawerNetDiagram(net, ax)
            arguments
                net (1,1) PowerNetwork
                ax  (1,1) matlab.graphics.axis.Axes = axes('Parent',figure());
            end
            obj.ax = ax;
            obj.set_network(net);
            obj.set_powerflow(net);
        end

        set_powerflow(obj, cv_Vbus, cv_Icomp)
        set_network(obj, net)
    end

    % Private methods
    methods(Access = private)
        rehash(obj)
        draw_graph_network(obj)
        reflect_color_mode(obj)
        reflect_node_label(obj)
        reflect_arrow_forward(obj)
        apply_color_values(obj, h_list, rv_value)
        function flag = validate(obj)
            flag = isempty(obj.plt) || ~isgraphics(obj.ax);
        end
    end

    methods
        function set.ax(obj,ax)
            arguments
                obj 
                ax (1,1) matlab.graphics.axis.Axes
            end
            obj.ax = ax;
            obj.flag_new = true; %#ok
        end

        function set.ColorLim(obj, color_lim)
            obj.ColorLim  = color_lim;
            clim(obj.ax, obj.ColorLim);                                     %#ok
            obj.rehash();
        end

        function set.ColorMap(obj, cmap)
            obj.ColorMap  = cmap;
            colormap(obj.ax, obj.ColorMap);                                 %#ok
            obj.rehash();
        end

        function set.ColorMode(obj, edge_color_mode)
            obj.ColorMode = edge_color_mode;
            obj.reflect_color_mode();
        end

        % Setters for properties for node label appearance
        function set.NodeFontSize(obj, font_size)
            obj.NodeFontSize = font_size;
            if validate(obj); return; end

            h_label = obj.plt.NodeLabel;                                    %#ok
            for i = 1:numel(h_label)
                if isgraphics(h_label(i))
                    h_label(i).FontSize = font_size;
                end
            end
            h_label = obj.plt.CompLabel;                                    %#ok
            for i = 1:numel(h_label)
                if isgraphics(h_label(i))
                    h_label(i).FontSize = font_size;
                end
            end
        end
        function set.NodeFontWeight(obj, font_weight)
            obj.NodeFontWeight = font_weight;
            if validate(obj); return; end

            h_label = obj.plt.NodeLabel;                                    %#ok
            for i = 1:numel(h_label)
                if isgraphics(h_label(i))
                    h_label(i).FontWeight = font_weight;
                end
            end
        end

        % Setters for properties that require re-plotting
        function set.EdgeWidthOffset(obj, edge_width_offset)
            obj.EdgeWidthOffset = edge_width_offset;
            if ~validate(obj)
                obj.draw_graph_network;
                obj.reflect_color_mode;
                obj.reflect_node_label;
            end
        end
        function set.EdgeWidthSclae(obj, edge_width_sclae)
            obj.EdgeWidthSclae = edge_width_sclae;
            if ~validate(obj)
                obj.draw_graph_network;
                obj.reflect_color_mode;
                obj.reflect_node_label;
            end
        end
        function set.EdgeWidthMode(obj, edge_width_mode)
            obj.EdgeWidthMode = edge_width_mode;
            if ~validate(obj)
                obj.draw_graph_network;
                obj.reflect_color_mode;
                obj.reflect_node_label;
            end
        end
        function set.MarkerSize(obj, sz)
            obj.MarkerSize = sz;
            if ~validate(obj)
                obj.draw_graph_network;
                obj.reflect_color_mode;
                obj.reflect_node_label;
            end
        end
        function set.NodeHeightMode(obj, mode)
            obj.NodeHeightMode = mode;
            if ~validate(obj)
                obj.draw_graph_network;
                obj.reflect_color_mode;
                obj.reflect_node_label;
            end
        end

        % Setters for color values
        function set.NodeB_ColorVal(obj, rv_value)
            obj.NodeB_ColorVal = rv_value;
            if validate(obj) || ~isfield(obj.plt, 'NodeMain'); return; end  %#ok
            obj.apply_color_values(obj.plt.NodeMain, rv_value);             %#ok
        end

        function set.NodeC_ColorVal(obj, rv_value)
            obj.NodeC_ColorVal = rv_value;
            if validate(obj) || ~isfield(obj.plt, 'CompMain'); return; end  %#ok
            obj.apply_color_values(obj.plt.CompMain, rv_value);             %#ok
        end

        function set.EdgeB2B_ColorVal(obj, rv_value)
            obj.EdgeB2B_ColorVal = rv_value;
            if validate(obj) || ~isfield(obj.plt, 'EdgeMain') || ~isfield(obj.plt, 'EdgeArrow'); return; end %#ok
            obj.apply_color_values(obj.plt.EdgeMain,  rv_value);            %#ok
            obj.apply_color_values(obj.plt.EdgeArrow, rv_value);            %#ok
        end

        function set.EdgeB2C_ColorVal(obj, rv_value)
            obj.EdgeB2C_ColorVal = rv_value;
            if validate(obj) || ~isfield(obj.plt, 'CompEdge'); return; end  %#ok
            obj.apply_color_values(obj.plt.CompEdge, rv_value);             %#ok
        end


        % Setters for node labels
        function set.NodeLabelB(obj, label)
            obj.NodeLabelB = string(label);
            for i =1:numel(obj.plt.NodeLabel)                               %#ok
                if isgraphics(obj.plt.NodeLabel(i))                         %#ok
                    obj.plt.NodeLabel(i).String = obj.NodeLabelB(i);        %#ok
                end
            end
        end

        function set.NodeLabelC(obj, label)
            obj.NodeLabelC = string(label);
            for i =1:numel(obj.plt.CompLabel)                               %#ok
                if isgraphics(obj.plt.CompLabel(i))                         %#ok
                    obj.plt.CompLabel(i).String = obj.NodeLabelC(i);        %#ok
                end
            end
        end

        function set.NodeLabelVisible(obj, is_visible)
            obj.NodeLabelVisible = is_visible;
            if validate(obj) || ~isfield(obj.plt, 'NodeLabel'); return; end %#ok
            for i =1:numel(obj.plt.NodeLabel)                               %#ok
                if isgraphics(obj.plt.NodeLabel(i))                         %#ok
                    obj.plt.NodeLabel(i).Visible = is_visible;              %#ok
                end
            end
            for i =1:numel(obj.plt.CompLabel)                               %#ok
                if isgraphics(obj.plt.CompLabel(i))                         %#ok
                    obj.plt.CompLabel(i).Visible = is_visible;              %#ok
                end
            end
        end


        % Setters for edge direction (for directed edge shapes)
        function set.EdgeB2B_forward(obj, forward)
            obj.EdgeB2B_forward = forward;
            if validate(obj) || ~isfield(obj.plt, 'EdgeArrow'); return; end %#ok
            for i = 1:numel(obj.plt.EdgeArrow)                              %#ok
                h_arrowi = obj.plt.EdgeArrow(i);                            %#ok
                if ~isgraphics(h_arrowi)
                    continue
                end
                ud = h_arrowi.UserData;
                switch sign(forward(i))
                    case 0
                        set(ud.To, 'Visible', 'off');
                        set(ud.From, 'Visible', 'off');
                    case 1
                        set(ud.To, 'Visible', 'on');
                        set(ud.From, 'Visible', 'off');
                    case -1
                        set(ud.To, 'Visible', 'off');
                        set(ud.From, 'Visible', 'on');
                end
            end
        end

        function set.EdgeB2C_forward(obj, forward)
            obj.EdgeB2C_forward = forward;
            if validate(obj) || ~isfield(obj.plt, 'CompEdge'); return; end  %#ok
            for i = 1:numel(obj.plt.CompArrow)                              %#ok
                h_edgei = obj.plt.CompArrow(i);                             %#ok
                if ~isgraphics(h_edgei)
                    continue
                end
                ud = h_edgei.UserData;
                switch sign(forward(i))
                    case 0
                        set(ud.To, 'Visible', 'off');
                        set(ud.From, 'Visible', 'off');
                    case 1
                        set(ud.To, 'Visible', 'on');
                        set(ud.From, 'Visible', 'off');
                    case -1
                        set(ud.To, 'Visible', 'off');
                        set(ud.From, 'Visible', 'on');  
                end
            end
            
        end
    end
end


