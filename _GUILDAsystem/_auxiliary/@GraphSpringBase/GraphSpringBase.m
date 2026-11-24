classdef (Abstract) GraphSpringBase < GraphBase
% Abstract base class of the spring-mass pictures of a power system (GraphSpring2D, GraphSpring3D).
%
% The nodes are voltage phasors: the buses, and the own nodes of components such as the
% internal voltage E' of a synchronous machine. The springs are the branches and the
% reactances between a bus and the own node of its component. At chosen nodes a pair of
% arrows shows the active power P (tangential) and the reactive-current magnitude Iq
% (radial). GraphSpring2D draws the phasor plane and GraphSpring3D puts the nodes on the
% surface z = log|V|.
%
% The constructor of a subclass takes the data as a struct (one sample for a picture,
% several for an animation):
%
% - `rv_t` (1 x n_t) [s]: times (or the values of other samples, e.g. the steps of a
%   continuation power flow, with s_sampleName).
% - `sv_node` (n_node x 1): node tags; `sv_kind` (n_node x 1): "bus" or "component".
% - `cm_V` (n_node x n_t) [pu]: node phasors over time.
% - `im_edge` (2 x n_edge): node indices of each spring; `sv_edge` (n_edge x 1): their
%   tags (optional).
% - `iv_arrow` (n_arrow x 1): the node of each arrow pair; `rm_P`, `rm_Iq`
%   (n_arrow x n_t) [pu]: active power and reactive-current magnitude (optional).
% - `sv_marker` (MATLAB marker; "v" is a cone in 3D, other markers are spheres),
%   `rv_size` (NaN: default of the kind), `sv_color` ("": default of the kind; a color
%   name or "#RRGGBB") and `rv_circle` [pu] (radius of a dashed |E| circle; NaN: none;
%   hidden at the samples where the phasor of its node is NaN), n_node x 1 each (optional).
% - `s_sampleName`, `sv_sampleText` (optional): the name of the samples (e.g. "Step") and
%   the text of each sample (1 x n_t), shown in the title and in the playback bar instead
%   of the time (see GraphBase).
%
% The appearance fields set the initial values of the vector properties NodeMarker,
% NodeSize and NodeColor; after that the vector properties are the appearance (sct_data
% keeps the other fields). The elements of tab_element are the nodes (kind "node", tag
% sv_node), the springs ("edge", tag sv_edge; "E1", "E2", ... when not given) and the
% arrow pairs ("arrow", the tag of their node). set_style sets Color, Label, Marker,
% MarkerSize and Visible of a node and Color, LineWidth and Visible of a spring; the
% arrows have no options. The positions are the phasors: set_position and get_layout are errors. A
% click on a node or a spring raises ElementClicked; a selected node gets a ring and a
% selected spring a wide line in SelectionColor.
%
% The common rotation of the buses is removed by `RotationScale`: the angle reference at
% sample k is $\bar\theta_1 + (1-s)(\bar\theta_k - \bar\theta_1)$, where
% $\bar\theta_k$ is the mean of the unwrapped bus angles and s is RotationScale. s = 1
% keeps the actual rotation (only the initial mean is removed), s = 0 removes it at every
% sample. Changing a property redraws the current sample.
%
% show_controls shows ShowLabel, ShowValue and ShowLegend (Label), RotationScale,
% ArrowScaleP and ArrowScaleQ (View); with two or more samples the time is in the
% playback bar below the axes (see GraphBase).
%
% The coils of the springs have the radius SpringAmplitude in pu, the same on every spring
% whatever its length; a spring shorter than SpringAmplitude/0.06 gets a radius of 6 % of
% its length so that its loops do not overlap.
%
% <@Examples>
% ```matlab
% sct.rv_t    = 0;
% sct.sv_node = ["B1"; "B2"; "G1"];
% sct.sv_kind = ["bus"; "bus"; "component"];
% sct.cm_V    = [1; 0.98*exp(-0.2j); 1.05*exp(0.3j)];
% sct.im_edge = [1 2; 1 3]';
% G = GraphSpring2D(sct);
% G.ArrowScaleP = 0.5;
% G.set_style("G1", Color="r", MarkerSize=20);   % the same as G.NodeColor(3, :) = [1 0 0] ...
% ```
%
% The data of a network or of an analysis result is assembled by
% PowerNetwork.plot_spring_model (the equilibrium), ResultODE.plot_spring_model (all
% output times, for animate and export_video) and ResultPF.plot_spring_model (the buses).
%
% See also GraphBase, GraphSpring2D, GraphSpring3D, PowerNetwork.plot_spring_model, ResultODE.plot_spring_model, ResultPF.plot_spring_model

    properties (SetObservable) % Appearance (controls of show_controls)
        RotationScale (1,1) double = 1                        % Share of the common rotation of the buses that is shown: 1 the actual rotation, 0 none.
        ArrowScaleP (1,1) double = 0.30                       % [1/pu] Length of the active power arrow per unit of P.
        ArrowScaleQ (1,1) double = 0.30                       % [1/pu] Length of the reactive-current arrow per unit of Iq.
        ShowLabel (1,1) logical = true                        % Show the node labels.
        ShowValue (1,1) logical = true                        % Show the values of P and Iq next to the arrows (none for an arrow scale of 0).
        ShowLegend (1,1) logical = true                       % Show the legend of the arrows.
    end
    properties % Appearance
        SpringTurns (1,1) double {mustBePositive} = 5         % Coil turns: per spring (2D) or per unit of spring length (3D).
        SpringAmplitude (1,1) double {mustBePositive} = 0.02  % [pu] Coil radius, the same on every spring (at most 6 % of the spring length).
    end
    properties % Appearance of each element
        NodeColor (:,3) double {mustBeInRange(NodeColor, 0, 1)} = zeros(0, 3) % RGB color of each node (n_node x 3).
        NodeLabel (:,1) string = strings(0, 1)                % Label of each node (default: its tag).
        NodeSize (:,1) double {mustBePositive} = zeros(0, 1)  % Size of each node (marker size; in 3D the radius is 0.004 pu per unit).
        NodeMarker (:,1) string = strings(0, 1)               % Marker of each node ("v" is a cone in 3D, other markers are spheres).
        NodeVisible (:,1) logical = false(0, 1)               % Show each node, its label and its |E| circle.
        EdgeColor (:,3) double {mustBeInRange(EdgeColor, 0, 1)} = zeros(0, 3) % RGB color of each spring (n_edge x 3).
        EdgeLineWidth (:,1) double {mustBePositive} = zeros(0, 1) % Line width of each spring.
        EdgeVisible (:,1) logical = false(0, 1)               % Show each spring.
    end
    properties (SetAccess = protected) % Data
        sct_data                                              % Data of the picture with the optional fields filled (without the appearance fields, see the class help). <@Type> struct
    end
    properties (Access = protected) % Rotation reference
        rv_angleMean                                          % [rad] Mean of the unwrapped bus angles at each sample.
    end

    methods
        function obj = GraphSpringBase(sct_data, opt)
        % Check the data, apply the options and draw the first sample.
            arguments (Input)
                sct_data (1,1) struct  % Data of the picture (see the class help).
                opt      (1,1) struct  % Name-Value options of the subclass constructor; Parent is the container or axes (see GraphBase.make_axes), other fields are copied to the properties.
            end
            arguments (Output)
                obj  % The picture.
            end
            obj.load_data(sct_data);
            obj.build(opt);
        end

        set_position(obj, sr_tag, rm_xy)
        sct_layout = get_layout(obj)
    end

    methods (Access = protected)
        load_data(obj, sct_data)
        update_scene(obj, k)
        tab = element_table(obj)
        sct_map = style_properties(obj)
        apply_selection(obj)
        sct_ctl = control_list(obj)
    end

    methods (Abstract, Access = protected) % Subclass contract
        % Move the graphics objects to sample k. cv_node holds the node phasors of sample k
        % turned by the rotation reference (see RotationScale). create_scene and
        % apply_style are those of GraphBase.
        draw_sample(obj, k, cv_node)
    end

    methods
        function set.RotationScale(obj, val)
            obj.RotationScale = val;
            redraw(obj);
        end
        function set.ArrowScaleP(obj, val)
            obj.ArrowScaleP = val;
            redraw(obj);
        end
        function set.ArrowScaleQ(obj, val)
            obj.ArrowScaleQ = val;
            redraw(obj);
        end
        function set.ShowLabel(obj, val)
            obj.ShowLabel = val;
            redraw(obj);
        end
        function set.ShowValue(obj, val)
            obj.ShowValue = val;
            redraw(obj);
        end
        function set.ShowLegend(obj, val)
            obj.ShowLegend = val;
            redraw(obj);
        end
        function set.SpringTurns(obj, val)
            obj.SpringTurns = val;
            redraw(obj);
        end
        function set.SpringAmplitude(obj, val)
            obj.SpringAmplitude = val;
            redraw(obj);
        end

        % Setters of the appearance of each element: draw the changed elements again
        function set.NodeColor(obj, val)
            check_size(obj, "node", val, "NodeColor");
            iv = changed_rows(obj.NodeColor, val);
            obj.NodeColor = val;
            restyle(obj, "node", iv);
        end
        function set.NodeLabel(obj, val)
            check_size(obj, "node", val, "NodeLabel");
            iv = changed_rows(obj.NodeLabel, val);
            obj.NodeLabel = val;
            restyle(obj, "node", iv);
        end
        function set.NodeSize(obj, val)
            check_size(obj, "node", val, "NodeSize");
            iv = changed_rows(obj.NodeSize, val);
            obj.NodeSize = val;
            restyle(obj, "node", iv);
        end
        function set.NodeMarker(obj, val)
            check_size(obj, "node", val, "NodeMarker");
            iv = changed_rows(obj.NodeMarker, val);
            obj.NodeMarker = val;
            restyle(obj, "node", iv);
        end
        function set.NodeVisible(obj, val)
            check_size(obj, "node", val, "NodeVisible");
            iv = changed_rows(obj.NodeVisible, val);
            obj.NodeVisible = val;
            restyle(obj, "node", iv);
        end
        function set.EdgeColor(obj, val)
            check_size(obj, "edge", val, "EdgeColor");
            iv = changed_rows(obj.EdgeColor, val);
            obj.EdgeColor = val;
            restyle(obj, "edge", iv);
        end
        function set.EdgeLineWidth(obj, val)
            check_size(obj, "edge", val, "EdgeLineWidth");
            iv = changed_rows(obj.EdgeLineWidth, val);
            obj.EdgeLineWidth = val;
            restyle(obj, "edge", iv);
        end
        function set.EdgeVisible(obj, val)
            check_size(obj, "edge", val, "EdgeVisible");
            iv = changed_rows(obj.EdgeVisible, val);
            obj.EdgeVisible = val;
            restyle(obj, "edge", iv);
        end
    end
