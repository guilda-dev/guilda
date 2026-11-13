classdef GraphSpring3D < GraphSpringBase
% Spring-mass picture of a power system on the surface z = log|V|.
%
% Each node with phasor $V = |V| e^{j\theta}$ sits at
% $(|V|\cos\theta, |V|\sin\theta, \log|V|)$ on a translucent surface of revolution that
% runs from RMin to RMax, with contour circles of constant |V|, a polar grid on the floor
% and a pillar on the z axis. |V| below RMin is drawn at RMin. Rods join the axis to the
% component nodes, 3D coils join the nodes, and the nodes are spheres (cones for the
% marker "v"). At each arrow node the active power P points along the circle of constant
% |V| and the reactive-current magnitude Iq along the surface away from the axis. Dashed
% circles of radius |E| lie on the surface. The camera is fixed so that the picture keeps
% its size for any azimuth. See GraphSpringBase for the data and the common properties
% and methods.
%
% Defaults that differ from GraphSpring2D: ShowLabel and ShowValue are false,
% SpringTurns is 1/0.09 turns per pu of length and SpringAmplitude is a coil radius of
% 0.013 pu.
%
% <@Examples>
% ```matlab
% G = GraphSpring3D(sct_data, View=[-30 40]);   % sct_data: see GraphSpringBase
% G.set_time(2.5);
% ```
%
% See also GraphSpringBase, GraphSpring2D

    properties % Appearance
        RMin (1,1) double {mustBePositive} = 0.02                                                     % [pu] Smallest |V| of the surface (its bottom).
        RMax (1,1) double {mustBePositive} = 1.70                                                     % [pu] Largest |V| of the surface.
        SurfaceAlpha (1,1) double {mustBeNonnegative, mustBeLessThanOrEqual(SurfaceAlpha, 1)} = 0.40  % Opacity of the surface.
        ContourCount (1,1) double {mustBeNonnegative, mustBeInteger} = 12                             % Number of contour circles of constant |V|, evenly spaced in z.
        View (1,2) double = [-20 50]                                                                  % [deg] Azimuth and elevation of the camera.
    end

    methods
        function obj = GraphSpring3D(sct_data, opt)
        % Create the picture and draw the first sample.
            arguments (Input)
                sct_data (1,1) struct   % Data of the picture (see GraphSpringBase).
                opt.?GraphSpring3D      % Name-Value options; each field is copied to the property of the same name.
                opt.Parent = []         % Axes to draw in; [] for new axes in a new figure. <@Type> matlab.graphics.axis.Axes
            end
            arguments (Output)
                obj % The picture.
            end
            sct_default = struct("ShowLabel", false, "ShowValue", false, "SpringTurns", 1/0.09, "SpringAmplitude", 0.013);
            for s_field = string(fieldnames(sct_default))'
                if ~isfield(opt, s_field)
                    opt.(s_field) = sct_default.(s_field);
                end
            end
            obj@GraphSpringBase(sct_data, opt);
        end

        function set.RMin(obj, val)
            obj.RMin = val;
            rebuild(obj);
        end
        function set.RMax(obj, val)
            obj.RMax = val;
            rebuild(obj);
        end
        function set.SurfaceAlpha(obj, val)
            obj.SurfaceAlpha = val;
            rebuild(obj);
        end
        function set.ContourCount(obj, val)
            obj.ContourCount = val;
            rebuild(obj);
        end
        function set.View(obj, val)
            obj.View = val;
            rebuild(obj);
        end
    end

    methods (Access = protected)
        create_scene(obj)
        update_scene(obj, k, cv_node)
    end
end


function rebuild(obj)
% Draw the fixed parts and the current sample again once the picture exists.
    arguments (Input)
        obj % The picture.
    end
    if ~isempty(obj.sct_plt) && isgraphics(obj.ax)
        obj.create_scene();
        obj.set_time(obj.sct_data.rv_t(obj.i_time));
    end
end
