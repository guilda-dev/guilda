classdef DrawerNetDiagram < auxiliary
% 3D diagram of a network: buses, components and branches drawn as solids.
%
% The diagram is built from data only: a snapshot of the network (struct(net, false)) and
% the state to show. It never reads or changes a network. net.plot_diagram draws the
% equilibrium of the network and ResultPF.plot_diagram the power flow solution. The colors
% of the branches and of the links (the lines between a component and its bus) follow
% ColorMode, the widths of the branches follow BranchWidthMode and the heights of the buses
% follow BusHeightMode. Changing a property updates the drawing; hovering over an element
% shows its values. It is implemented without the digraph plot.
%
% The positions are Xaxis and Yaxis of the graph parameters of the buses and components in
% the snapshot. When a bus has none (NaN), the positions of all buses come from the "force"
% layout of MATLAB; a component without a position is placed around its bus. These
% positions stay in the drawer: nothing is written to the network.
%
% The state is a struct with the fields:
%
% - `rv_t` (1 x n_t) [s]: times of the samples.
% - `cm_Vbus` (n_bus x n_t) [pu]: bus voltage phasors, in the a_Bus order of the snapshot.
% - `cm_Icomp` (n_comp x n_t) [pu]: current phasors injected by the components into their
%   buses, bus by bus in the a_Bus order and in the a_Component order of each bus.
%
% set_time(t) shows the sample nearest to t. The current injection of a bus is the sum of
% the currents of its components, and the branch currents come from the bus voltages and
% the admittance matrix of each branch (the field cm_Y of the branch in the snapshot).
%
% - `ColorMode`: "I" (current), "P" (active power), "Q" (reactive power), "Loss", "none",
%   or "user" (the values set in BusColorData, ComponentColorData, BranchColorData and
%   LinkColorData are kept).
% - `BranchWidthMode`: "G", "B", "Y" (conductance, susceptance, magnitude of the series
%   admittance of the branch), "Ysvd" (largest singular value of the admittance matrix of
%   the branch) or "none".
% - `BusHeightMode`: "V" (|V|), "angle" (angle of V), "Vimag" (imaginary part of V), "P",
%   "Q" (power injections) or "none".
% - `LabelMode`: "tag" (the tags), "value" (the tags and the values) or "none".
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
% See also PowerNetwork.plot_diagram, ResultPF.plot_diagram

    properties % Appearance
        ColorLimits (1,2) double = [0,2]                                                                % Limits of the color scale (clim of the axes).
        Colormap (:,3) double = turbo                                                                   % Colormap of the color values.
        ColorMode (1,1) string {mustBeMember(ColorMode, ["none","Loss","I","P","Q","user"])} = "I"     % Quantity that colors the branches and links (see the class help).
        LabelFontSize (1,1) double = 5                                                                  % Font size of the labels.
        LabelFontWeight (1,1) string = "bold"                                                           % Font weight of the bus labels.
        BranchWidthScale (1,1) double = 0.15                                                            % Scale of the branch width per unit of the BranchWidthMode value.
        BranchWidthOffset (1,1) double = 1                                                              % Branch width added to the scaled value.
        BranchWidthMode (1,1) string {mustBeMember(BranchWidthMode, ["none","G","B","Y","Ysvd"])} = "Ysvd" % Admittance quantity that sets the branch widths (see the class help).
        MarkerSize (1,1) double = 10                                                                    % Size of the bus and component solids.
        BusHeightMode (1,1) string {mustBeMember(BusHeightMode, ["none","V","angle","Vimag","P","Q"])} = "none" % Quantity that sets the height of each bus (see the class help).
        BusColorData (:,1) double = []                                                                  % Color values of the buses, one per bus.
        ComponentColorData (:,1) double = []                                                            % Color values of the components, one per component.
        BranchColorData (:,1) double = []                                                               % Color values of the branches, one per branch.
        LinkColorData (:,1) double = []                                                                 % Color values of the links (component to bus), one per component.
        BusLabel (:,1) string = []                                                                      % Labels of the buses, one per bus.
        ComponentLabel (:,1) string = []                                                                % Labels of the components, one per component.
        LabelMode (1,1) string {mustBeMember(LabelMode, ["none","tag","value"])} = "tag"               % Labels shown: "tag", "value" or "none".
        BranchDirection (:,1) double = []                                                               % Arrow direction of each branch: 1 forward, -1 backward, 0 none.
        LinkDirection (:,1) double = []                                                                 % Arrow direction of each link: 1, -1 or 0.
        GridSpacing (1,1) double = 0.01                                                                 % Spacing of the grid lines of the axes.
    end
    properties (SetAccess = private) % Graphics
        ax                                                                                              % Axes of the diagram. <@Type> matlab.graphics.axis.Axes
    end
    properties (SetAccess = private) % State
        sct_state                                                                                       % State shown: rv_t, cm_Vbus, cm_Icomp (see the class help). <@Type> struct
        i_time = 1                                                                                      % Index of the sample shown.
    end
    properties (Access = private) % Graphics
        sct_plt                                                                                         % Graphics objects of the diagram, as a struct of handle arrays.
        l_redraw = true                                                                                 % True when the diagram must be drawn again (new axes).
    end
    properties (Access = private) % Network data
        im_edge                                                                                         % End-bus indices of each branch (2 x n_branch).
        tab_bus                                                                                         % Bus type and operation and graph parameters, one row per bus.
        tab_branch                                                                                      % Branch class and operation, graph and dynamics parameters (with Ysvd), one row per branch.
        tab_component                                                                                   % Bus index, class and operation and graph parameters, one row per component.
        n_bus                                                                                           % Number of buses.
        n_branch                                                                                        % Number of branches.
        n_component                                                                                     % Number of components.
        sv_bus                                                                                          % Bus tags.
        sv_branch                                                                                       % Branch tags.
        sv_component                                                                                    % Component tags without the bus tag.
        cm_Vbus2Ibranch                                                                                 % Map from the bus voltages to the currents into the branches at both ends (sparse).
        cm_Vbus2Vbranch                                                                                 % Map from the bus voltages to the end voltages of the branches (sparse).
    end
    properties (Access = private) % State of the sample shown
        cv_Vbus                                                                                         % [pu] Bus voltage phasors shown.
        cv_Ibus                                                                                         % [pu] Bus current injections.
        rv_Pbus                                                                                         % [pu] Active power injections of the buses.
        rv_Qbus                                                                                         % [pu] Reactive power injections of the buses.
        cm_Vbranch                                                                                      % [pu] End voltages of the branches (2 x n_branch).
        cm_Ibranch                                                                                      % [pu] Currents into the branches at both ends (2 x n_branch).
        rm_Pbranch                                                                                      % [pu] Active power into the branches at both ends (2 x n_branch).
        rm_Qbranch                                                                                      % [pu] Reactive power into the branches at both ends (2 x n_branch).
        cv_Vcomp                                                                                        % [pu] Voltage of the bus of each component.
        cv_Icomp                                                                                        % [pu] Current injection of each component.
        rv_Pcomp                                                                                        % [pu] Active power injection of each component.
        rv_Qcomp                                                                                        % [pu] Reactive power injection of each component.
    end

    methods
        function obj = DrawerNetDiagram(sct_network, sct_state, opt)
        % Create the diagram from a network snapshot and a state, and draw its first sample.
            arguments (Input)
                sct_network (1,1) struct  % Snapshot of the network: struct(net, false).
                sct_state   (1,1) struct  % State to show: rv_t, cm_Vbus, cm_Icomp (see the class help).
                opt.?DrawerNetDiagram     % Name-Value options; each field is copied to the property of the same name.
                opt.Parent = []           % Axes to draw in; [] for new axes in a new figure. <@Type> matlab.graphics.axis.Axes
            end
            arguments (Output)
                obj % The diagram.
            end
            obj.set_network(sct_network);
            obj.sct_state = check_state(sct_state, obj.n_bus, obj.n_component);

            if isempty(opt.Parent)
                obj.ax = axes(figure());
            elseif isa(opt.Parent, "matlab.graphics.axis.Axes")
                obj.ax = opt.Parent;
            else
                error(msg("GUILDA:DrawerNetDiagram:ParentNotAxes", class(opt.Parent)));
            end
            for s_field = setdiff(string(fieldnames(opt))', "Parent")
                obj.(s_field) = opt.(s_field);
            end

            obj.set_time(obj.sct_state.rv_t(1));
        end

        set_time(obj, t)
    end

    methods (Hidden)
        output_txt = hover_bus(obj, i_bus)
        output_txt = hover_branch(obj, i_branch)
        output_txt = hover_component(obj, i_comp)
    end

    methods (Access = private)
        set_network(obj, sct_network)
        set_powerflow(obj, cv_Vbus, cv_Icomp)
        rehash(obj)
        draw_graph_network(obj)
        reflect_color_mode(obj)
        reflect_node_label(obj)
        reflect_arrow_forward(obj)
        apply_color_values(obj, h_list, rv_value)
        flag = validate(obj)
    end

    methods
        function set.ax(obj, ax)
            arguments (Input)
                obj
                ax (1,1) matlab.graphics.axis.Axes % Axes of the diagram.
            end
            obj.ax = ax;
            obj.l_redraw = true; %#ok<MCSUP>
        end

        function set.ColorLimits(obj, color_lim)
            obj.ColorLimits = color_lim;
            if isgraphics(obj.ax)                                           %#ok<MCSUP>
                clim(obj.ax, obj.ColorLimits);                              %#ok<MCSUP>
            end
            obj.rehash();
        end

        function set.Colormap(obj, cmap)
            obj.Colormap = cmap;
            if isgraphics(obj.ax)                                           %#ok<MCSUP>
                colormap(obj.ax, obj.Colormap);                             %#ok<MCSUP>
            end
            obj.rehash();
        end

        function set.ColorMode(obj, edge_color_mode)
            obj.ColorMode = edge_color_mode;
            if validate(obj); return; end
            obj.reflect_color_mode();
        end

        % Setters of the label appearance
        function set.LabelFontSize(obj, font_size)
            obj.LabelFontSize = font_size;
            if validate(obj); return; end
            h_label = [obj.sct_plt.NodeLabel(:); obj.sct_plt.CompLabel(:)];       %#ok<MCSUP>
            for i = 1:numel(h_label)
                if isgraphics(h_label(i))
                    h_label(i).FontSize = font_size;
                end
            end
        end
        function set.LabelFontWeight(obj, font_weight)
            obj.LabelFontWeight = font_weight;
            if validate(obj); return; end
            h_label = obj.sct_plt.NodeLabel;                                %#ok<MCSUP>
            for i = 1:numel(h_label)
                if isgraphics(h_label(i))
                    h_label(i).FontWeight = font_weight;
                end
            end
        end

        % Setters of the properties that need the diagram drawn again
        function set.BranchWidthOffset(obj, val)
            obj.BranchWidthOffset = val;
            redraw(obj);
        end
        function set.BranchWidthScale(obj, val)
            obj.BranchWidthScale = val;
            redraw(obj);
        end
        function set.BranchWidthMode(obj, val)
            obj.BranchWidthMode = val;
            redraw(obj);
        end
        function set.MarkerSize(obj, val)
            obj.MarkerSize = val;
            redraw(obj);
        end
        function set.BusHeightMode(obj, val)
            obj.BusHeightMode = val;
            redraw(obj);
        end

        % Setters of the color values
        function set.BusColorData(obj, rv_value)
            obj.BusColorData = rv_value;
            if validate(obj); return; end
            obj.apply_color_values(obj.sct_plt.NodeMain, rv_value);         %#ok<MCSUP>
        end
        function set.ComponentColorData(obj, rv_value)
            obj.ComponentColorData = rv_value;
            if validate(obj); return; end
            obj.apply_color_values(obj.sct_plt.CompMain, rv_value);         %#ok<MCSUP>
        end
        function set.BranchColorData(obj, rv_value)
            obj.BranchColorData = rv_value;
            if validate(obj); return; end
            obj.apply_color_values(obj.sct_plt.EdgeMain,  rv_value);        %#ok<MCSUP>
            obj.apply_color_values(obj.sct_plt.EdgeArrow, rv_value);        %#ok<MCSUP>
        end
        function set.LinkColorData(obj, rv_value)
            obj.LinkColorData = rv_value;
            if validate(obj); return; end
            obj.apply_color_values(obj.sct_plt.CompEdge,  rv_value);        %#ok<MCSUP>
            obj.apply_color_values(obj.sct_plt.CompArrow, rv_value);        %#ok<MCSUP>
        end

        % Setters of the labels
        function set.BusLabel(obj, label)
            obj.BusLabel = string(label);
            if validate(obj); return; end
            set_label_strings(obj.sct_plt.NodeLabel, obj.BusLabel);         %#ok<MCSUP>
        end
        function set.ComponentLabel(obj, label)
            obj.ComponentLabel = string(label);
            if validate(obj); return; end
            set_label_strings(obj.sct_plt.CompLabel, obj.ComponentLabel);   %#ok<MCSUP>
        end
        function set.LabelMode(obj, mode)
            obj.LabelMode = mode;
            if validate(obj); return; end
            obj.reflect_node_label();
        end

        % Setters of the arrow directions
        function set.BranchDirection(obj, forward)
            obj.BranchDirection = forward;
            if validate(obj); return; end
            set_arrow_direction(obj.sct_plt.EdgeArrow, forward);            %#ok<MCSUP>
        end
        function set.LinkDirection(obj, forward)
            obj.LinkDirection = forward;
            if validate(obj); return; end
            set_arrow_direction(obj.sct_plt.CompArrow, forward);            %#ok<MCSUP>
        end

        function set.GridSpacing(obj, val)
            val = abs(val);
            obj.GridSpacing = val;
            if validate(obj); return; end
            xticks(obj.ax, 0:val:1)                                         %#ok<MCSUP>
            yticks(obj.ax, 0:val:1)                                         %#ok<MCSUP>
        end
    end
end


function redraw(obj)
% Draw the diagram again after a property that changes its shapes was set
    if validate(obj); return; end
    obj.draw_graph_network();
    obj.reflect_color_mode();
    obj.reflect_node_label();
end


function set_label_strings(h_label, sv_label)
% Put the label texts into the text objects
    for i = 1:min(numel(h_label), numel(sv_label))
        if isgraphics(h_label(i))
            h_label(i).String = sv_label(i);
        end
    end
end


function set_arrow_direction(h_arrow, rv_forward)
% Show the arrow head at the "To" end (1), at the "From" end (-1) or none (0)
    for i = 1:min(numel(h_arrow), numel(rv_forward))
        if ~isgraphics(h_arrow(i))
            continue
        end
        ud = h_arrow(i).UserData;
        set(ud.To,   'Visible', sign(rv_forward(i)) ==  1);
        set(ud.From, 'Visible', sign(rv_forward(i)) == -1);
    end
end


function sct = check_state(sct, n_bus, n_comp)
% The fields rv_t, cm_Vbus and cm_Icomp of the state, with their sizes
    for s_field = ["rv_t", "cm_Vbus", "cm_Icomp"]
        if ~isfield(sct, s_field)
            error(msg("GUILDA:DrawerNetDiagram:MissingStateField", s_field));
        end
    end
    rv_t = sct.rv_t;
    if ~(isnumeric(rv_t) && isreal(rv_t) && isvector(rv_t) && all(isfinite(rv_t)))
        error(msg("GUILDA:DrawerNetDiagram:StateSize", "rv_t", "a finite real 1xn_t vector", size_text(rv_t)));
    end
    n_t = numel(rv_t);
    if isempty(sct.cm_Icomp) && n_comp == 0
        sct.cm_Icomp = zeros(0, n_t);
    end
    if ~isnumeric(sct.cm_Vbus) || ~isequal(size(sct.cm_Vbus), [n_bus, n_t])
        error(msg("GUILDA:DrawerNetDiagram:StateSize", "cm_Vbus", n_bus + "x" + n_t, size_text(sct.cm_Vbus)));
    end
    if ~isnumeric(sct.cm_Icomp) || ~isequal(size(sct.cm_Icomp), [n_comp, n_t])
        error(msg("GUILDA:DrawerNetDiagram:StateSize", "cm_Icomp", n_comp + "x" + n_t, size_text(sct.cm_Icomp)));
    end
    sct = struct("rv_t", reshape(double(rv_t), 1, []), ...
                 "cm_Vbus", double(sct.cm_Vbus), "cm_Icomp", double(sct.cm_Icomp));
end


function s = size_text(x)
% Size of x as text, e.g. "3x1"
    s = join(string(size(x)), "x");
end
