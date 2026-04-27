classdef DrawerNetDiagram < auxiliary
% <@Desc>
% 3D network diagram renderer for power systems.
% Draws buses, branches, and components as a graph plot on a MATLAB axes object.
% Supports interactive hover tooltips, color-coded edge/node visualization, and
% dynamic updates to color values, labels, and edge directions.
% <@Role>
% auxiliary
% <@Constructor>
% DrawerNetDiagram(net, ax, opt)
%  i.e.
%  >> drawer = DrawerNetDiagram(net)
%  >> drawer = DrawerNetDiagram(net, ax)
%      - net: PowerNetwork object to visualize
%      - ax:  MATLAB Axes object to draw on (default: new axes in a new figure)

    properties

        % <@Desc> Color limits [min, max] for the colormap applied to edges and nodes.
        % <@Role> Graph
        % <@Type> double
        % <@Size> 1x2
        ColorLim       (1,2) double = [0,2];

        % <@Desc> Colormap matrix used for coloring edges and nodes.
        % <@Role> Graph
        % <@Type> double
        % <@Size> Nx3
        ColorMap       (:,3) double = turbo;

        % <@Desc> Color mode for edges/nodes ("none","Loss","I (current)","P (active power)","Q (reactive power)","User defined").
        % <@Role> Graph
        % <@Type> string
        % <@Size> 1x1
        ColorMode      (1,1) string {mustBeMember(ColorMode, [...
                                            "none",               ...
                                            "Loss",               ...
                                            "I (current)",        ...
                                            "P (active power)",   ...
                                            "Q (reactive power)", ...
                                            "User defined"])} = "I (current)";

        % <@Desc> Font size for node labels.
        % <@Role> Graph
        % <@Type> double
        % <@Size> 1x1
        NodeFontSize      (1,1) double = 7;

        % <@Desc> Font weight for node labels ("bold", "normal", etc.).
        % <@Role> Graph
        % <@Type> string
        % <@Size> 1x1
        NodeFontWeight    (1,1) string = "bold";

        % <@Desc> Scale factor for edge width rendering.
        % <@Role> Graph
        % <@Type> double
        % <@Size> 1x1
        EdgeWidthSclae    (1,1) double = 0.15;

        % <@Desc> Offset added to edge width rendering.
        % <@Role> Graph
        % <@Type> double
        % <@Size> 1x1
        EdgeWidthOffset   (1,1) double = 1.5;

        % <@Desc> Mode for computing edge width ("none","G","B","Y","SvdMaxYmat").
        % <@Role> Graph
        % <@Type> string
        % <@Size> 1x1
        EdgeWidthMode     (1,1) string {mustBeMember(EdgeWidthMode, ["none","G", "B", "Y", "SvdMaxYmat"])} = "SvdMaxYmat";

        % <@Desc> Marker size for bus nodes.
        % <@Role> Graph
        % <@Type> double
        % <@Size> 1x1
        MarkerSize        (1,1) double = 5;

        % <@Desc> Mode for computing node height ("none","Vmag","Varg","Vsin","P","Q").
        % <@Role> Graph
        % <@Type> string
        % <@Size> 1x1
        NodeHeightMode    (1,1) string {mustBeMember(NodeHeightMode, ["none", "Vmag", "Varg", "Vsin", "P", "Q"])} = "Varg";

        % <@Desc> Color values for bus nodes (used when ColorMode is "User defined").
        % <@Role> Graph
        % <@Type> double
        % <@Size> Nx1
        NodeB_ColorVal    (:,1) double = [];

        % <@Desc> Color values for component nodes (used when ColorMode is "User defined").
        % <@Role> Graph
        % <@Type> double
        % <@Size> Nx1
        NodeC_ColorVal    (:,1) double = [];

        % <@Desc> Color values for bus-to-bus edges (used when ColorMode is "User defined").
        % <@Role> Graph
        % <@Type> double
        % <@Size> Nx1
        EdgeB2B_ColorVal  (:,1) double = [];

        % <@Desc> Color values for bus-to-component edges (used when ColorMode is "User defined").
        % <@Role> Graph
        % <@Type> double
        % <@Size> Nx1
        EdgeB2C_ColorVal  (:,1) double = [];

        % <@Desc> Label strings for bus nodes.
        % <@Role> Graph
        % <@Type> string
        % <@Size> Nx1
        NodeLabelB        (:,1) string = [];

        % <@Desc> Label strings for component nodes.
        % <@Role> Graph
        % <@Type> string
        % <@Size> Nx1
        NodeLabelC        (:,1) string = [];

        % <@Desc> Mode for displaying node labels ("none","name","info").
        % <@Role> Graph
        % <@Type> string
        % <@Size> 1x1
        NodeLabelMode     (1,1) string {mustBeMember(NodeLabelMode, ["none", "name", "info"])} = "name"

        % <@Desc> Forward power flow direction values for bus-to-bus edges (positive=forward, negative=reverse, zero=hidden).
        % <@Role> Graph
        % <@Type> double
        % <@Size> Nx1
        EdgeB2B_forward   (:,1) double = [];

        % <@Desc> Forward power flow direction values for bus-to-component edges.
        % <@Role> Graph
        % <@Type> double
        % <@Size> Nx1
        EdgeB2C_forward   (:,1) double = [];

        % <@Desc> Grid spacing for the axes tick marks.
        % <@Role> Graph
        % <@Type> double
        % <@Size> 1x1
        GridWidth         (1,1) double = 0.01;
    end

    % Properties for storing graphics objects
    properties

        % <@Desc> MATLAB Axes object used for rendering the diagram.
        % <@Role> Graph
        % <@Type> matlab.graphics.axis.Axes
        % <@Size> 1x1
        ax
    end
    properties(SetAccess = private)

        % <@Desc> Graphics object handles for the rendered diagram elements.
        % <@Role> Graph
        % <@Type> struct
        % <@Size> 1x1
        plt

        % <@Desc> Flag indicating whether the diagram needs to be fully redrawn.
        % <@Role> Graph
        % <@Type> logical
        % <@Size> 1x1
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
        function obj = DrawerNetDiagram(net, ax, opt)
        % <@Desc>
        % Creates a DrawerNetDiagram instance and renders the power network diagram.
        % <@Role>
        % Constructor
        % <@Abst>
        % Initialize axes, apply options, and draw the network.
        % <@Signatures>
        % [
        %   "obj = DrawerNetDiagram(net)",
        %   "obj = DrawerNetDiagram(net, ax)"
        % ]
        % <@varargin>
        % [
        %   {
        %     "Name": "net",
        %     "Type": "PowerNetwork",
        %     "Description": "Power network to visualize.",
        %     "Required": true,
        %     "Default": "-"
        %   },
        %   {
        %     "Name": "ax",
        %     "Type": "matlab.graphics.axis.Axes",
        %     "Description": "Axes object to draw on.",
        %     "Required": false,
        %     "Default": "new axes in a new figure"
        %   }
        % ]
        % <@varargout>
        % [
        %   {
        %     "Name": "obj",
        %     "Type": "DrawerNetDiagram",
        %     "Description": "Created DrawerNetDiagram instance."
        %   }
        % ]
            arguments
                net (1,1) PowerNetwork
                ax  (1,1) matlab.graphics.axis.Axes = axes('Parent',figure());
                opt.?odeSimulator
            end
            obj.ax = ax;
            
            str_fd = fieldnames(opt);
            for i_fd = 1:numel(str_fd)
                stri = str_fd{i_fd};
                obj.(stri) = opt.(stri);
            end

            obj.set_network(net);
            obj.set_powerflow(net);
        end

        set_powerflow(obj, cv_Vbus, cv_Icomp)
        set_network(obj, net)
    end

    methods(Hidden)
        output_txt = hover_bus(obj, i_bus)
        output_txt = hover_branch(obj, i_branch)
        output_txt = hover_component(obj, i_comp)
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

        function set.NodeLabelMode(obj, mode)
            obj.NodeLabelMode = mode;
            if validate(obj) || ~isfield(obj.plt, 'NodeLabel'); return; end %#ok
            obj.reflect_node_label
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

        function set.GridWidth(obj,val)
            val = abs(val);
            if obj.validate; return; end
            obj.GridWidth = val;
            xticks(obj.ax, 0:val:1) %#ok
            yticks(obj.ax, 0:val:1) %#ok
        end
    end
end


