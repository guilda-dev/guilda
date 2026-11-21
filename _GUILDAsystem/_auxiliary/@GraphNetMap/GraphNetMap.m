classdef GraphNetMap < GraphBase
% Light 2D map of a power flow: the buses colored by the voltage and the branch flows as arrows.
%
% The map is one MATLAB graph plot (GraphPlot). The buses are its nodes, colored by |V|
% [pu] or the angle of V [deg] with a colorbar, and the branches are its edges: arrows in
% the direction of the active or reactive power flow, from the end where the power enters
% the branch, whose width grows with the larger |P| or |Q| of the two ends (mapped
% linearly from the smallest to the largest of all branches onto BranchWidthRange, in
% pt), or plain lines (the middle of the range).
% ResultPF.plot_network returns it. It is built from data only and never reads or changes
% a network.
%
% The data is a struct with the fields:
%
% - `sv_bus` (n_bus x 1): bus tags.
% - `rm_xy` (n_bus x 2): positions (x, y) of the bus centers. When a row is NaN, the
%   buses of the earlier data of the map keep their drawn positions (by tag) and the
%   others are placed by tools.layout_place_buses near their neighbours; the buses with a
%   position never move (every bus takes the "force" layout only when none has one).
% - `rv_length` (n_bus x 1, optional): bar length of each bus for the placement (positive
%   for a horizontal bar, negative for a vertical one, NaN for a point).
% - `c_path` (n_branch x 1 cell, optional): bend points (m x 2) of each branch for the
%   placement.
% - `cv_V` (n_bus x 1) [pu]: bus voltage phasors.
% - `sv_branch` (n_branch x 1): branch tags.
% - `im_end` (n_branch x 2): rows in sv_bus of the "from" and "to" buses of each branch.
% - `rm_P`, `rm_Q` (n_branch x 2) [pu]: active and reactive power into each branch at its
%   "from" and "to" ends.
% - `s_color`: "V" (|V|) or "angle" (angle of V) for the node colors.
% - `s_arrow`: "P", "Q" (arrows along that flow) or "none" (plain lines).
%
% A power flow has one sample: set_time shows it and changes nothing; animate and
% export_video stop with GUILDA:GraphBase:OneSample.
%
% The elements of tab_element are the buses (kind "bus") and the branches ("branch").
% Their appearance is in vectors in the order of the data, which set_style writes by tag:
%
% - buses: BusColor (Color; RGB, NaN rows: the color of the voltage on the colormap),
%   BusLabel (Label), BusMarkerSize (MarkerSize) and BusMarker (Marker);
% - branches: BranchColor (Color; NaN rows: the edge color of the graph plot),
%   BranchLineWidth (LineWidth in pt; NaN rows: the width of the flow in BranchWidthRange)
%   and BranchLineStyle (LineStyle).
%
% They change the properties of the graph plot only; the map is never drawn again.
% set_position moves buses in the drawing only (never in the model); the branches follow
% their ends. get_layout returns the drawn bus positions, and
% net.set_layout(G.get_layout()) saves them. A click on the graph plot is matched to the nearest bus marker, else to the
% nearest branch line (in pixels), and raises ElementClicked; a selected bus is marked by
% a ring and a selected branch by a wide line in SelectionColor. The callback of the graph
% plot holds the map by a weak reference, so a saved figure does not save the map.
%
% <@Examples>
% ```matlab
% res = network.IEEE14bus().calculate_powerflow();
% G = res.plot_network(Color="angle", Arrow="Q");
% G.set_style("B001", Color="r", MarkerSize=12);
% G.BranchWidthRange = [0.5 6];
% G.BranchLineStyle(3) = ":";
% G.set_position("B001", [0, 0]);
% G.ColorbarLabel = "voltage angle [deg]";
% ```
%
% See also GraphBase, ResultPF.plot_network, GraphNetDiagram

    properties % Appearance
        ColorbarLabel (1,1) string = ""                                % Label of the colorbar; "": "|V| [pu]" or "\angleV [deg]" (s_color of the data).
    end
    properties (SetObservable) % Appearance (controls of show_controls)
        BranchWidthRange (1,2) double = [1 4]                          % [pt] Range [min max] of the widths of the flows.
    end
    properties % Appearance of each bus (set_style Color, Label, MarkerSize, Marker)
        BusColor (:,3) double = zeros(0, 3)                            % RGB color of each bus; NaN rows: the color of its voltage.
        BusLabel (:,1) string = strings(0, 1)                          % Label of each bus.
        BusMarkerSize (:,1) double = zeros(0, 1)                       % [pt] Marker size of each bus (default 6).
        BusMarker (:,1) string = strings(0, 1)                         % Marker of each bus.
    end
    properties % Appearance of each branch (set_style Color, LineWidth, LineStyle)
        BranchColor (:,3) double = zeros(0, 3)                         % RGB color of each branch; NaN rows: the edge color of the graph plot.
        BranchLineWidth (:,1) double = zeros(0, 1)                     % [pt] Width of each branch; NaN rows: the width of its flow in BranchWidthRange.
        BranchLineStyle (:,1) string = strings(0, 1)                   % Line style of each branch.
    end
    properties (Access = private) % Data
        sct_data                                                       % Data of the map (see the class help), with rm_xy the drawn positions, rm_flow the flow of the arrows and rv_flowMag the size of each flow. <@Type> struct
    end

    methods
        function obj = GraphNetMap(sct_data, opt)
        % Create the map from the data of a power flow and draw it.
            arguments (Input)
                sct_data (1,1) struct  % Data of the map (see the class help).
                opt.?GraphNetMap       % Name-Value options; each field is copied to the property of the same name.
                opt.Parent = []        % Container (figure, uifigure, uipanel, uitab, uigridlayout) or axes/uiaxes to draw in; [] for a new figure.
            end
            arguments (Output)
                obj  % The map.
            end
            obj.load_data(sct_data);
            obj.build(opt);
        end

        set_position(obj, sr_tag, rm_xy)
        sct_layout = get_layout(obj)

        % Setters of the appearance vectors: change the graph plot for the changed elements
        function set.BusColor(obj, rm_color)
            iv = changed_rows(obj.BusColor, rm_color);
            obj.BusColor = rm_color;
            restyle(obj, "bus", iv);
        end
        function set.BusLabel(obj, sv_label)
            iv = changed_rows(obj.BusLabel, sv_label);
            obj.BusLabel = sv_label;
            restyle(obj, "bus", iv);
        end
        function set.BusMarkerSize(obj, rv_size)
            iv = changed_rows(obj.BusMarkerSize, rv_size);
            obj.BusMarkerSize = rv_size;
            restyle(obj, "bus", iv);
        end
        function set.BusMarker(obj, sv_marker)
            iv = changed_rows(obj.BusMarker, sv_marker);
            obj.BusMarker = sv_marker;
            restyle(obj, "bus", iv);
        end
        function set.BranchColor(obj, rm_color)
            iv = changed_rows(obj.BranchColor, rm_color);
            obj.BranchColor = rm_color;
            restyle(obj, "branch", iv);
        end
        function set.BranchLineWidth(obj, rv_width)
            iv = changed_rows(obj.BranchLineWidth, rv_width);
            obj.BranchLineWidth = rv_width;
            restyle(obj, "branch", iv);
        end
        function set.BranchLineStyle(obj, sv_style)
            iv = changed_rows(obj.BranchLineStyle, sv_style);
            obj.BranchLineStyle = sv_style;
            restyle(obj, "branch", iv);
        end

        % Setter of the range of the flow widths: the widths of the branches
        function set.BranchWidthRange(obj, rv_range)
            if ~(all(isfinite(rv_range)) && all(rv_range > 0) && rv_range(1) <= rv_range(2))
                error(msg("GUILDA:GraphNetMap:RangeValue", "BranchWidthRange", mat2str(rv_range)));
            end
            obj.BranchWidthRange = rv_range;
            restyle(obj, "branch", (1:numel(obj.BranchLineWidth))');           %#ok<MCSUP>
        end

        % Setter of the colorbar label: change the text only
        function set.ColorbarLabel(obj, s_label)
            obj.ColorbarLabel = s_label;
            if has_scene(obj)
                obj.sct_plt.Colorbar.Label.String = obj.colorbar_text();    %#ok<MCSUP>
            end
        end
    end

    methods (Access = protected)
        load_data(obj, sct_data)
        create_scene(obj)
        update_scene(obj, k)
        apply_style(obj, iv_element)
        tab = element_table(obj)
        sct_map = style_properties(obj)
        apply_selection(obj)
        sct_ctl = control_list(obj)
    end

    methods (Access = private)
        click_at(obj, rv_point)

        function s = colorbar_text(obj)
        % Label of the colorbar: ColorbarLabel, or the quantity of the node colors.
            arguments (Input)
                obj
            end
            arguments (Output)
                s (1,1) string  % Text of the label.
            end
            s = obj.ColorbarLabel;
            if s == ""
                s = "|V| [pu]";
                if obj.sct_data.s_color == "angle"
                    s = "\angleV [deg]";
                end
            end
        end
    end
end


function l = has_scene(obj)
% True when the graph plot of the map exists.
    arguments (Input)
        obj  % The map.
    end
    arguments (Output)
        l (1,1) logical  % The scene exists.
    end
    l = ~isempty(obj.sct_plt) && ~isempty(obj.ax) && all(isgraphics(obj.ax)) && isgraphics(obj.sct_plt.Graph);
end


function iv = changed_rows(v_old, v_new)
% Rows of v_new that differ from v_old (all rows when the sizes differ).
    arguments (Input)
        v_old  % Old value.
        v_new  % New value.
    end
    arguments (Output)
        iv (:,1) double  % Changed rows.
    end
    n = size(v_new, 1);
    if size(v_old, 1) ~= n
        iv = (1:n)';
        return
    end
    if isnumeric(v_old) && isnumeric(v_new)
        iv = find(any(v_old ~= v_new & ~(isnan(v_old) & isnan(v_new)), 2));
    else
        iv = find(any(v_old ~= v_new, 2));
    end
end


function restyle(obj, s_kind, iv_index)
% Draw the appearance of the elements iv_index of a kind again once the map exists.
    arguments (Input)
        obj                    % The map.
        s_kind (1,1) string    % "bus" or "branch".
        iv_index (:,1) double  % Indices of the elements in the vectors of the kind.
    end
    if isempty(iv_index) || ~has_scene(obj)
        return
    end
    tab = obj.element_table();
    obj.apply_style(find(tab.Kind == s_kind & ismember(tab.Index, iv_index)));
    if ~isempty(obj.Selection)
        obj.apply_selection();             % the rings and lines follow the sizes
    end
end
