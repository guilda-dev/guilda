classdef (Abstract) GraphBase < auxiliary
% Abstract base class of the graphs of GUILDA: every plot_* returns a graph object.
%
% A graph draws data in one or more axes (panels) and keeps every later change in one
% place: the data and the time shown, the appearance of each element, and, in a free
% layout, its position. The same code then serves a picture and an animation.
%
% - Data: `set_data(sct_data)` replaces the data (the same contract as the data of the
%   constructor of the subclass) and keeps the appearance of the elements that still
%   exist (matched by tag and kind).
% - Time: `set_time(t)` shows the sample nearest to t; `animate` plays the samples and
%   `export_video` writes them to a video. Graphs joined by `link` follow `set_time`
%   (each at the nearest sample of its own times). The samples are times in seconds
%   unless the data names them: the optional fields `s_sampleName` (e.g. "Step") and
%   `sv_sampleText` (one text per sample, e.g. "Step 12 (λ = 0.734)") of the data of
%   every graph are shown in the playback bar and in the titles that show the
%   time. rv_t then holds the values of these samples (e.g. the step numbers), which
%   must still be nondecreasing; set_time(t), animate and export_video take them as they
%   take times (TimeStep is then a step of the sample values).
% - Elements: `tab_element` lists the elements (Tag, Kind, Index). Their appearance is held
%   in public vector properties of the subclass, one row per element of a kind (e.g.
%   NodeColor). `set_style(sr_tag, Name=Value)` writes the same vectors by tag, so the two
%   forms stay in sync, and only the changed elements are drawn again.
% - Positions: `set_position(sr_tag, rm_xy)` moves elements of a free layout
%   (GraphNetDiagram, GraphNetMap) and `get_layout()` returns the drawn positions in the
%   form of net.get_layout, so that net.set_layout(G.get_layout()) saves them. Other graphs
%   raise an error.
% - `reset_style(sr_tag)` returns the appearance of those elements (all with no argument)
%   to the defaults of the data.
% - Clicks: a click on an element raises the event ElementClicked and calls
%   ElementClickedFcn as fcn(G, data), with data a GraphEventData (Tag, Kind, Index).
% - Time changes: after set_time has drawn a graph (also a graph moved by link, and every
%   frame of animate and export_video), it raises the event TimeChanged and calls
%   TimeChangedFcn as fcn(G, data), with data a GraphTimeEventData (Time, Index of the
%   sample shown), e.g. to write a title or styles per time. build and set_data raise
%   nothing. A set_time called from these callbacks leaves the graphs of the set_time
%   that is running as they are, so a callback that moves a linked graph does not loop.
% - Selection: `select(sr_tag)` adds tags to Selection and `clear_selection()` empties it.
%   The selected elements (every element with a selected tag) are drawn with an overlay in
%   SelectionColor; the overlay does not change the appearance vectors, so clearing it
%   shows the appearance set before. The selection stays through set_time and set_data
%   (tags that disappear are dropped).
%
% Hook contract of a subclass (protected methods):
%
% - `load_data(sct_data)`: check the data, store it, set rv_t (1 x n_t), call
%   load_sample_label(sct_data) (the optional sample name and texts) and set the vector
%   properties of the appearance to the defaults of the data. It draws nothing: sct_plt is
%   empty while it runs, so the setters of the vector properties must not draw then.
% - `create_scene()`: draw the fixed parts in ax and create every graphics object of the
%   elements in sct_plt, with the appearance of the vector properties. Called after the
%   axes are set and after load_data, and again by the subclass when a property changes
%   the fixed parts. Called by set_data, sct_pltPrevious holds the drawing before, whose
%   objects it may reuse when they still fit the new data.
% - `update_scene(k)`: draw sample k (i_time is already k): move the graphics objects and
%   show the time, e.g. in the title or with a cursor line.
% - `apply_style(iv_element)`: draw again the appearance of the elements of the rows
%   iv_element of tab_element from the vector properties. The setters of the vector
%   properties call it with the changed rows once sct_plt exists.
% - `tab = element_table()`: the element table of the current data (columns Tag, Kind,
%   Index); tab_element returns it.
% - `sct_map = style_properties()`: for each kind, the set_style options that apply and the
%   vector property each writes, e.g. sct_map.node.Color = "NodeColor". A kind with no
%   options maps to struct().
% - `apply_selection()`: delete the previous selection overlay and draw a new one for the
%   elements whose tag is in Selection, in SelectionColor, at the positions shown. The
%   overlay must not take clicks (PickableParts "none"). The base calls it after
%   update_scene (build, set_time, set_data) and when Selection or SelectionColor changes;
%   a subclass that calls create_scene or update_scene itself (e.g. in a property setter)
%   calls it afterwards.
%
% Clicks: create_scene sets the ButtonDownFcn of the graphics objects of each element (or
% uses another hit test, such as the data tips) so that a click calls the protected
% `click_element(i_row)` of the base with the row of the element in tab_element.
%
% The constructor of a subclass loads its data, then calls build(opt, n_panel, rv_grid)
% with its Name-Value options: build sets ax with make_axes(opt.Parent, n_panel, rv_grid),
% copies the other options to the properties, calls create_scene and shows the first
% sample. Parent is a container (figure, uifigure, uipanel, uitab, uigridlayout; a tiled
% layout of rv_grid = [n_row n_col] tiles, default one column, is made in it and the
% n_panel axes fill it row by row), an axes or uiaxes (single-panel graphs only; a graph
% with several panels stops with GUILDA:GraphBase:ParentNeedsContainer), or empty (a new
% figure).
%
% Playback bar: a graph whose data has two or more samples (see has_playback) gets a bar
% below its axes when they are made in a container (a new figure, or the container given
% by Parent; not when Parent is an axes). The bar has a Play/Pause button, a time slider,
% the text of the sample shown (sample_text) and a dropdown of the playback speed
% (0.1x to 10x, the same as PlaySpeed; another value of PlaySpeed shows as an item of its
% own). The axes keep the space above it. The bar follows set_time (also through link),
% set_data (the slider takes the new samples; the bar appears or goes when the number of
% samples crosses two) and animate. Play (or `G.play()`) plays the samples from the one
% shown (from the first when the last is shown) by a timer, so MATLAB stays usable:
% PlaySpeed times real time (one sample value per second at 1 for samples named by the
% data). Pause (or `G.pause()`), closing the figure, deleting the axes or deleting the
% graph stops the timer and deletes it. As for FlowAnimation of GraphNetDiagram, no timer
% is made in matlab -batch or for a figure that is not visible: Play then does nothing
% (the slider still works). While a playback runs (also a blocking animate), the button
% shows Pause and Play starts nothing more.
% export_video and exportgraphics of the axes do not show the bar.
%
% Controls: `G.show_controls()` puts a panel of controls next to the axes (or in a given
% container, e.g. a cell of a GUI) and `G.hide_controls()` removes it. The panel is made
% from the declaration `control_list()` of the subclass (one row per control: a property
% and its widget) and only sets these properties: a change in the panel sets the
% property, and a change of the property (by code, set_style or another panel) updates
% the panel. The time is in the playback bar, not in the panel. No plot_* shows the panel
% by itself.
%
% `prepare_frame(r_dt)` (protected) is called by export_video before each frame with the
% time between frames [s], and with NaN after the last one; the default does nothing.
% `sample_text(k, s_format)` (protected) is the text of sample k for a title or the panel:
% the text of the data, the sample name and value, or sprintf(s_format, rv_t(k)).
%
% The protected static helpers set_arrow, place_label, resolve_overlap, write_frame and
% range_map (sizes and widths normalized into a range) are shared by the subclasses (the
% private functions of a class folder are not visible to its subclasses).
%
% <@Examples>
% ```matlab
% G = net.plot_spring_model();
% G.set_style(["B001", "B002"], Color="r", MarkerSize=20);
% G.NodeColor(3, :) = [0 0.5 0];       % the same as set_style by tag
% G.tab_element                         % Tag, Kind, Index of every element
% ```
%
% See also GraphSpringBase, GraphNetDiagram, GraphChart, GraphEventData, GraphTimeEventData

    events
        ElementClicked                                        % An element was clicked; the event data is a GraphEventData.
        TimeChanged                                           % set_time drew the graph (also through a link and in animate); the event data is a GraphTimeEventData.
    end

    properties % Time
        PlaySpeed (1,1) double {mustBePositive, mustBeFinite} = 1  % Playback speed relative to real time, of the Play button of the playback bar and of animate without Speed.
    end

    properties % Interaction
        ElementClickedFcn = []                                % Function called as fcn(G, data) when an element is clicked (data: GraphEventData); [] for none. <@Type> function_handle
        TimeChangedFcn = []                                   % Function called as fcn(G, data) after set_time drew the graph (data: GraphTimeEventData); [] for none. <@Type> function_handle
        SelectionColor = [1 176/255 0]                        % Color of the selection overlay (a color name, "#RRGGBB" or RGB; stored as RGB).
    end
    properties (SetAccess = private) % Interaction
        Selection (1,:) string = strings(1, 0)                % Tags of the selected elements.
    end

    properties (SetAccess = private) % Controls
        h_controls = gobjects(0)                              % Panel of controls of show_controls (a uipanel); empty when not shown. <@Type> matlab.ui.container.Panel
    end

    properties (SetAccess = protected) % Graphics
        ax = gobjects(0)                                      % Axes of the graph, one per panel. <@Type> matlab.graphics.axis.Axes
        sct_plt = struct.empty                                % Graphics objects of the graph, as a struct of handle arrays. <@Type> struct
    end
    properties (Access = protected) % Graphics
        sct_pltPrevious = struct.empty                        % During create_scene of set_data: sct_plt of the drawing before (a subclass may reuse its objects); empty otherwise. <@Type> struct
    end
    properties (SetAccess = protected) % Time
        rv_t = 0                                              % Times of the samples (1 x n_t) [s], or the values of other samples (e.g. the steps of a continuation power flow).
        i_time = 1                                            % Index of the sample shown.
    end
    properties (Access = protected) % Time
        s_sampleName (1,1) string = ""                        % Name of the samples from the data (e.g. "Step"); "": times in seconds.
        sv_sampleText (1,:) string = strings(1, 0)            % Text of each sample from the data (1 x n_t); empty: see sample_text.
    end
    properties (Dependent, SetAccess = private) % Elements
        tab_element                                           % Elements of the graph: Tag, Kind and Index (position in the vector properties of its kind). <@Type> table
    end
    properties (Access = private) % Links
        c_link = {}                                           % Graphs linked to this one (handles; deleted graphs are dropped when read).
        l_timeFixed (1,1) logical = false                     % The TimeChanged callbacks of a set_time that drew this graph are running: set_time leaves it.
    end
    properties (Access = private) % Defaults of the appearance
        sct_styleDefault = struct()                           % Appearance vectors of the data defaults, by property name (for reset_style).
    end
    properties (Access = private) % Controls
        l_stopAnimate (1,1) logical = false                   % The pause button of the playback bar asks animate to stop at the next frame.
        l_animating (1,1) logical = false                     % animate or the timer of the bar is playing the samples (the play button shows Pause).
    end
    properties (Access = private) % Playback bar
        h_bar = gobjects(0)                                   % Playback bar below the axes (a uipanel); empty when the graph has none. <@Type> matlab.ui.container.Panel
        h_playTimer = []                                      % Timer of the playback started by the Play button of the bar; [] when it does not run. <@Type> timer
        r_playFrom (1,1) double = 0                           % Sample value at which the timer playback was (re)started.
        u_playTic = uint64(0)                                 % tic of the (re)start of the timer playback.
        lis_playAxes = []                                     % Listener that stops the timer when the axes are deleted. <@Type> event.listener
    end

    methods
        set_time(obj, t)
        set_data(obj, sct_data)
        set_style(obj, sr_tag, opt)
        set_position(obj, sr_tag, rm_xy)
        sct_layout = get_layout(obj)
        animate(obj, opt)
        play(obj)
        pause(obj)
        export_video(obj, s_file, opt)
        link(obj, G_other)
        unlink(obj, G_other)
        reset_style(obj, sr_tag)
        select(obj, sr_tag)
        clear_selection(obj)
        h_panel = show_controls(obj, opt)
        hide_controls(obj)

        function set.ElementClickedFcn(obj, fcn)
            arguments (Input)
                obj
                fcn  % Function handle or [].
            end
            if ~(isempty(fcn) || isa(fcn, "function_handle"))
                error(msg("GUILDA:GraphBase:ClickFcn", class(fcn)));
            end
            obj.ElementClickedFcn = fcn;
        end

        function set.PlaySpeed(obj, val)
            arguments (Input)
                obj
                val (1,1) double  % Playback speed relative to real time.
            end
            if ~isempty(obj.h_playTimer) %#ok<MCSUP> % a running playback goes on from where it is at the new speed
                obj.r_playFrom = obj.r_playFrom + toc(obj.u_playTic) * obj.PlaySpeed; %#ok<MCSUP>
                obj.u_playTic  = tic; %#ok<MCSUP>
            end
            obj.PlaySpeed = val;
            obj.refresh_bar();
        end

        function set.TimeChangedFcn(obj, fcn)
            arguments (Input)
                obj
                fcn  % Function handle or [].
            end
            if ~(isempty(fcn) || isa(fcn, "function_handle"))
                error(msg("GUILDA:GraphBase:TimeFcn", class(fcn)));
            end
            obj.TimeChangedFcn = fcn;
        end

        function set.SelectionColor(obj, val)
            arguments (Input)
                obj
                val  % Color name, "#RRGGBB" or RGB triplet.
            end
            try
                val = validatecolor(val);
            catch
                error(msg("GUILDA:GraphBase:StyleValue", "SelectionColor", "a color name, ""#RRGGBB"" or an RGB triplet"));
            end
            obj.SelectionColor = val;
            if ~isempty(obj.sct_plt) && ~isempty(obj.ax) && all(isgraphics(obj.ax)) %#ok<MCSUP>
                obj.apply_selection();
            end
        end

        function tab = get.tab_element(obj)
            arguments (Input)
                obj
            end
            arguments (Output)
                tab table  % Tag, Kind and Index of every element.
            end
            tab = obj.element_table();
        end
    end

    methods (Access = protected)
        build(obj, opt, n_panel, rv_grid)
        hv_ax = make_axes(obj, h_parent, n_panel, rv_grid)
        click_element(obj, i_row)
        sct_ctl = control_list(obj)
        prepare_frame(obj, r_dt)
        load_sample_label(obj, sct_data)
        s = sample_text(obj, k, s_format)
        l = has_playback(obj)
    end

    methods (Access = private)
        refresh_controls(obj)
        refresh_bar(obj)
        place_bar(obj, l_hide)
        play_bar(obj, l_play)
    end

    methods (Abstract, Access = protected) % Subclass contract (see the class help)
        load_data(obj, sct_data)
        create_scene(obj)
        update_scene(obj, k)
        apply_style(obj, iv_element)
        tab = element_table(obj)
        sct_map = style_properties(obj)
        apply_selection(obj)
    end

    methods (Static, Access = protected)
        set_arrow(hv_arrow, rv_start, rv_vector, r_head)
        place_label(h_text, rv_start, rv_direction, r_length, s_text, r_value)
        rm_box = resolve_overlap(hv_move, hv_fix, n_iter, r_pad, rm_box)
        iv_size = write_frame(vw, h_capture, iv_size, n_repeat)
        rv_w = range_map(rv_v, rv_range, rv_lim)
    end
end
