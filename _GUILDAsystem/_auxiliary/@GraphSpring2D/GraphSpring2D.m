classdef GraphSpring2D < GraphSpringBase
% Spring-mass picture of a power system on the phasor plane.
%
% Each node is drawn at its phasor (Re V, Im V) over a polar grid up to RMax: the buses
% and the own nodes of components, joined by coil springs (branches and the reactances
% to the own nodes) whose loops have the same small radius SpringAmplitude (0.02 pu) on
% every spring. At each arrow node the active power P points along the tangent
% (counterclockwise for P > 0) and the reactive-current magnitude Iq along the radius.
% Dashed circles of radius |E| mark the nodes whose |E| is constant. Value labels are
% pushed apart when they overlap. The radius labels lie on the 165 degree ray, between the
% angle labels. The tick labels of the grid are thinned out so that none overlaps another
% (angle labels every 30, 60 or 90 degrees, then the radius labels from the outermost), and
% a label that touches a node, a spring or an arrow of the sample is hidden. They lie below
% the data and are chosen again when the axes change size, limits or font size and at each
% sample; a tick label hidden by the user stays hidden. ShowTickLabel = false hides all of
% them (e.g. for a picture whose grid only shows the scale). See GraphSpringBase for the
% data and the common properties and methods.
%
% <@Examples>
% ```matlab
% G = GraphSpring2D(sct_data);                 % sct_data: see GraphSpringBase
% G.RotationScale = 0;                         % remove the common rotation
% G.animate(Speed=0.5);
% G.export_video("swing.mp4");
% G.set_style("B001", Color="r", MarkerSize=20);
% ```
%
% See also GraphBase, GraphSpringBase, GraphSpring3D

    properties % Appearance
        RMax (1,1) double {mustBePositive} = 1.5  % [pu] Largest radius of the polar grid.
        ShowTickLabel (1,1) logical = true        % Show the angle and radius labels of the polar grid.
    end

    methods
        function obj = GraphSpring2D(sct_data, opt)
        % Create the picture and draw the first sample.
            arguments (Input)
                sct_data (1,1) struct  % Data of the picture (see GraphSpringBase).
                opt.?GraphSpring2D     % Name-Value options; each field is copied to the property of the same name.
                opt.Parent = []        % Container (figure, uifigure, uipanel, uitab, uigridlayout) or axes/uiaxes to draw in; [] for a new figure.
            end
            arguments (Output)
                obj  % The picture.
            end
            obj@GraphSpringBase(sct_data, opt);
        end

        function set.RMax(obj, val)
            obj.RMax = val;
            if ~isempty(obj.sct_plt) && all(isgraphics(obj.ax))
                obj.create_scene();
                obj.update_scene(obj.i_time);
                obj.apply_selection();
            end
        end

        function set.ShowTickLabel(obj, val)
            obj.ShowTickLabel = val;
            if ~isempty(obj.sct_plt) && all(isgraphics(obj.ax)) %#ok<MCSUP>
                obj.create_scene();
                obj.update_scene(obj.i_time);
                obj.apply_selection();
            end
        end
    end

    methods (Access = protected)
        create_scene(obj)
        apply_style(obj, iv_element)
        draw_sample(obj, k, cv_node)
    end
end
