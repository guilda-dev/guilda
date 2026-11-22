classdef GraphNetDiagram < GraphBase
% Single-line diagram of a network: buses, components and branches, in 2D or 3D.
%
% The diagram is built from data only: a snapshot of the network (struct(net, false)) and
% the state to show. It never reads or changes a network. net.plot_diagram draws the
% equilibrium of the network, ResultPF.plot_diagram the power flow solution and
% ResultODE.plot_diagram every output time of a simulation. The colors
% of the branches and of the links (the lines between a component and its bus) follow
% ColorMode, the widths of the branches follow BranchWidthMode, the sizes of the buses and
% components MarkerSizeMode and the heights of the buses BusHeightMode. Changing a
% property updates the drawing; hovering over an element shows its values.
%
% Every value drawn by color can be read. The data tip of an element (hover, or a click in
% the data cursor mode) has, under its tag, one line "<name> = <value>" after a square of
% its color: the value that colors it at the sample shown (BusColorData of a bus; the
% quantity of ColorMode, or BranchColorData and LinkColorData under "user", of a branch
% and a link; ComponentColorData or the value of ColorMode of a component), written with
% %.4g, e.g. "LMP [cost/pu] = 12.34". The name is the colorbar label: ColorbarLabel, or
% with "" the quantity of ColorMode ("|I| [pu]", "Loss [pu]", ...), or "color" when there
% is none ("user"). The line is there even when the tip lists the same quantity below (|I|
% of the "from" end with "I", P_loss with "Loss"): it is always the colored value, named as
% the colorbar. An element without a finite color value (NaN) has no such line.
%
% Dimension chooses the drawing. "2D" (default) draws flat symbols, lines and markers
% without lighting: a bar bus is a line segment, a point bus and a component a marker, a
% branch and a link a polyline, and a transformer two overlapping circles near the "from"
% end. "3D" draws solids (boxes, tubes, spheres, cones) with lighting and arrow cones.
% Both put each bus at its height (BusHeightMode; 0 for "none"), a branch climbs linearly
% along its path between the heights of its ends, and a component and its link stay at
% the height of its bus. The first drawing looks from the top; a later drawing (Dimension,
% BusHeightMode, set_position, set_data) keeps the view the user rotated to. When the 3D
% drawing gets heights (the first drawing too) while it looks from the top, it turns to
% an oblique view (azimuth -37.5, elevation 30), and back to the top when the heights go
% away in that view.
%
% Sizes and widths are in points (pt), as LineWidth and MarkerSize of MATLAB, so they do
% not depend on the coordinates. The value of the quantity of BranchWidthMode is mapped
% linearly onto BranchWidthRange (default [1 4] pt) from its smallest value to its 95th
% percentile over the branches and all samples of the state, leaving out the top outliers
% as the automatic ColorLimits do: the top 5 % take the largest width (with fewer than 20
% values, or a 95th percentile equal to the smallest value, the scale goes to the largest
% value). The value of MarkerSizeMode is mapped from its smallest to its largest value
% onto MarkerSizeRange (default [5 10] pt; buses and components each on their own scale).
% One scale for all samples gives the same pt per unit at every time; set_data computes it
% again from the new state. A mode of "none", or a quantity with one value or no value
% (the topology), gives the middle of the range, and a NaN value the minimum. The links
% are LinkWidth wide. In 3D, 1 pt is span/400 in coordinates (span: the larger side of the
% box of the bus centers).
%
% In 2D, dots (small triangles) move along the branches and links in the direction of the
% flow of FlowMode: "P" (default), "Q" (the flow (X_from - X_to)/2 of the powers into a
% branch at its two ends, and the injection of a component), "I" (the larger |I| of the
% two ends, or |I| of a component, in the direction of P) or "none" (no dots). A dot
% moves at FlowSpeed*d0*|q|/q_max per second (d0: the median length of the branch paths;
% q_max: the largest |q| over the branches, links and all samples), and the dots of an
% element are 0.25*d0 apart, so the speed shows the flow. An element with no flow or a
% flow below 1e-3*q_max has no dots. The dots follow the sample shown (set_time) and the
% heights of the paths, and are white with a thin dark edge. With FlowAnimation
% true (default) a timer moves them about 25 times per second while the 2D figure is
% visible; it is not made in a hidden figure (show the figure, then set FlowAnimation =
% true again) nor with matlab -batch, and it stops with FlowAnimation = false, "3D",
% FlowMode "none", the figure closed, cla, or delete(G). Without it the dots stay where
% they are, so a still image shows the direction too. export_video moves them by the
% time between its frames. BranchDirection and LinkDirection are the signs of the flow
% (the cones of 3D point the same way; with FlowMode "none", the voltage angles and P).
%
% The layout comes from the graph parameters of the snapshot (notes/graph-layout.md): the
% center X, Y, Shape and Length of each bus (a bar is centered at X, Y), the bend points
% Path, the attachments FromOffset, ToOffset and Style of each branch ("transformer": a
% symbol at the "from" end), and the position DX, DY, the bend points Path and the
% attachment Offset of each component, relative to the center of its bus. A branch or a
% link meets a bar on its center line, at its offset (NaN: the nearest bend point
% projected onto the bar, or the center). The buses without a position are placed by
% tools.layout_place_buses near their neighbours (the buses with one never move); a
% component without a position is placed around its bus. These positions stay in the
% graph: nothing is written to the network. set_position moves a bus or a component in
% the drawing (never in the model); the components of a moved bus move with it.
% get_layout returns the drawn positions, and net.set_layout(G.get_layout()) saves them.
%
% The state is a struct with the fields:
%
% - `rv_t` (1 x n_t) [s]: times of the samples (or the values of other samples, e.g. the
%   steps of a continuation power flow, with s_sampleName).
% - `cm_Vbus` (n_bus x n_t) [pu]: bus voltage phasors, in the a_Bus order of the snapshot.
% - `cm_Icomp` (n_comp x n_t) [pu]: current phasors injected by the components into their
%   buses, bus by bus in the a_Bus order and in the a_Component order of each bus.
% - `c_Ybranch`, `iv_Ybranch` (optional) [pu]: the admittance matrices of the branches of
%   each sample: c_Ybranch{m} is 2 x 2 x n_branch (page k: branch k of the snapshot) and
%   iv_Ybranch (n_t values) the position in c_Ybranch of each sample, e.g. the branch
%   states of the phases of a simulation (ResultODE.plot_diagram).
% - `s_sampleName`, `sv_sampleText` (optional): the name of the samples (e.g. "Step") and
%   the text of each sample (1 x n_t), shown in the title and in the playback bar instead
%   of the time (see GraphBase).
%
% set_time(t) shows the sample nearest to t. The current injection of a bus is the sum of
% the currents of its components (NaN, a tripped unit, counts as 0), and the branch
% currents come from the bus voltages and the admittance matrix of each branch: of
% c_Ybranch at that sample when the state has it, else the field cm_Y of the branch in
% the snapshot. The stored state sct_state also holds them as cm_Ibranch (2 n_branch x
% n_t: the currents into the branch at its from and to ends).
%
% - `ColorMode`: "I" (current), "P" (active power), "Q" (reactive power), "Loss" (the
%   active-power loss Re(S_from + S_to) of each branch, charging and tap included), "none",
%   or "user" (the values set in BusColorData, ComponentColorData, BranchColorData and
%   LinkColorData are kept). With "I", "P" and "Q" a component takes the color of the
%   value of its link. While a colormap is in use (not "none", and an element has a finite
%   color value) a component without a value ("Loss", a tripped unit, a NaN row of "user")
%   is black; with "none" the components keep their class colors. ComponentColor rows
%   override both.
% - `ColorLimits`: [NaN NaN] (default) takes the limits from the data of all samples,
%   leaving out the top outliers: with m the 95th percentile of |value| over the branches,
%   the links and all samples (nearest rank), [0, m] for a magnitude ("I", "Loss") and
%   [-m, m] for a signed quantity ("P", "Q"; the injections of the components are
%   signed); the 5th to 95th percentiles with "user". Values beyond take the end colors.
%   With fewer than 20 values, or a percentile of 0, the largest (smallest) value is used.
%   A numeric [cmin cmax] fixes them.
%   Limits closer than 1e-6 of their size (a field constant up to rounding) are shown as
%   c(1 -/+ 1e-3) around their middle c, so that the colorbar ticks stay readable.
% - `BranchWidthMode`: "P", "Q" (|P_from - P_to|/2, |Q_from - Q_to|/2: the flow
%   of active or reactive power through the branch), "I" (the larger current of its two
%   ends), "G", "B", "Y" (conductance, susceptance, magnitude of the series admittance of
%   the branch), "Ysvd" (default: largest singular value of the admittance matrix of the
%   branch) or "none". The widths are on one scale from the smallest value to the 95th
%   percentile over all samples, so the top 5 % take the largest width.
% - `MarkerSizeMode`: "none" (default), "P", "Q" or "S" (|P|, |Q|, |P + jQ| of the
%   injection of a component, and of the sum of the components of a bus).
% - `BusHeightMode`: "V" (|V|), "angle" (angle of V), "Vimag" (imaginary part of V), "P",
%   "Q" (power injections) or "none". In 2D the height is the value. In 3D it is scaled
%   about the reference value (1 pu for "V", 0 for the others) so that the values of all
%   samples and the reference span a quarter of the drawing, and the heights are drawn
%   readable: a light floor with a grid below the lowest value of all samples, the
%   shadows of the bars, branches and links on it, a thin post from each bus down to it,
%   a translucent reference plane labeled with its value ("|V| = 1"), and a z axis with
%   the values and the quantity ("|V| [pu]", "∠V [rad]", "Im V [pu]", "P [pu]", "Q
%   [pu]"). The floor and the scale are the same at every sample (set_time), so the posts
%   compare across times. None of these can be clicked or has a data tip. "none" draws
%   none of them.
% - `LabelMode`: "bus" (default: the tags of the buses), "tag" (the tags of the buses and
%   components), "value" (the tags and the values: ∠V and |V| of a bus, P and Q of a
%   component, and the line "<name>=<value>" of its color value with the name and format
%   of the data tip, when it is finite; branches have no labels), "user" (the texts set in
%   BusLabel and ComponentLabel are kept) or "none". With "bus", "tag" and "value" the
%   labels are written again at every sample; the "value" labels also follow
%   BusColorData, ComponentColorData, ColorbarLabel and ColorMode set from outside (e.g.
%   in a TimeChangedFcn), row by row for the color values. In 2D, labels that overlap are
%   moved apart vertically and the axes take them in. The labels are laid out again
%   whenever the limits or the pixel size of the axes change (a GUI setting the limits or
%   resizing its panels, a resized figure, a hidden tab shown): limits set from outside
%   then stay.
% - `TitleFormat`: with more than one sample, the title is sprintf(TitleFormat, t) at every
%   sample, with t the time of the sample shown (default "t = %.2f s"); for samples named
%   by the state (s_sampleName, sv_sampleText) the title is the text of the sample
%   instead. With "" the title is never written, so a title set by title(G.ax, ...) stays.
% - `ColorbarLabel`: label of the colorbar; it stays when the diagram is drawn again. With
%   "" (default) the label is the quantity of ColorMode: "|I| [pu]", "P [pu]", "Q [pu]" or
%   "Loss [pu]" (none for "user"). It is also the name of the color value in the data tips
%   and the "value" labels ("color" when there is none).
%
% A title set by title(G.ax, ...) also stays when the diagram is drawn again (Dimension,
% set_position, set_data, or in 3D BusHeightMode and LinkWidth). The colorbar is shown
% only when an element has a color value (none for the topology). The axes fit the
% drawing (and in 2D its labels) with a padding of 3% of its larger side.
%
% The elements of tab_element are the buses (kind "bus"), the components ("component",
% their full tags), the branches ("branch") and the links ("link", the tag of their
% component). set_style sets Color of every kind, Label and MarkerSize of buses and
% components and LineWidth of branches. A color set by Color (the vectors BusColor,
% ComponentColor, BranchColor and LinkColor, NaN rows: none) stays over the color of the
% color data and of ColorMode at every sample. A size set by MarkerSize or LineWidth (the
% vectors BusMarkerSize, ComponentMarkerSize and BranchLineWidth in pt, NaN rows: none)
% stays over the size of MarkerSizeMode and the width of BranchWidthMode, without being
% mapped onto the range. These vectors change the graphics objects that are drawn and
% never draw the diagram again. A click on an element (or its data tip in the data cursor
% mode) raises ElementClicked; a selected element is marked by a ring or a wide line in
% SelectionColor. The callbacks of the graphics objects hold the diagram by a weak
% reference, so a saved figure (savefig, a Live Editor output) does not save the diagram.
%
% set_data takes the state; with the extra field sct_network (a new snapshot) it also sets
% the network again, keeping the positions, appearance and selection of the elements by
% tag (net.plot_diagram(Graph=G) uses it). A state of NaN draws the topology only: the
% hover shows tags and parameters, and the arrows are hidden.
%
% <@Examples>
% ```matlab
% net = network.IEEE14bus();
% net.initialize();
% G = net.plot_diagram();
% G.ColorMode = "P";
% G.BusHeightMode = "V";
% G.MarkerSizeMode = "P";
% G.BranchWidthRange = [0.5 6];
% G.LabelMode = "value";
% G.ColorLimits = [0 2];                  % fixed; [NaN NaN] is automatic again
% G.FlowMode = "Q";
% G.FlowSpeed = 2;
% G.Dimension = "3D";
% G.set_style("B001", Color="r");
% G.set_position("B001", [0.1, 0.9]);
% ```
%
% See also GraphBase, PowerNetwork.plot_diagram, ResultPF.plot_diagram, ResultODE.plot_diagram

    % The appearance blocks keep the order of the properties (and of the Name-Value options);
    % the SetObservable ones are the controls of show_controls (control_list).
    properties (SetObservable) % Appearance (controls of show_controls)
        Dimension (1,1) string {mustBeMember(Dimension, ["2D","3D"])} = "2D"                          % "2D": lines and markers; "3D": solids with lighting (see the class help).
        ColorLimits (1,2) double = [NaN NaN]                                                            % Limits of the color scale (clim of the axes); NaN: from the data (see the class help).
    end
    properties % Appearance
        Colormap (:,3) double = turbo                                                                   % Colormap of the color values.
    end
    properties (SetObservable) % Appearance (controls of show_controls)
        ColorMode (1,1) string {mustBeMember(ColorMode, ["none","Loss","I","P","Q","user"])} = "I"     % Quantity that colors the branches and links (see the class help).
        LabelFontSize (1,1) double = 5                                                                  % Font size of the labels.
    end
    properties % Appearance
        LabelFontWeight (1,1) string = "bold"                                                           % Font weight of the bus labels.
    end
    properties (SetObservable) % Appearance (controls of show_controls)
        BranchWidthMode (1,1) string {mustBeMember(BranchWidthMode, ["none","P","Q","I","G","B","Y","Ysvd"])} = "Ysvd" % Quantity that sets the branch widths (see the class help).
        BranchWidthRange (1,2) double = [1 4]                                                           % [pt] Range [min max] of the branch widths.
        MarkerSizeMode (1,1) string {mustBeMember(MarkerSizeMode, ["none","P","Q","S"])} = "none"      % Quantity that sets the bus and component sizes (see the class help).
        MarkerSizeRange (1,2) double = [5 10]                                                           % [pt] Range [min max] of the bus and component sizes.
        LinkWidth (1,1) double {mustBePositive, mustBeFinite} = 1                                       % [pt] Width of the links (component to bus).
        BusHeightMode (1,1) string {mustBeMember(BusHeightMode, ["none","V","angle","Vimag","P","Q"])} = "none" % Quantity that sets the height of each bus (see the class help).
    end
    properties % Appearance
        BusColorData (:,1) double = []                                                                  % Color values of the buses, one per bus.
        ComponentColorData (:,1) double = []                                                            % Color values of the components, one per component.
        BranchColorData (:,1) double = []                                                               % Color values of the branches, one per branch.
        LinkColorData (:,1) double = []                                                                 % Color values of the links (component to bus), one per component.
        BusLabel (:,1) string = []                                                                      % Labels of the buses, one per bus.
        ComponentLabel (:,1) string = []                                                                % Labels of the components, one per component.
    end
    properties (SetObservable) % Appearance (controls of show_controls)
        LabelMode (1,1) string {mustBeMember(LabelMode, ["none","bus","tag","value","user"])} = "bus"  % Labels shown: "bus" (bus tags), "tag", "value", "user" (BusLabel and ComponentLabel kept) or "none".
    end
    properties % Appearance
        BranchDirection (:,1) double = []                                                               % Arrow direction of each branch: 1 forward, -1 backward, 0 none.
        LinkDirection (:,1) double = []                                                                 % Arrow direction of each link: 1, -1 or 0.
        GridSpacing (1,1) double = 0.01                                                                 % Spacing of the grid lines of the axes.
        TitleFormat (1,1) string = "t = %.2f s"                                                         % Format of the title written at each sample (sprintf of the time); "": none.
        ColorbarLabel (1,1) string = ""                                                                 % Label of the colorbar; "": the quantity of ColorMode.
    end
    properties (SetObservable) % Flow animation (2D, controls of show_controls)
        FlowMode (1,1) string {mustBeMember(FlowMode, ["none","P","Q","I"])} = "P"                     % Quantity of the flow dots (see the class help); "none": no dots.
        FlowAnimation (1,1) logical = true                                                              % Move the flow dots by a timer (visible 2D figures, not in matlab -batch).
        FlowSpeed (1,1) double {mustBePositive, mustBeFinite} = 1                                       % Distance per second of the dots of the largest flow, in units of d0.
    end
    properties % Fixed colors of each element (set_style Color)
        BusColor (:,3) double = zeros(0, 3)                                                             % RGB color of each bus over its color data; NaN rows: none.
        ComponentColor (:,3) double = zeros(0, 3)                                                       % RGB color of each component over its color data; NaN rows: none.
        BranchColor (:,3) double = zeros(0, 3)                                                          % RGB color of each branch over its color data; NaN rows: none.
        LinkColor (:,3) double = zeros(0, 3)                                                            % RGB color of each link over its color data; NaN rows: none.
    end
    properties % Sizes of each element (set_style MarkerSize and LineWidth)
        BusMarkerSize (:,1) double = zeros(0, 1)                                                        % [pt] Size of each bus; NaN rows: the size of MarkerSizeMode in MarkerSizeRange.
        ComponentMarkerSize (:,1) double = zeros(0, 1)                                                  % [pt] Size of each component; NaN rows: the size of MarkerSizeMode in MarkerSizeRange.
        BranchLineWidth (:,1) double = zeros(0, 1)                                                      % [pt] Width of each branch; NaN rows: the width of BranchWidthMode in BranchWidthRange.
    end
    properties (SetAccess = private) % State
        sct_state                                                                                       % State shown: rv_t, cm_Vbus, cm_Icomp and the branch currents cm_Ibranch (see the class help). <@Type> struct
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
        sv_componentTag                                                                                 % Full component tags.
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
    properties (Access = private) % Sizes and drawing
        sct_scale = struct("Branch", [NaN NaN], "Bus", [NaN NaN], "Comp", [NaN NaN])                   % Scales [vmin vmax] of the size quantities over all samples of the state.
        l_viewSet (1,1) logical = false                                                                 % The view of the axes was set once: a new drawing keeps it.
        l_drawing (1,1) logical = false                                                                 % create_scene is setting the values: the setters draw nothing.
        rv_climAuto (1,2) double = [0 1]                                                                % Automatic color limits of ColorMode over all samples (update_color_scale).
        lis_labelAxes = []                                                                              % Listener on MarkedClean of the axes that lays the 2D labels out again (fit_axes). <@Type> event.listener
        l_labelBusy (1,1) logical = false                                                               % fit_axes is laying the labels out: the listener does nothing.
        l_labelAuto (1,1) logical = false                                                               % reflect_node_label is writing the labels of LabelMode: set.ComponentLabel makes no text objects.
    end
    properties (Access = private) % Flow animation
        sct_flow = struct("rm_q", zeros(0, 1), "r_qmax", NaN, "rv_v", zeros(0, 1), "rv_dir", zeros(0, 1), "rv_phase", zeros(0, 1)) % Flow values (elements x samples, branches then links), speeds, directions and phases of the dots.
        sct_flowPath = struct.empty                                                                     % Paths of the dots of the branches and of the links (flow_paths).
        h_flowTimer = []                                                                                % Timer of the animation; [] when it does not run. <@Type> timer
        lis_flowAxes = []                                                                               % Listener that stops the timer when the axes are deleted. <@Type> event.listener
        u_flowTic = uint64(0)                                                                           % tic of the last frame of the timer.
        l_flowHold (1,1) logical = false                                                                % export_video advances the dots (prepare_frame): no timer.
    end

    methods
        function obj = GraphNetDiagram(sct_network, sct_state, opt)
        % Create the diagram from a network snapshot and a state, and draw its first sample.
            arguments (Input)
                sct_network (1,1) struct  % Snapshot of the network: struct(net, false).
                sct_state   (1,1) struct  % State to show: rv_t, cm_Vbus, cm_Icomp (see the class help).
                opt.?GraphNetDiagram      % Name-Value options; each field is copied to the property of the same name.
                opt.Parent = []           % Container (figure, uifigure, uipanel, uitab, uigridlayout) or axes/uiaxes to draw in; [] for a new figure.
            end
            arguments (Output)
                obj  % The diagram.
            end
            obj.set_network(sct_network);
            obj.load_data(sct_state);
            obj.build(opt);
        end

        set_position(obj, sr_tag, rm_xy)
        sct_layout = get_layout(obj)

        function delete(obj)
        % Stop and delete the timer of the flow animation when the diagram is deleted.
        % No arguments block: with one, MATLAB takes delete as an ordinary method and not
        % as the destructor, so delete(G) would leave G valid.
            obj.flow_timer("stop");
        end
    end

    methods (Access = protected)
        load_data(obj, sct_state)
        create_scene(obj)
        update_scene(obj, k)
        apply_style(obj, iv_element)
        tab = element_table(obj)
        sct_map = style_properties(obj)
        apply_selection(obj)
        prepare_frame(obj, r_dt)
        sct_ctl = control_list(obj)
    end

    methods (Hidden)
        step_flow(obj, r_dt)
        output_txt = hover_bus(obj, i_bus)
        output_txt = hover_branch(obj, i_branch)
        output_txt = hover_component(obj, i_comp)
    end

    methods (Static, Access = private)
        r = color_percentile(rv_v, r_q)
    end

    methods (Access = private)
        set_network(obj, sct_network)
        set_powerflow(obj, cv_Vbus, cv_Icomp, cv_Ibranch)
        sct_g = diagram_geometry(obj)
        draw_graph_network(obj, sct_g, fcn_click)
        draw_diagram_2d(obj, sct_g, fcn_click)
        update_heights(obj)
        sct_v = size_values(obj, iv_k)
        update_scale(obj)
        iv_row = update_sizes(obj)
        reflect_color_mode(obj)
        reflect_node_label(obj, iv_bus, iv_comp)
        make_component_labels(obj, iv_comp)
        reflect_arrow_forward(obj)
        rm_color = color_of_values(obj, rv_value)
        [rm_branch, rm_link] = color_values(obj, iv_k)
        rv_lim = color_limits(obj)
        [sv_line, rv_value, s_label] = color_readout(obj, s_kind, iv_index, s_sep)
        update_color_scale(obj)
        fit_axes(obj, s_mode)
        flag = validate(obj)
        flow_values(obj)
        flow_paths(obj)
        update_flow(obj)
        flow_timer(obj, s_action)
    end

    methods
        function set.ColorLimits(obj, color_lim)
            obj.ColorLimits = color_lim;
            restyle_all(obj);              % apply_style sets the limits in use to the axes
        end

        function set.Colormap(obj, cmap)
            obj.Colormap = cmap;
            if ~isempty(obj.ax) && all(isgraphics(obj.ax))                 %#ok<MCSUP>
                colormap(obj.ax, obj.Colormap);                             %#ok<MCSUP>
            end
            restyle_all(obj);
        end

        function set.ColorMode(obj, edge_color_mode)
            obj.ColorMode = edge_color_mode;
            obj.update_color_scale();      % the automatic limits of the new quantity
            if validate(obj); return; end
            obj.reflect_color_mode();
            refresh_value_labels(obj);     % the name of the color values follows the quantity
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
            if obj.Dimension == "2D"                                        %#ok<MCSUP>
                obj.fit_axes();            % the labels apart again, inside the limits
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

        % Setters of the drawing: Dimension draws the diagram again; BusHeightMode too in 3D
        function set.Dimension(obj, val)
            obj.Dimension = val;
            redraw(obj);
        end
        function set.BusHeightMode(obj, val)
            obj.BusHeightMode = val;
            if validate(obj); return; end
            if obj.Dimension == "3D"                                        %#ok<MCSUP>
                redraw(obj);
            else
                obj.update_heights();
                obj.apply_selection();
                obj.flow_paths();          % the dots follow the new heights of the paths
                obj.update_flow();
            end
        end

        % Setters of the sizes: new scale (modes) or new range, then the sizes of every element
        function set.BranchWidthMode(obj, val)
            obj.BranchWidthMode = val;
            obj.update_scale();
            resize(obj);
        end
        function set.MarkerSizeMode(obj, val)
            obj.MarkerSizeMode = val;
            obj.update_scale();
            resize(obj);
        end
        function set.BranchWidthRange(obj, rv_range)
            check_range(rv_range, "BranchWidthRange");
            obj.BranchWidthRange = rv_range;
            resize(obj);
        end
        function set.MarkerSizeRange(obj, rv_range)
            check_range(rv_range, "MarkerSizeRange");
            obj.MarkerSizeRange = rv_range;
            resize(obj);
        end
        function set.LinkWidth(obj, val)
            obj.LinkWidth = val;
            if validate(obj); return; end
            if obj.Dimension == "3D"                                        %#ok<MCSUP>
                redraw(obj);
            else
                set(obj.sct_plt.CompEdge(isgraphics(obj.sct_plt.CompEdge)), "LineWidth", val); %#ok<MCSUP>
                if ~isempty(obj.Selection)                                  %#ok<MCSUP>
                    obj.apply_selection();
                end
            end
        end

        % Setters of the color values, fixed colors, sizes and labels: draw the changed elements again
        function set.BusColorData(obj, rv_value)
            iv = changed_rows(obj.BusColorData, rv_value);
            obj.BusColorData = rv_value;
            restyle(obj, "bus", iv);
            if ~isempty(iv)
                refresh_value_labels(obj, iv, zeros(0, 1));
            end
        end
        function set.ComponentColorData(obj, rv_value)
            iv = changed_rows(obj.ComponentColorData, rv_value);
            obj.ComponentColorData = rv_value;
            restyle(obj, "component", iv);
            if ~isempty(iv)
                refresh_value_labels(obj, zeros(0, 1), iv);
            end
        end
        function set.BranchColorData(obj, rv_value)
            iv = changed_rows(obj.BranchColorData, rv_value);
            obj.BranchColorData = rv_value;
            restyle(obj, "branch", iv);
        end
        function set.LinkColorData(obj, rv_value)
            iv = changed_rows(obj.LinkColorData, rv_value);
            obj.LinkColorData = rv_value;
            restyle(obj, "link", iv);
        end
        function set.BusColor(obj, rm_color)
            iv = changed_rows(obj.BusColor, rm_color);
            obj.BusColor = rm_color;
            restyle(obj, "bus", iv);
        end
        function set.ComponentColor(obj, rm_color)
            iv = changed_rows(obj.ComponentColor, rm_color);
            obj.ComponentColor = rm_color;
            restyle(obj, "component", iv);
        end
        function set.BranchColor(obj, rm_color)
            iv = changed_rows(obj.BranchColor, rm_color);
            obj.BranchColor = rm_color;
            restyle(obj, "branch", iv);
        end
        function set.LinkColor(obj, rm_color)
            iv = changed_rows(obj.LinkColor, rm_color);
            obj.LinkColor = rm_color;
            restyle(obj, "link", iv);
        end
        function set.BusMarkerSize(obj, rv_size)
            iv = changed_rows(obj.BusMarkerSize, rv_size);
            obj.BusMarkerSize = rv_size;
            restyle(obj, "bus", iv);
        end
        function set.ComponentMarkerSize(obj, rv_size)
            iv = changed_rows(obj.ComponentMarkerSize, rv_size);
            obj.ComponentMarkerSize = rv_size;
            restyle(obj, "component", iv);
        end
        function set.BranchLineWidth(obj, rv_width)
            iv = changed_rows(obj.BranchLineWidth, rv_width);
            obj.BranchLineWidth = rv_width;
            restyle(obj, "branch", iv);
        end
        function set.BusLabel(obj, label)
            label = string(label);
            iv = changed_rows(obj.BusLabel, label);
            obj.BusLabel = label;
            restyle(obj, "bus", iv);
        end
        function set.ComponentLabel(obj, label)
            label = string(label);
            iv = changed_rows(obj.ComponentLabel, label);
            obj.ComponentLabel = label;
            if ~isempty(iv) && ~obj.l_labelAuto && ~obj.l_drawing && ~validate(obj)    %#ok<MCSUP>
                obj.make_component_labels(iv);   % a label set by the user (set_style, the vector) gets its text object
            end
            restyle(obj, "component", iv);
        end
        function set.LabelMode(obj, mode)
            obj.LabelMode = mode;
            if validate(obj); return; end
            obj.reflect_node_label();
            if obj.Dimension == "2D"                                        %#ok<MCSUP>
                obj.fit_axes();            % the labels shown apart, inside the limits
            end
        end

        % Setters of the arrow directions: the cones (3D) and the flow dots (2D) follow
        function set.BranchDirection(obj, forward)
            obj.BranchDirection = forward;
            if validate(obj); return; end
            set_arrow_direction(obj.sct_plt.EdgeArrow, forward);            %#ok<MCSUP>
            obj.update_flow();
        end
        function set.LinkDirection(obj, forward)
            obj.LinkDirection = forward;
            if validate(obj); return; end
            set_arrow_direction(obj.sct_plt.CompArrow, forward);            %#ok<MCSUP>
            obj.update_flow();
        end

        % Setters of the flow animation
        function set.FlowMode(obj, val)
            obj.FlowMode = val;
            obj.flow_values();             % the flow of every sample and its scale
            if validate(obj); return; end
            obj.reflect_arrow_forward();   % the directions follow the quantity (update_flow too)
            obj.flow_timer("auto");
        end
        function set.FlowAnimation(obj, val)
            obj.FlowAnimation = val;
            obj.flow_timer("auto");
        end
        function set.FlowSpeed(obj, val)
            obj.FlowSpeed = val;
            if validate(obj); return; end
            obj.update_flow();
        end

        function set.GridSpacing(obj, val)
            val = abs(val);
            obj.GridSpacing = val;
            if validate(obj); return; end
            xticks(obj.ax, 0:val:1)                                         %#ok<MCSUP>
            yticks(obj.ax, 0:val:1)                                         %#ok<MCSUP>
        end

        % Setters of the title and the colorbar label: change the text only
        function set.TitleFormat(obj, s_format)
            obj.TitleFormat = s_format;
            if validate(obj) || s_format == "" || numel(obj.rv_t) < 2       %#ok<MCSUP>
                return
            end
            title(obj.ax, sprintf(s_format, obj.rv_t(obj.i_time)));         %#ok<MCSUP>
        end
        function set.ColorbarLabel(obj, s_label)
            obj.ColorbarLabel = s_label;
            if validate(obj)
                return
            end
            refresh_value_labels(obj);     % the name of the color values in the labels
            if isscalar(obj.ax(1).Colorbar)                                 %#ok<MCSUP>
                obj.apply_style(zeros(0, 1));  % the colorbar part only: the label ("": that of ColorMode)
            end
        end
    end
end


function redraw(obj)
% Draw the diagram again after a property that changes its shapes was set.
    arguments (Input)
        obj  % The diagram.
    end
    if validate(obj); return; end
    obj.create_scene();
    obj.apply_selection();
end


function resize(obj)
% Give every element the size and width of its value at the sample shown, once the diagram exists.
    arguments (Input)
        obj  % The diagram.
    end
    if validate(obj); return; end
    obj.apply_style(obj.update_sizes());
    if ~isempty(obj.Selection)
        obj.apply_selection();             % the overlay follows the sizes
    end
end


function check_range(rv_range, s_name)
% Stop unless the range is finite and positive with its minimum first.
    arguments (Input)
        rv_range (1,2) double  % Range [a b].
        s_name (1,1) string    % Name of the property.
    end
    if ~(all(isfinite(rv_range)) && all(rv_range > 0) && rv_range(1) <= rv_range(2))
        error(msg("GUILDA:GraphNetDiagram:RangeValue", s_name, mat2str(rv_range)));
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
    if isnumeric(v_old) && isnumeric(v_new)
        iv = find(any(v_old ~= v_new & ~(isnan(v_old) & isnan(v_new)), 2));
    else
        iv = find(~arrayfun(@(i) isequaln(v_old(i, :), v_new(i, :)), (1:n)'));
    end
end


function restyle(obj, s_kind, iv_index)
% Draw the appearance of the elements iv_index of a kind again once the diagram exists.
    arguments (Input)
        obj                    % The diagram.
        s_kind (1,1) string    % "bus", "component", "branch" or "link".
        iv_index (:,1) double  % Indices of the elements in the vectors of the kind.
    end
    if isempty(iv_index) || obj.l_drawing || validate(obj)
        return
    end
    tab = obj.element_table();
    obj.apply_style(find(tab.Kind == s_kind & ismember(tab.Index, iv_index)));
    if ~isempty(obj.Selection) && any(s_kind == ["bus", "component", "branch"])
        obj.apply_selection();             % the overlay follows the sizes and widths
    end
end


function restyle_all(obj)
% Draw the appearance of every element again once the diagram exists (new color scale).
    arguments (Input)
        obj  % The diagram.
    end
    if obj.l_drawing || validate(obj)
        return
    end
    obj.apply_style((1:height(obj.element_table()))');
end


function refresh_value_labels(obj, iv_bus, iv_comp)
% Write the labels of LabelMode "value" again after a color value or its name changed.
%
% Only the rows iv_bus and iv_comp are written (reflect_node_label; default: all). In 2D,
% when a label gained or lost its line of the color value, the labels are laid out again:
% the limits are fit again while they are still the ones fit_axes set, else they stay.
    arguments (Input)
        obj                                           % The diagram.
        iv_bus (:,1) double = (1:obj.n_bus)'          % Buses whose color value changed.
        iv_comp (:,1) double = (1:obj.n_component)'   % Components whose color value changed.
    end
    if obj.LabelMode ~= "value" || obj.l_drawing || validate(obj)
        return
    end
    rv_lines = [count(obj.BusLabel, newline); count(obj.ComponentLabel, newline)];
    obj.reflect_node_label(iv_bus, iv_comp);
    if obj.Dimension == "2D" && ~isequaln(rv_lines, [count(obj.BusLabel, newline); count(obj.ComponentLabel, newline)])
        ax = obj.ax(1);
        if isfield(obj.sct_plt, "FitLim") && isequal([ax.XLim, ax.YLim], obj.sct_plt.FitLim)
            obj.fit_axes("fit");
        else
            obj.fit_axes("labels");
        end
    end
end


function set_arrow_direction(h_arrow, rv_forward)
% Show the arrow cone (3D) at the "To" end (1), at the "From" end (-1) or none (0).
    arguments (Input)
        h_arrow                  % Groups of the two cones of each element (Tag "To" and "From"); none in 2D.
        rv_forward (:,1) double  % Direction of each element.
    end
    for i = 1:min(numel(h_arrow), numel(rv_forward))
        if ~isgraphics(h_arrow(i))
            continue
        end
        for h = reshape(allchild(h_arrow(i)), 1, [])
            h.Visible = (h.Tag == "To" && sign(rv_forward(i)) == 1) || (h.Tag == "From" && sign(rv_forward(i)) == -1);
        end
    end
end
