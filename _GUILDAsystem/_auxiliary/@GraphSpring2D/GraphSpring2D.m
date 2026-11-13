classdef GraphSpring2D < GraphSpringBase
% Spring-mass picture of a power system on the phasor plane.
%
% Each node is drawn at its phasor (Re V, Im V) over a polar grid up to RMax: the buses
% and the own nodes of components, joined by coil springs (branches and the reactances
% to the own nodes). At each arrow node the active power P points along the tangent
% (counterclockwise for P > 0) and the reactive-current magnitude Iq along the radius.
% Dashed circles of radius |E| mark the nodes whose |E| is constant. Value labels are
% pushed apart when they overlap. See GraphSpringBase for the data and the common
% properties and methods.
%
% <@Examples>
% ```matlab
% G = GraphSpring2D(sct_data);                 % sct_data: see GraphSpringBase
% G.RotationScale = 0;                         % remove the common rotation
% G.animate(Speed=0.5);
% G.export_video("swing.mp4");
% ```
%
% See also GraphSpringBase, GraphSpring3D

    properties % Appearance
        RMax (1,1) double {mustBePositive} = 1.5  % [pu] Largest radius of the polar grid.
    end

    methods
        function obj = GraphSpring2D(sct_data, opt)
        % Create the picture and draw the first sample.
            arguments (Input)
                sct_data (1,1) struct   % Data of the picture (see GraphSpringBase).
                opt.?GraphSpring2D      % Name-Value options; each field is copied to the property of the same name.
                opt.Parent = []         % Axes to draw in; [] for new axes in a new figure. <@Type> matlab.graphics.axis.Axes
            end
            arguments (Output)
                obj % The picture.
            end
            obj@GraphSpringBase(sct_data, opt);
        end

        function set.RMax(obj, val)
            obj.RMax = val;
            if ~isempty(obj.sct_plt) && isgraphics(obj.ax)
                obj.create_scene();
                obj.set_time(obj.sct_data.rv_t(obj.i_time));
            end
        end
    end

    methods (Access = protected)
        create_scene(obj)
        update_scene(obj, k, cv_node)
    end
end
