classdef GraphConnection < GraphBase
% Block diagram of the signal connections: controllers, components and buses with the signals between them.
%
% The graph draws one block per bus, component, local controller and global controller,
% in layers from left to right: the global controllers, the local controllers (a
% controller held by another one to its left), the components and the buses. Each
% component is joined to its bus by a thin line. The signals are arrows from the block
% that gives them to the block that takes them, labeled with their names; the kind of the
% signal sets the color and the line style of the arrow:
%
% | Kind | Signal | Default |
% |---|---|---|
% | local | output of a local controller into its parent | blue, solid |
% | global | output of a global controller into a unit or its controllers | orange, solid |
% | observe | output or state of a component read by a controller | green, dashed |
% | equilibrium | the input keeps its equilibrium value (no source block) | gray, dotted, from a short stub |
%
% The rows follow the order of the data: the blocks without a held block take one row
% each, and a block that holds others is at the middle of them (a bus at the middle of
% its components, a component at the middle of its controllers). A global controller is
% at the middle of the blocks it is joined to, moved apart from the other global
% controllers when they would overlap. A block is drawn when it is in the data; the arrows
% at one side of a block are spread over its height in the order of their other ends.
% It is built from data only (see PowerNetwork.plot_connection).
%
% The data (constructor and set_data) is a struct with the fields:
%
% - `sv_blockTag` (n_block): the tags of the blocks, unique and nonempty.
% - `sv_blockKind` (n_block): "bus", "component", "localcontroller" or "globalcontroller".
% - `sv_blockParent` (n_block): the tag of the block that holds each one (the bus of a
%   component, the component or the controller of a local controller); "" for a bus,
%   a global controller, or a block whose holder is not in the data.
% - `sv_blockClass` (n_block, optional): a second line of text in the block, e.g. its class.
% - `sv_arrowSource` (n_arrow): the tag of the block that gives the signal; "" for Kind
%   "equilibrium".
% - `sv_arrowTarget` (n_arrow): the tag of the block that takes the signal.
% - `sv_arrowKind` (n_arrow): "local", "global", "observe" or "equilibrium".
% - `sv_arrowLabel` (n_arrow, optional): the names of the signals of each arrow.
% - `s_title` (optional, default ""): the title.
%
% Elements: one row per block (Kind: its kind of block, Tag: its tag), then one per arrow
% (Kind: its kind of signal, Tag: "<source>-><target>", or "(equilibrium)-><target>").
% Index is the row in the Block* or the Arrow* properties. A click on a block, an arrow or
% its label is a click on its element (ElementClicked). set_style options by kind:
%
% | Kind | Options |
% |---|---|
% | bus, component, localcontroller, globalcontroller | Color, Label, LineWidth |
% | local, global, observe, equilibrium | Color, Label, LineWidth, LineStyle |
%
% The graph has one sample and no controls. Parent: a container gives a tiled layout with
% one axes; an axes or uiaxes is used directly (see GraphBase).
%
% <@Examples>
% ```matlab
% sct = struct();
% sct.sv_blockTag    = ["B1"; "G1"; "AVR1"];
% sct.sv_blockKind   = ["bus"; "component"; "localcontroller"];
% sct.sv_blockParent = [""; "B1"; "G1"];
% sct.sv_arrowSource = ["AVR1"; "G1"];
% sct.sv_arrowTarget = ["G1"; "AVR1"];
% sct.sv_arrowKind   = ["local"; "observe"];
% sct.sv_arrowLabel  = ["Vfield"; "Ifield"];
% G = GraphConnection(sct);
% G.set_style("AVR1->G1", Color="r", LineWidth=2);
% G.select("G1");
% ```
%
% See also PowerNetwork.plot_connection, PowerNetwork.disp_connection, GraphBase

    properties % Appearance of each element (one row per element, see tab_element)
        BlockColor (:,3) double = zeros(0, 3)            % RGB color of the edge (and the light fill) of each block.
        BlockLabel (:,1) string = strings(0, 1)          % First line of the text of each block (default: its tag).
        BlockLineWidth (:,1) double = zeros(0, 1)        % [pt] Width of the edge of each block.
        ArrowColor (:,3) double = zeros(0, 3)            % RGB color of each arrow and its label.
        ArrowLabel (:,1) string = strings(0, 1)          % Label of each arrow (default: the names of its signals).
        ArrowLineWidth (:,1) double = zeros(0, 1)        % [pt] Width of each arrow.
        ArrowLineStyle (:,1) string = strings(0, 1)      % Line style of each arrow ("-", "--", ":", "-.").
    end
    properties (Access = protected) % Data
        sct_data                                         % Data of the graph with the optional fields filled and the layout (rm_blockXY, rm_arrowPath). <@Type> struct
    end

    methods
        function obj = GraphConnection(sct_data, opt)
        % Check the data, lay out the blocks and draw the diagram.
            arguments (Input)
                sct_data (1,1) struct  % Data of the graph (see the class help).
                opt.Parent = []        % Container (figure, uifigure, uipanel, uitab, uigridlayout), or axes/uiaxes; [] for a new figure.
            end
            arguments (Output)
                obj  % The graph.
            end
            obj.load_data(sct_data);
            if isempty(opt.Parent)          % a new figure sized to the diagram: about 40 px per unit
                rm_xy = obj.sct_data.rm_blockXY;
                rv_px = [40 * (max([rm_xy(:, 1); 0]) + 5), 40 * (max([rm_xy(:, 2); 1]) + 2) + 90];
                opt.Parent = figure("Position", [80 80 min(max(rv_px, [640 300]), [1800 1100])]);
            end
            obj.build(opt);
        end

        % Setters of the appearance of each element: draw the changed elements again
        function set.BlockColor(obj, val)
            arguments (Input)
                obj
                val  % One RGB row per block.
            end
            check_rows(obj, val, "BlockColor", "block");
            check_color(val, "BlockColor");
            iv = changed_rows(obj.BlockColor, val);
            obj.BlockColor = val;
            restyle(obj, iv);
        end
        function set.BlockLabel(obj, val)
            arguments (Input)
                obj
                val  % One text per block.
            end
            check_rows(obj, val, "BlockLabel", "block");
            iv = changed_rows(obj.BlockLabel, val);
            obj.BlockLabel = val;
            restyle(obj, iv);
        end
        function set.BlockLineWidth(obj, val)
            arguments (Input)
                obj
                val  % One width per block.
            end
            check_rows(obj, val, "BlockLineWidth", "block");
            check_width(val, "BlockLineWidth");
            iv = changed_rows(obj.BlockLineWidth, val);
            obj.BlockLineWidth = val;
            restyle(obj, iv);
        end
        function set.ArrowColor(obj, val)
            arguments (Input)
                obj
                val  % One RGB row per arrow.
            end
            check_rows(obj, val, "ArrowColor", "arrow");
            check_color(val, "ArrowColor");
            iv = changed_rows(obj.ArrowColor, val);
            obj.ArrowColor = val;
            restyle(obj, iv + n_block(obj));
        end
        function set.ArrowLabel(obj, val)
            arguments (Input)
                obj
                val  % One text per arrow.
            end
            check_rows(obj, val, "ArrowLabel", "arrow");
            iv = changed_rows(obj.ArrowLabel, val);
            obj.ArrowLabel = val;
            restyle(obj, iv + n_block(obj));
        end
        function set.ArrowLineWidth(obj, val)
            arguments (Input)
                obj
                val  % One width per arrow.
            end
            check_rows(obj, val, "ArrowLineWidth", "arrow");
            check_width(val, "ArrowLineWidth");
            iv = changed_rows(obj.ArrowLineWidth, val);
            obj.ArrowLineWidth = val;
            restyle(obj, iv + n_block(obj));
        end
        function set.ArrowLineStyle(obj, val)
            arguments (Input)
                obj
                val  % One line style per arrow.
            end
            check_rows(obj, val, "ArrowLineStyle", "arrow");
            if ~all(ismember(val, ["-", "--", ":", "-."]))
                error(msg("GUILDA:GraphBase:StyleValue", "LineStyle", """-"", ""--"", "":"" or ""-."""));
            end
            iv = changed_rows(obj.ArrowLineStyle, val);
            obj.ArrowLineStyle = val;
            restyle(obj, iv + n_block(obj));
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
    end
