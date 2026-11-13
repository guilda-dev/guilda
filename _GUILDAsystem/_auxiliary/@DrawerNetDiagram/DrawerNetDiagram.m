classdef DrawerNetDiagram < auxiliary
% 3D diagram of a network: buses, components and branches drawn as solids.
%
% net.plot_diagram creates one. The diagram shows the power flow state of the network:
% the colors of the branches and component connections follow ColorMode, the widths of the
% branches follow BranchWidthMode, and the heights of the buses follow BusHeightMode.
% Changing a property updates the drawing; hovering over an element shows its values. It
% is implemented without the digraph plot.
%
% - `ColorMode`: "Loss", "I", "P", "Q", "none",
%   or "user" (set BusColorData, ComponentColorData, BranchColorData,
%   LinkColorData).
% - `BranchWidthMode`: "G", "B", "Y" (conductance, susceptance, magnitude of the series
%   admittance of the branch), "Ysvd" (largest singular value of the admittance
%   matrix of the branch) or "none".
%
% <@Examples>
% ```matlab
% net = network.IEEE14bus();
% net.initialize();
% G = net.plot_diagram();
% G.ColorMode = "P";
% G.BusHeightMode = "V";
% G.LabelMode = "value";
% ```
%
% See also PowerNetwork.plot_diagram

    properties % Appearance
        ColorLimits (1,2) double = [0,2];                                                                                    % Limits of the color scale (clim of the axes).
        Colormap (:,3) double = turbo;                                                                                    % Colormap of the color values.
        ColorMode (1,1) string {mustBeMember(ColorMode, [...
                                            "none",               ...
                                            "Loss",               ...
                                            "I",        ...
                                            "P",   ...
                                            "Q", ...
                                            "user"])} = "I";                                            % Quantity that colors the branches and component connections (see the class help).
        LabelFontSize (1,1) double = 5;                                                                                    % Font size of the labels.
        LabelFontWeight (1,1) string = "bold";                                                                             % Font weight of the labels.
        BranchWidthScale (1,1) double = 0.15;                                                                               % Scale of the branch width per unit of the BranchWidthMode value.
        BranchWidthOffset (1,1) double = 1;                                                                                 % Branch width added to the scaled value.
        BranchWidthMode (1,1) string {mustBeMember(BranchWidthMode, ["none","G", "B", "Y", "Ysvd"])} = "Ysvd";    % Admittance quantity that sets the branch widths (see the class help).
        MarkerSize (1,1) double = 10;                                                                                     % Size of the bus and component solids.
        BusHeightMode (1,1) string {mustBeMember(BusHeightMode, ["none", "V", "angle", "Vimag", "P", "Q"])} = "none";  % Quantity that sets the height of each bus: "V", "angle", "Vimag", "P", "Q" or "none".
        BusColorData (:,1) double = [];                                                                                 % Color values of the buses, one per bus.
        ComponentColorData (:,1) double = [];                                                                                 % Color values of the components, one per component.
        BranchColorData (:,1) double = [];                                                                               % Color values of the branches, one per branch.
        LinkColorData (:,1) double = [];                                                                               % Color values of the component connections, one per component.
        BusLabel (:,1) string = [];                                                                                     % Labels of the buses, one per bus.
        ComponentLabel (:,1) string = [];                                                                                     % Labels of the components, one per component.
        LabelMode (1,1) string {mustBeMember(LabelMode, ["none", "tag", "value"])} = "tag"                       % Labels shown: "tag" (tags), "value" (values) or "none".
        BranchDirection (:,1) double = [];                                                                                % Arrow direction of each branch: 1 forward, -1 backward, 0 none.
        LinkDirection (:,1) double = [];                                                                                % Arrow direction of each component connection: 1, -1 or 0.
        GridSpacing (1,1) double = 0.01;                                                                                    % Spacing of the grid lines of the axes.
    end
    properties % Graphics
        ax                                                                                                                % Axes of the diagram. <@Type> matlab.graphics.axis.Axes
    end
    properties(SetAccess = private) % Graphics
        sct_plt                                                                                                               % Graphics objects of the diagram, as a struct of handle arrays. <@Type> struct
        l_redraw                                                                                                          % True when the diagram must be drawn again (new axes). <@Type> logical
    end
    properties(Access = private) % Network data
        im_edge                                                                                                           % End-bus indices of each branch (2 x n_branch).
        cm_Ymat                                                                                                           % [pu] Admittance matrix of the network (sparse).
        tab_bus                                                                                                           % Bus type and operation and graph parameters, one row per bus.
        tab_branch                                                                                                        % Branch class and operation, graph and dynamics parameters (with Ysvd), one row per branch.
        tab_component                                                                                                     % Bus index, class and operation and graph parameters, one row per component.
        n_bus                                                                                                             % Number of buses.
        n_branch                                                                                                          % Number of branches.
        n_component                                                                                                       % Number of components.
        sv_bus                                                                                                            % Bus tags.
        sv_branch                                                                                                         % Branch tags.
        sv_component                                                                                                      % Component tags without the bus tag.
        cm_Vbus2Ibranch                                                                                                   % Map from the bus voltages to the currents into the branches at both ends (sparse).
        cm_Vbus2Vbranch                                                                                                   % Map from the bus voltages to the end voltages of the branches (sparse).
    end
    properties(Access = private) % State
        cv_Vbus                                                                                                           % [pu] Bus voltage phasors shown.
        cv_Ibus                                                                                                           % [pu] Bus current injections.
        rv_Pbus                                                                                                           % [pu] Active power injections of the buses.
        rv_Qbus                                                                                                           % [pu] Reactive power injections of the buses.
        cm_Vbranch                                                                                                        % [pu] End voltages of the branches (2 x n_branch).
        cm_Ibranch                                                                                                        % [pu] Currents into the branches at both ends (2 x n_branch).
        rm_Pbranch                                                                                                        % [pu] Active power into the branches at both ends (2 x n_branch).
        rm_Qbranch                                                                                                        % [pu] Reactive power into the branches at both ends (2 x n_branch).
        cv_Vcomp                                                                                                          % [pu] Voltage of the bus of each component.
        cv_Icomp                                                                                                          % [pu] Current injection of each component.
        rv_Pcomp                                                                                                          % [pu] Active power injection of each component.
        rv_Qcomp                                                                                                          % [pu] Reactive power injection of each component.
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
            obj.l_redraw = true; %#ok
        end

        function set.ColorLimits(obj, color_lim)
            obj.ColorLimits  = color_lim;
            clim(obj.ax, obj.ColorLimits);                                     %#ok
            obj.rehash();
        end

        function set.Colormap(obj, cmap)
            obj.Colormap  = cmap;
            colormap(obj.ax, obj.Colormap);                                 %#ok
            obj.rehash();
        end

        function set.ColorMode(obj, edge_color_mode)
            obj.ColorMode = edge_color_mode;
            obj.reflect_color_mode();
        end

        % Setters for properties for node label appearance
        function set.LabelFontSize(obj, font_size)
            obj.LabelFontSize = font_size;
            if validate(obj); return; end

            h_label = obj.sct_plt.NodeLabel;                                    %#ok
            for i = 1:numel(h_label)
                if isgraphics(h_label(i))
                    h_label(i).FontSize = font_size;
                end
            end
            h_label = obj.sct_plt.CompLabel;                                    %#ok
            for i = 1:numel(h_label)
                if isgraphics(h_label(i))
                    h_label(i).FontSize = font_size;
                end
            end
        end
        function set.LabelFontWeight(obj, font_weight)
            obj.LabelFontWeight = font_weight;
            if validate(obj); return; end

            h_label = obj.sct_plt.NodeLabel;                                    %#ok
            for i = 1:numel(h_label)
                if isgraphics(h_label(i))
                    h_label(i).FontWeight = font_weight;
                end
            end
        end

        % Setters for properties that require re-plotting
        function set.BranchWidthOffset(obj, edge_width_offset)
            obj.BranchWidthOffset = edge_width_offset;
            if ~validate(obj)
                obj.draw_graph_network;
                obj.reflect_color_mode;
                obj.reflect_node_label;
            end
        end
        function set.BranchWidthScale(obj, branch_width_scale)
            obj.BranchWidthScale = branch_width_scale;
            if ~validate(obj)
                obj.draw_graph_network;
                obj.reflect_color_mode;
                obj.reflect_node_label;
            end
        end
        function set.BranchWidthMode(obj, edge_width_mode)
            obj.BranchWidthMode = edge_width_mode;
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
        function set.BusHeightMode(obj, mode)
            obj.BusHeightMode = mode;
            if ~validate(obj)
                obj.draw_graph_network;
                obj.reflect_color_mode;
                obj.reflect_node_label;
            end
        end

        % Setters for color values
        function set.BusColorData(obj, rv_value)
            obj.BusColorData = rv_value;
            if validate(obj) || ~isfield(obj.sct_plt, 'NodeMain'); return; end  %#ok
            obj.apply_color_values(obj.sct_plt.NodeMain, rv_value);             %#ok
        end

        function set.ComponentColorData(obj, rv_value)
            obj.ComponentColorData = rv_value;
            if validate(obj) || ~isfield(obj.sct_plt, 'CompMain'); return; end  %#ok
            obj.apply_color_values(obj.sct_plt.CompMain, rv_value);             %#ok
        end

        function set.BranchColorData(obj, rv_value)
            obj.BranchColorData = rv_value;
            if validate(obj) || ~isfield(obj.sct_plt, 'EdgeMain') || ~isfield(obj.sct_plt, 'EdgeArrow'); return; end %#ok
            obj.apply_color_values(obj.sct_plt.EdgeMain,  rv_value);            %#ok
            obj.apply_color_values(obj.sct_plt.EdgeArrow, rv_value);            %#ok
        end

        function set.LinkColorData(obj, rv_value)
            obj.LinkColorData = rv_value;
            if validate(obj) || ~isfield(obj.sct_plt, 'CompEdge'); return; end  %#ok
            obj.apply_color_values(obj.sct_plt.CompEdge, rv_value);             %#ok
            obj.apply_color_values(obj.sct_plt.CompArrow,rv_value);             %#ok
        end

        % Setters for node labels
        function set.BusLabel(obj, label)
            obj.BusLabel = string(label);
            for i =1:numel(obj.sct_plt.NodeLabel)                               %#ok
                if isgraphics(obj.sct_plt.NodeLabel(i))                         %#ok
                    obj.sct_plt.NodeLabel(i).String = obj.BusLabel(i);        %#ok
                end
            end
        end

        function set.ComponentLabel(obj, label)
            obj.ComponentLabel = string(label);
            for i =1:numel(obj.sct_plt.CompLabel)                               %#ok
                if isgraphics(obj.sct_plt.CompLabel(i))                         %#ok
                    obj.sct_plt.CompLabel(i).String = obj.ComponentLabel(i);        %#ok
                end
            end
        end

        function set.LabelMode(obj, mode)
            obj.LabelMode = mode;
            if validate(obj) || ~isfield(obj.sct_plt, 'NodeLabel'); return; end %#ok
            obj.reflect_node_label
        end

        % Setters for edge direction (for directed edge shapes)
        function set.BranchDirection(obj, forward)
            obj.BranchDirection = forward;
            if validate(obj) || ~isfield(obj.sct_plt, 'EdgeArrow'); return; end %#ok
            for i = 1:numel(obj.sct_plt.EdgeArrow)                              %#ok
                h_arrowi = obj.sct_plt.EdgeArrow(i);                            %#ok
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

        function set.LinkDirection(obj, forward)
            obj.LinkDirection = forward;
            if validate(obj) || ~isfield(obj.sct_plt, 'CompEdge'); return; end  %#ok
            for i = 1:numel(obj.sct_plt.CompArrow)                              %#ok
                h_edgei = obj.sct_plt.CompArrow(i);                             %#ok
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

        function set.GridSpacing(obj,val)
            val = abs(val);
            if obj.validate; return; end
            obj.GridSpacing = val;
            xticks(obj.ax, 0:val:1) %#ok
            yticks(obj.ax, 0:val:1) %#ok
        end
    end
end
