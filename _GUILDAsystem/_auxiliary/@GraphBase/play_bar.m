function play_bar(obj, l_play)
% Start or stop the playback of the Play button of the bar (a timer).
%
% l_play true plays from the sample shown (from the first when the last is shown): a timer
% (Tag "GUILDA:GraphBase:Playback", every 0.04 s) shows at each tick the sample at
% r_playFrom + PlaySpeed x (real time since the start), and stops at the last sample. It
% holds the graph by a weak reference only and stops and deletes itself when the graph or
% its axes are gone, or its figure is missing or being deleted; a listener on the axes stops
% it when they are deleted (the figure closed), and build stops it when the graph is
% deleted. A tick can still run while a window closes (MATLAB runs queued timer callbacks
% during the deletion); an error in such a tick stops the timer without a warning, and an
% error while the figure is alive stops it with the warning GUILDA:GraphBase:PlaybackTimer.
% l_play false stops and deletes the timer. Nothing starts while a playback (the timer or animate) runs, in matlab -batch,
% or when the figure is not visible (the rule of FlowAnimation of GraphNetDiagram).
    arguments (Input)
        obj
        l_play (1,1) logical  % Start (true) or stop (false).
    end
    if ~l_play
        if ~isempty(obj.h_playTimer) && isvalid(obj.h_playTimer)
            stop(obj.h_playTimer);
            delete(obj.h_playTimer);
        end
        l_was = ~isempty(obj.h_playTimer);
        obj.h_playTimer = [];
        if ~isempty(obj.lis_playAxes) && isvalid(obj.lis_playAxes)
            delete(obj.lis_playAxes);
        end
        obj.lis_playAxes = [];
        if l_was
            obj.l_animating = false;
            obj.refresh_bar();
        end
        return
    end
    if obj.l_animating || numel(obj.rv_t) < 2 || isempty(obj.ax) || ~all(isgraphics(obj.ax)) ...
            || batchStartupOptionUsed
        return
    end
    fig = ancestor(obj.ax(1), "figure");
    if isempty(fig) || fig.Visible ~= "on"
        return
    end
    if obj.i_time == numel(obj.rv_t)
        obj.set_time(obj.rv_t(1));
    end
    wr = matlab.lang.WeakReference(obj);
    obj.r_playFrom  = obj.rv_t(obj.i_time);
    obj.u_playTic   = tic;
    obj.l_animating = true;
    obj.h_playTimer = timer("ExecutionMode", "fixedSpacing", "Period", 0.04, "BusyMode", "drop", ...
        "Tag", "GUILDA:GraphBase:Playback", "TimerFcn", @(h, ~) play_tick(h, wr));
    obj.lis_playAxes = listener(obj.ax(1), "ObjectBeingDestroyed", @(~, ~) play_stop(wr));
    obj.refresh_bar();
    start(obj.h_playTimer);
end


function play_tick(h_timer, wr)
% One frame of the playback: show the sample of the time reached; stop after the last one.
    arguments (Input)
        h_timer  % The timer. <@Type> timer
        wr       % Weak reference to the graph. <@Type> matlab.lang.WeakReference
    end
    G = wr.Handle;
    if is_gone(G)
        stop(h_timer);                   % the graph, its axes or its figure are gone
        delete(h_timer);
        return
    end
    try
        t = G.r_playFrom + toc(G.u_playTic) * G.PlaySpeed;
        l_end = t >= G.rv_t(end);
        G.set_time(min(t, G.rv_t(end)));
        drawnow limitrate
        if l_end
            G.play_bar(false);
        end
    catch err
        l_gone = is_gone(G);             % the window closed during the tick: stop quietly
        if isvalid(G)
            G.play_bar(false);
        elseif isvalid(h_timer)
            stop(h_timer);
            delete(h_timer);
        end
        if ~l_gone
            show_msg("warning", "GUILDA:GraphBase:PlaybackTimer", err.message);
        end
    end
end


function l_gone = is_gone(G)
% True when the graph is going away: it or its axes are gone, or its figure is missing or
% being deleted (a tick can run while a window closes; then the axes may have no figure).
    arguments (Input)
        G  % The graph, or empty. <@Type> GraphBase
    end
    arguments (Output)
        l_gone (1,1) logical  % True when the timer should stop without a warning.
    end
    try
        l_gone = isempty(G) || ~isvalid(G) || isempty(G.ax) || ~all(isgraphics(G.ax)) ...
            || any(arrayfun(@(h) h.BeingDeleted == "on", G.ax));
        if ~l_gone
            fig = ancestor(G.ax(1), "figure");
            l_gone = isempty(fig) || ~isvalid(fig) || fig.BeingDeleted == "on";
        end
    catch
        l_gone = true;                   % the graphics changed under the check: they are going away
    end
end


function play_stop(wr)
% Stop the playback of the graph held by the weak reference wr (its axes are being deleted).
    arguments (Input)
        wr  % Weak reference to the graph. <@Type> matlab.lang.WeakReference
    end
    G = wr.Handle;
    if ~isempty(G) && isvalid(G)
        G.play_bar(false);
    end
end
