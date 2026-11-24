function refresh_bar(obj)
% Make, update or remove the playback bar below the axes.
%
% The graph has a bar when has_playback is true and its axes are in a tiled layout made by
% make_axes (a new figure or the container given by Parent; not an axes given by Parent).
% The bar (a uipanel, Tag "GUILDA:GraphBase:PlaybackBar", in the container of the tiled
% layout, with a uigridlayout "GUILDA:GraphBase:PlaybackGrid") holds the Play/Pause state button (Tag "GUILDA:GraphBase:Play"), the time slider
% ("GUILDA:GraphBase:TimeSlider", one step per sample), the text of the sample shown
% ("GUILDA:GraphBase:TimeText", sample_text) and the speed dropdown
% ("GUILDA:GraphBase:PlaySpeed", ItemsData the speeds; a PlaySpeed not in the list is
% added as an item). Called by build, set_time, set_data, animate, the playback and the
% setter of PlaySpeed. A bar that is no longer needed (set_data to one sample) is deleted
% and the axes take back its place.
    arguments (Input)
        obj
    end
    if isempty(obj.ax) || ~all(isgraphics(obj.ax)) || any([obj.ax.BeingDeleted] == "on")
        return
    end
    fig = ancestor(obj.ax(1), "figure");
    if isempty(fig) || fig.BeingDeleted == "on"    % the figure is closing: no new bar
        return
    end
    h_bar = obj.h_bar;
    l_has = ~isempty(h_bar) && isgraphics(h_bar);
    tl    = obj.ax(1).Parent;
    l_want = obj.has_playback() && isa(tl, "matlab.graphics.layout.TiledChartLayout");
    if ~l_want
        if l_has
            delete(h_bar);
            tl.Units = "normalized";
            rv_pos = tl.OuterPosition;
            tl.OuterPosition = [rv_pos(1), 0, rv_pos(3), 1];
        end
        obj.h_bar = gobjects(0);
        return
    end
    if ~l_has
        h_bar = make_bar(obj, tl);
        obj.h_bar = h_bar;
        obj.place_bar();
    end

    % The widgets follow the samples, the sample shown, the playback and the speed
    sct = h_bar.UserData;
    n_t = numel(obj.rv_t);
    if ~isequal(sct.slider.Limits, [1 n_t])
        sct.slider.Limits = [1 n_t];
    end
    if sct.slider.Value ~= obj.i_time
        sct.slider.Value = obj.i_time;
    end
    s_text = obj.sample_text(obj.i_time, "t = %.4g s");
    if string(sct.text.Text) ~= s_text
        sct.text.Text = s_text;
    end
    s_play = "Play";
    if obj.l_animating
        s_play = "Pause";
    end
    if sct.button.Value ~= obj.l_animating || string(sct.button.Text) ~= s_play
        sct.button.Value = obj.l_animating;
        sct.button.Text  = s_play;
    end
    r_speed = obj.PlaySpeed;
    if ~isequal(sct.speed.Value, r_speed)
        rv_data = [sct.rv_speed, r_speed];
        if ~ismember(r_speed, sct.rv_speed)     % a value of its own: listed after the choices
            sct.speed.Items     = [speed_text(sct.rv_speed), speed_text(r_speed)];
            sct.speed.ItemsData = rv_data;
        elseif numel(sct.speed.ItemsData) ~= numel(sct.rv_speed)
            sct.speed.Items     = speed_text(sct.rv_speed);
            sct.speed.ItemsData = sct.rv_speed;
        end
        sct.speed.Value = r_speed;
    end
end


