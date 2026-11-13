classdef (Abstract) GraphSpringBase < auxiliary
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
% - `rv_t` (1 x n_t) [s]: times.
% - `sv_node` (n_node x 1): node tags; `sv_kind` (n_node x 1): "bus" or "component".
% - `cm_V` (n_node x n_t) [pu]: node phasors over time.
% - `im_edge` (2 x n_edge): node indices of each spring; `sv_edge` (n_edge x 1): their
%   tags (optional).
% - `iv_arrow` (n_arrow x 1): the node of each arrow pair; `rm_P`, `rm_Iq`
%   (n_arrow x n_t) [pu]: active power and reactive-current magnitude (optional).
% - `sv_marker` (MATLAB marker; "v" is a cone in 3D, other markers are spheres),
%   `rv_size` (NaN: default of the kind), `sv_color` ("": default of the kind; a color
%   name or "#RRGGBB") and `rv_circle` [pu] (radius of a dashed |E| circle; NaN: none),
%   n_node x 1 each (optional).
%
% The common rotation of the buses is removed by `RotationScale`: the angle reference at
% sample k is $\bar\theta_1 + (1-s)(\bar\theta_k - \bar\theta_1)$, where
% $\bar\theta_k$ is the mean of the unwrapped bus angles and s is RotationScale. s = 1
% keeps the actual rotation (only the initial mean is removed), s = 0 removes it at every
% sample. Changing a property redraws the current sample.
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
% ```
%
% The data of a network or of an analysis result is assembled by
% PowerNetwork.plot_spring_model (the equilibrium), ResultODE.plot_spring_model (all
% output times, for animate and export_video) and ResultPF.plot_spring_model (the buses).
%
% See also GraphSpring2D, GraphSpring3D, PowerNetwork.plot_spring_model, ResultODE.plot_spring_model, ResultPF.plot_spring_model

    properties % Appearance
        RotationScale (1,1) double = 1                        % Share of the common rotation of the buses that is shown: 1 the actual rotation, 0 none.
        ArrowScaleP (1,1) double = 0.30                       % [1/pu] Length of the active power arrow per unit of P.
        ArrowScaleQ (1,1) double = 0.30                       % [1/pu] Length of the reactive-current arrow per unit of Iq.
        ShowLabel (1,1) logical = true                        % Show the node tags.
        ShowValue (1,1) logical = true                        % Show the values of P and Iq next to the arrows.
        ShowLegend (1,1) logical = true                       % Show the legend of the arrows.
        SpringTurns (1,1) double {mustBePositive} = 5         % Coil turns: per spring (2D) or per unit of spring length (3D).
        SpringAmplitude (1,1) double {mustBePositive} = 0.06  % Coil amplitude: ratio to the spring length (2D) or coil radius in pu (3D).
    end
    properties (SetAccess = protected) % Data
        sct_data                                              % Data of the picture with the optional fields filled and the colors as RGB (rm_color, n_node x 3). <@Type> struct
        i_time = 1                                            % Index of the sample shown.
    end
    properties (SetAccess = protected) % Graphics
        ax                                                    % Axes of the picture. <@Type> matlab.graphics.axis.Axes
        sct_plt = struct.empty                                % Graphics objects of the picture, as a struct of handle arrays. <@Type> struct
    end
    properties (Access = protected) % Rotation reference
        rv_angleMean                                          % [rad] Mean of the unwrapped bus angles at each sample.
    end

    methods
        function obj = GraphSpringBase(sct_data, opt)
        % Check the data, apply the options and draw the first sample.
            arguments (Input)
                sct_data (1,1) struct % Data of the picture (see the class help).
                opt      (1,1) struct % Name-Value options of the subclass constructor; Parent is the axes, other fields are copied to the properties.
            end
            arguments (Output)
                obj % The picture.
            end
            sv_required = ["rv_t", "sv_node", "sv_kind", "cm_V", "im_edge"];
            for s_field = sv_required
                if ~isfield(sct_data, s_field)
                    error(msg("GUILDA:GraphSpringBase:MissingField", s_field));
                end
            end
            rv_t = sct_data.rv_t;
            if ~(isnumeric(rv_t) && isreal(rv_t) && isvector(rv_t) && all(isfinite(rv_t)) && all(diff(rv_t) >= 0))
                error(msg("GUILDA:GraphSpringBase:FieldValue", "rv_t", "finite nondecreasing real times"));
            end
            sv_node = string(sct_data.sv_node(:));
            n_node  = numel(sv_node);
            n_t     = numel(rv_t);
            sv_kind = string(sct_data.sv_kind(:));
            if numel(sv_kind) ~= n_node
                error(msg("GUILDA:GraphSpringBase:FieldSize", "sv_kind", n_node + "x1", size_text(sct_data.sv_kind)));
            end
            if ~all(ismember(sv_kind, ["bus", "component"]))
                error(msg("GUILDA:GraphSpringBase:FieldValue", "sv_kind", """bus"" or ""component"""));
            end
            cm_V = sct_data.cm_V;
            if ~isnumeric(cm_V) || ~isequal(size(cm_V), [n_node, n_t])
                error(msg("GUILDA:GraphSpringBase:FieldSize", "cm_V", n_node + "x" + n_t, size_text(cm_V)));
            end
            im_edge = sct_data.im_edge;
            if isempty(im_edge)
                im_edge = zeros(2, 0);
            end
            if size(im_edge, 1) ~= 2
                error(msg("GUILDA:GraphSpringBase:FieldSize", "im_edge", "2xn_edge", size_text(im_edge)));
            end
            if ~is_index(im_edge, n_node)
                error(msg("GUILDA:GraphSpringBase:FieldValue", "im_edge", "node indices from 1 to " + n_node));
            end
            n_edge = size(im_edge, 2);

            % Optional fields: their size, then the defaults
            sct_default = struct( ...
                "sv_edge",   strings(n_edge, 1), ...
                "iv_arrow",  zeros(0, 1), ...
                "sv_marker", repmat("o", n_node, 1), ...
                "rv_size",   nan(n_node, 1), ...
                "sv_color",  strings(n_node, 1), ...
                "rv_circle", nan(n_node, 1));
            for s_field = string(fieldnames(sct_default))'
                if ~isfield(sct_data, s_field) || isempty(sct_data.(s_field))
                    sct_data.(s_field) = sct_default.(s_field);
                end
                n_need = numel(sct_default.(s_field));
                if s_field ~= "iv_arrow" && numel(sct_data.(s_field)) ~= n_need
                    error(msg("GUILDA:GraphSpringBase:FieldSize", s_field, n_need + "x1", size_text(sct_data.(s_field))));
                end
            end
            iv_arrow = sct_data.iv_arrow(:);
            if ~is_index(iv_arrow, n_node)
                error(msg("GUILDA:GraphSpringBase:FieldValue", "iv_arrow", "node indices from 1 to " + n_node));
            end
            n_arrow = numel(iv_arrow);
            for s_field = ["rm_P", "rm_Iq"]
                if ~isfield(sct_data, s_field) || n_arrow == 0 && isempty(sct_data.(s_field))
                    sct_data.(s_field) = zeros(n_arrow, n_t);
                end
                if ~(isnumeric(sct_data.(s_field)) && isreal(sct_data.(s_field))) || ~isequal(size(sct_data.(s_field)), [n_arrow, n_t])
                    error(msg("GUILDA:GraphSpringBase:FieldSize", s_field, "real " + n_arrow + "x" + n_t, size_text(sct_data.(s_field))));
                end
            end

            % Defaults by kind: bus small and black, component larger and blue
            l_bus   = sv_kind == "bus";
            rv_size = double(sct_data.rv_size(:));
            rv_size(isnan(rv_size) &  l_bus) = 5;
            rv_size(isnan(rv_size) & ~l_bus) = 15;
            sv_color = string(sct_data.sv_color(:));
            sv_color(ismissing(sv_color)) = "";
            rm_color = zeros(n_node, 3);
            rm_color(~l_bus, :) = repmat([0 0.447 0.741], nnz(~l_bus), 1);
            for i_node = find(sv_color ~= "")'
                try
                    rm_color(i_node, :) = validatecolor(sv_color(i_node));
                catch
                    error(msg("GUILDA:GraphSpringBase:FieldValue", "sv_color", "a color name or ""#RRGGBB"", not """ + sv_color(i_node) + """"));
                end
            end
            sv_marker = string(sct_data.sv_marker(:));
            sv_marker(ismissing(sv_marker) | sv_marker == "") = "o";

            obj.sct_data = struct( ...
                "rv_t",      reshape(double(rv_t), 1, []), ...
                "sv_node",   sv_node, ...
                "sv_kind",   sv_kind, ...
                "cm_V",      double(cm_V), ...
                "im_edge",   double(im_edge), ...
                "sv_edge",   string(sct_data.sv_edge(:)), ...
                "iv_arrow",  double(iv_arrow), ...
                "rm_P",      double(sct_data.rm_P), ...
                "rm_Iq",     double(sct_data.rm_Iq), ...
                "sv_marker", sv_marker, ...
                "rv_size",   rv_size, ...
                "sv_color",  sv_color, ...
                "rm_color",  rm_color, ...
                "rv_circle", double(sct_data.rv_circle(:)));
            if ~any(l_bus)
                l_bus(:) = true;
            end
            obj.rv_angleMean = mean(unwrap(angle(obj.sct_data.cm_V(l_bus, :)), [], 2), 1);

            % Axes and options
            if ~isfield(opt, "Parent") || isempty(opt.Parent)
                obj.ax = axes(figure("Color", "w"));
            elseif isa(opt.Parent, "matlab.graphics.axis.Axes")
                obj.ax = opt.Parent;
            else
                error(msg("GUILDA:GraphSpringBase:ParentNotAxes", class(opt.Parent)));
            end
            for s_field = setdiff(string(fieldnames(opt))', "Parent")
                obj.(s_field) = opt.(s_field);
            end

            obj.create_scene();
            obj.set_time(obj.sct_data.rv_t(1));
        end

        set_time(obj, t)
        animate(obj, opt)
        export_video(obj, s_file, opt)
    end

    methods (Abstract, Access = protected) % Subclass contract
        % Draw the fixed parts of the picture and create the graphics objects of the nodes,
        % springs, arrows and labels in obj.sct_plt (with no data yet). Called again when a
        % property that changes the fixed parts is set.
        create_scene(obj)
        % Move the graphics objects to sample k. cv_node holds the node phasors of sample k
        % turned by the rotation reference (see RotationScale).
        update_scene(obj, k, cv_node)
    end

    methods (Static, Access = protected)
        set_arrow(hv_arrow, rv_start, rv_vector, r_head)
        place_label(h_text, rv_start, rv_direction, r_length, s_text, r_value)
        resolve_overlap(hv_move, hv_fix, n_iter, r_pad)
        iv_size = write_frame(vw, h_capture, iv_size, n_repeat)
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
    end
end


function redraw(obj)
% Draw the current sample again once the picture exists.
    arguments (Input)
        obj % The picture.
    end
    if ~isempty(obj.sct_plt) && isgraphics(obj.ax)
        obj.set_time(obj.sct_data.rv_t(obj.i_time));
    end
end


function s = size_text(x)
% Size of x as text, e.g. "3x2".
    arguments (Input)
        x % Any value.
    end
    arguments (Output)
        s (1,1) string % Its size.
    end
    s = join(string(size(x)), "x");
end


function l = is_index(x, n)
% True when x holds only integer indices from 1 to n.
    arguments (Input)
        x    % Values to check.
        n (1,1) double % Largest index.
    end
    arguments (Output)
        l (1,1) logical % True for valid indices.
    end
    l = isnumeric(x) && all(x(:) == round(x(:))) && all(x(:) >= 1 & x(:) <= n);
end