end


function n = n_block(obj)
% Number of blocks of the data (the arrows follow them in tab_element).
    arguments (Input)
        obj  % The graph.
    end
    arguments (Output)
        n (1,1) double  % Number of blocks.
    end
    n = 0;
    if ~isempty(obj.sct_data)
        n = numel(obj.sct_data.sv_blockTag);
    end
end


function check_rows(obj, val, s_prop, s_of)
% Stop when a vector property does not have one row per block (or per arrow).
    arguments (Input)
        obj                  % The graph.
        val                  % New value of the property.
        s_prop (1,1) string  % Name of the property.
        s_of (1,1) string    % "block" or "arrow".
    end
    if isempty(obj.sct_data)
        return
    end
    n = numel(obj.sct_data.("sv_" + s_of + "Tag"));
    if size(val, 1) ~= n
        error(msg("GUILDA:GraphBase:StyleValue", s_prop, n + " rows (one per " + s_of + ")"));
    end
end


function check_color(val, s_prop)
% Stop when a color property has values outside 0 to 1.
    arguments (Input)
        val                  % New value of the property.
        s_prop (1,1) string  % Name of the property.
    end
    if ~all(val >= 0 & val <= 1, "all")
        error(msg("GUILDA:GraphBase:StyleValue", s_prop, "RGB values from 0 to 1"));
    end
end


function check_width(val, s_prop)
% Stop when a width property has values that are not positive.
    arguments (Input)
        val                  % New value of the property.
        s_prop (1,1) string  % Name of the property.
    end
    if ~all(val > 0 & isfinite(val))
        error(msg("GUILDA:GraphBase:StyleValue", s_prop, "positive widths"));
    end
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
    iv = find(~arrayfun(@(i) isequaln(v_old(i, :), v_new(i, :)), (1:n)'));
end


function restyle(obj, iv_element)
% Draw the appearance of the elements iv_element again once the graph exists.
    arguments (Input)
        obj                      % The graph.
        iv_element (:,1) double  % Rows of the elements in tab_element.
    end
    if ~isempty(iv_element) && ~isempty(obj.sct_plt) && ~isempty(obj.ax) && all(isgraphics(obj.ax))
        obj.apply_style(iv_element);
    end
end