function h_bar = make_bar(obj, tl)
% The bar with its widgets in the container of the tiled layout tl; it is placed again
% (place_bar, hidden or shown as it is) when the container sends SizeChanged and each time tl
% is drawn, so that it keeps its height in pixels when the container is resized.
    arguments (Input)
        obj
        tl  % Tiled layout of the axes. <@Type> matlab.graphics.layout.TiledChartLayout
    end
    arguments (Output)
        h_bar  % The bar. <@Type> matlab.ui.container.Panel
    end
    h_host = tl.Parent;
    rv_speed = [0.1 0.25 0.5 1 2 5 10];
    wr = matlab.lang.WeakReference(obj);     % the callbacks hold the graph weakly (savefig; build keeps it alive)
    h_bar = uipanel(h_host, "Units", "normalized", "Position", [0 0 1 0.05], "BorderType", "none", ...
        "Tag", "GUILDA:GraphBase:PlaybackBar");
    if isprop(h_host, "Color")
        h_bar.BackgroundColor = h_host.Color;
    elseif isprop(h_host, "BackgroundColor")
        h_bar.BackgroundColor = h_host.BackgroundColor;
    end
    gl = uigridlayout(h_bar, [1 4], "ColumnWidth", {64, "1x", "fit", 72}, "RowHeight", {"1x"}, ...
        "Padding", [6 3 6 3], "ColumnSpacing", 8, "BackgroundColor", h_bar.BackgroundColor, ...
        "Tag", "GUILDA:GraphBase:PlaybackGrid");
    h_button = uibutton(gl, "state", "Text", "Play", "Tag", "GUILDA:GraphBase:Play", ...
        "Tooltip", "Play the samples from the one shown; Pause stops", ...
        "ValueChangedFcn", @(h, ~) call_weak(wr, @(G) on_play(G, h)));
    h_slider = uislider(gl, "Limits", [1 2], "MajorTicks", [], "MinorTicks", [], ...
        "Tag", "GUILDA:GraphBase:TimeSlider", ...
        "ValueChangingFcn", @(~, evt) call_weak(wr, @(G) on_slide(G, evt.Value)), ...
        "ValueChangedFcn", @(h, ~) call_weak(wr, @(G) on_slide(G, h.Value)));
    h_text = uilabel(gl, "Text", "", "Tag", "GUILDA:GraphBase:TimeText");
    h_speed = uidropdown(gl, "Items", speed_text(rv_speed), "ItemsData", rv_speed, "Value", 1, ...
        "Tag", "GUILDA:GraphBase:PlaySpeed", "Tooltip", "Playback speed (PlaySpeed)", ...
        "ValueChangedFcn", @(h, ~) call_weak(wr, @(G) on_speed(G, h)));
    fcn_place = @(~, ~) call_weak(wr, @(G) G.place_bar(isvalid(h_bar) && h_bar.Visible == "off"));
    lis = [listener(h_host, "SizeChanged", fcn_place), listener(tl, "MarkedClean", fcn_place)];
    h_bar.UserData = struct("button", h_button, "slider", h_slider, "text", h_text, "speed", h_speed, ...
        "rv_speed", rv_speed, "lis_place", lis);
end


function on_play(obj, h_button)
% Start the playback of the bar, or stop the playback that runs (the timer or animate).
    arguments (Input)
        obj        % The graph.
        h_button   % The play button (a state button).
    end
    if h_button.Value
        if ~obj.l_animating
            obj.play_bar(true);
        end
    elseif ~isempty(obj.h_playTimer)
        obj.play_bar(false);
    elseif obj.l_animating
        obj.l_stopAnimate = true;       % animate stops at its next frame
    end
    obj.refresh_bar();
end


function on_slide(obj, r_value)
% Show the sample of the slider position.
    arguments (Input)
        obj                   % The graph.
        r_value (1,1) double  % Position of the slider (a sample index, not rounded).
    end
    k = min(max(round(r_value), 1), numel(obj.rv_t));
    if k ~= obj.i_time
        obj.set_time(obj.rv_t(k));
    end
end


function on_speed(obj, h_speed)
% Set PlaySpeed from the dropdown.
    arguments (Input)
        obj       % The graph.
        h_speed   % The speed dropdown.
    end
    obj.PlaySpeed = h_speed.Value;
end


function sv = speed_text(rv_speed)
% Texts of the speeds, e.g. "0.25×".
    arguments (Input)
        rv_speed (1,:) double  % Speeds.
    end
    arguments (Output)
        sv (1,:) string  % Texts.
    end
    sv = compose("%g×", rv_speed);
end


function call_weak(wr, fcn)
% Call fcn(G) with the graph G held by the weak reference wr (nothing once it is deleted).
    arguments (Input)
        wr   % Weak reference to the graph. <@Type> matlab.lang.WeakReference
        fcn  % Function called as fcn(G). <@Type> function_handle
    end
    G = wr.Handle;
    if ~isempty(G) && isvalid(G)
        fcn(G);
    end
end
