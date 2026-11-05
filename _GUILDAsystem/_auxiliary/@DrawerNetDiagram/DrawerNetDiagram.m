classdef DrawerNetDiagram < auxiliary
% 3D diagram of a network: buses, components and branches drawn as solids.
%
% net.draw_diagram creates one. The diagram shows the power flow state of the network:
% the colors of the branches and component connections follow ColorMode, the widths of the
% branches follow EdgeWidthMode, and the heights of the buses follow NodeHeightMode.
% Changing a property updates the drawing; hovering over an element shows its values. It
% is implemented without the digraph plot.
%
% - `ColorMode`: "Loss", "I (current)", "P (active power)", "Q (reactive power)", "none",
%   or "User defined" (set NodeB_ColorVal, NodeC_ColorVal, EdgeB2B_ColorVal,
%   EdgeB2C_ColorVal).
% - `EdgeWidthMode`: "G", "B", "Y" (conductance, susceptance, magnitude of the series
%   admittance of the branch), "SvdMaxYmat" (largest singular value of the admittance
%   matrix of the branch) or "none".
%
% <@Examples>
% ```matlab
% net = network.IEEE14bus();
% net.initialize();
% G = net.draw_diagram();
% G.ColorMode = "P (active power)";
% G.NodeHeightMode = "Vmag";
% G.NodeLabelMode = "info";
% ```
%
% See also PowerNetwork.draw_diagram

    properties % Appearance
        ColorLim (1,2) double = [0,2];  % Limits of the color scale (clim of the axes).
        ColorMap (:,3) double = turbo;  % Colormap of the color values.
        ColorMode (1,1) string {mustBeMember(ColorMode, [...
                                            "none",               ...
                                            "Loss",               ...
                                            "I (current)",        ...
                                            "P (active power)",   ...
                                            "Q (reactive power)", ...
                                            "User defined"])} = "I (current)";  % Quantity that colors the branches and component connections (see the class help).
        NodeFontSize (1,1) double = 5;  % Font size of the labels.
        NodeFontWeight (1,1) string = "bold";  % Font weight of the labels.
        EdgeWidthSclae (1,1) double = 0.15;  % Scale of the branch width per unit of the EdgeWidthMode value.
        EdgeWidthOffset (1,1) double = 1;  % Branch width added to the scaled value.
        EdgeWidthMode (1,1) string {mustBeMember(EdgeWidthMode, ["none","G", "B", "Y", "SvdMaxYmat"])} = "SvdMaxYmat";  % Admittance quantity that sets the branch widths (see the class help).
        MarkerSize (1,1) double = 10;  % Size of the bus and component solids.
        NodeHeightMode (1,1) string {mustBeMember(NodeHeightMode, ["none", "Vmag", "Varg", "Vsin", "P", "Q"])} = "none";  % Quantity that sets the height of each bus: "Vmag", "Varg", "Vsin", "P", "Q" or "none".
        NodeB_ColorVal (:,1) double = [];  % Color values of the buses, one per bus.
        NodeC_ColorVal (:,1) double = [];  % Color values of the components, one per component.
        EdgeB2B_ColorVal (:,1) double = [];  % Color values of the branches, one per branch.
        EdgeB2C_ColorVal (:,1) double = [];  % Color values of the component connections, one per component.
        NodeLabelB (:,1) string = [];  % Labels of the buses, one per bus.
        NodeLabelC (:,1) string = [];  % Labels of the components, one per component.
        NodeLabelMode (1,1) string {mustBeMember(NodeLabelMode, ["none", "name", "info"])} = "name"  % Labels shown: "name" (tags), "info" (values) or "none".
        EdgeB2B_forward (:,1) double = [];  % Arrow direction of each branch: 1 forward, -1 backward, 0 none.
        EdgeB2C_forward (:,1) double = [];  % Arrow direction of each component connection: 1, -1 or 0.
        GridWidth (1,1) double = 0.01;  % Spacing of the grid lines of the axes.
    end
    properties % Graphics
        ax  % Axes of the diagram. <@Type> matlab.graphics.axis.Axes
    end
    properties(SetAccess = private) % Graphics
        plt  % Graphics objects of the diagram, as a struct of handle arrays. <@Type> struct
        flag_new  % True when the diagram must be drawn again (new axes). <@Type> logical
    end
    properties(Access = private) % Network data
        im_edge  % End-bus indices of each branch (2 x n_branch).
        cm_Ymat  % [pu] Admittance matrix of the network (sparse).
        tab_bus  % Bus type and operation and graph parameters, one row per bus.
        tab_branch  % Branch class and operation, graph and dynamics parameters (with SvdMaxYmat), one row per branch.
        tab_component  % Bus index, class and operation and graph parameters, one row per component.
        n_bus  % Number of buses.
        n_branch  % Number of branches.
        n_component  % Number of components.
        sv_bus  % Bus tags.
        sv_branch  % Branch tags.
        sv_component  % Component tags without the bus tag.
        cm_Vbus2Ibranch  % Map from the bus voltages to the currents into the branches at both ends (sparse).
        cm_Vbus2Vbranch  % Map from the bus voltages to the end voltages of the branches (sparse).
    end
    properties(Access = private) % State
        cv_Vbus  % [pu] Bus voltage phasors shown.
        cv_Ibus  % [pu] Bus current injections.
        rv_Pbus  % [pu] Active power injections of the buses.
        rv_Qbus  % [pu] Reactive power injections of the buses.
        cm_Vbranch  % [pu] End voltages of the branches (2 x n_branch).
        cm_Ibranch  % [pu] Currents into the branches at both ends (2 x n_branch).
        rm_Pbranch  % [pu] Active power into the branches at both ends (2 x n_branch).
        rm_Qbranch  % [pu] Reactive power into the branches at both ends (2 x n_branch).
        cv_Vcomp  % [pu] Voltage of the bus of each component.
        cv_Icomp  % [pu] Current injection of each component.
        rv_Pcomp  % [pu] Active power injection of each component.
        rv_Qcomp  % [pu] Reactive power injection of each component.
    end

    methods
        function obj = DrawerNetDiagram(net, ax, opt)
        % Create the diagram of a network and draw its equilibrium.
            arguments (Input)
                net (1,1) PowerNetwork % Network to draw.
                ax  (1,1) matlab.graphics.axis.Axes = axes('Parent',figure()); % Axes to draw in.
                opt.?SolverODE % Name-Value options; each field is copied to the property of the same name.
            end
            arguments (Output)
                obj % The diagram.
            end
            obj.ax = ax;
            
            sv_fd = fieldnames(opt);
            for i_fd = 1:numel(sv_fd)
                stri = sv_fd{i_fd};
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
        flag = validate(obj)
    end

    methods
        function set.ax(obj,ax)
            arguments (Input)
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
            obj.apply_color_values(obj.plt.CompArrow,rv_value);             %#ok
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