end


function redraw(obj)
% Draw the current sample again once the picture exists (the linked graphs do not move).
    arguments (Input)
        obj  % The picture.
    end
    if ~isempty(obj.sct_plt) && all(isgraphics(obj.ax))
        obj.update_scene(obj.i_time);
        obj.apply_selection();
    end
end


function check_size(obj, s_kind, val, s_prop)
% Stop when a vector property does not have one row per element of its kind.
    arguments (Input)
        obj                  % The picture.
        s_kind (1,1) string  % "node" or "edge".
        val                  % New value of the property.
        s_prop (1,1) string  % Name of the property.
    end
    if isempty(obj.sct_data)
        return
    end
    if s_kind == "node"
        n = numel(obj.sct_data.sv_node);
    else
        n = size(obj.sct_data.im_edge, 2);
    end
    if size(val, 1) ~= n
        error(msg("GUILDA:GraphSpringBase:StyleSize", s_prop, n, size(val, 1)));
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


function restyle(obj, s_kind, iv_index)
% Draw the appearance of the elements iv_index of a kind again once the picture exists.
    arguments (Input)
        obj                    % The picture.
        s_kind (1,1) string    % "node" or "edge".
        iv_index (:,1) double  % Indices of the elements in the vectors of the kind.
    end
    if isempty(iv_index) || isempty(obj.sct_plt) || ~all(isgraphics(obj.ax))
        return
    end
    tab = obj.element_table();
    obj.apply_style(find(tab.Kind == s_kind & ismember(tab.Index, iv_index)));
end
