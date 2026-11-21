function flow_timer(obj, s_action)
% Start or stop the timer that moves the flow dots.
%
% "auto" runs the timer when FlowAnimation is true, the diagram is drawn in 2D with a
% FlowMode other than "none", its figure is visible, MATLAB is not started with -batch,
% and export_video does not hold the dots (prepare_frame); otherwise it stops the timer.
% "stop" stops it. A stopped timer is deleted. The timer (Tag
% "GUILDA:GraphNetDiagram:Flow", every 0.04 s, about 25 frames per second) advances the
% dots by the real time since its last frame (at most 0.1 s), so a dropped frame does not
% change their speed, and skips the frames while the figure is hidden. It holds the
% diagram by a weak reference only, and stops and deletes itself when the diagram, its
% axes or its dots (cla) are gone, or its figure is missing or being deleted. A listener on
% the axes stops it when they are deleted (the figure closed, cla, a GUI clearing its
% container). A frame can still run while a window closes (MATLAB runs queued timer
% callbacks during the deletion); an error in such a frame stops the timer without a
% warning, and an error while the figure is alive stops it with the warning
% GUILDA:GraphNetDiagram:FlowTimer.
    arguments (Input)
        obj
        s_action (1,1) string {mustBeMember(s_action, ["auto", "stop"])}  % "auto" or "stop".
    end
    l_run = false;
    if s_action == "auto" && obj.FlowAnimation && ~obj.l_flowHold && obj.Dimension == "2D" ...
            && obj.FlowMode ~= "none" && ~validate(obj) && isfield(obj.sct_plt, "FlowBranch") ...
            && ~batchStartupOptionUsed
        fig   = ancestor(obj.ax(1), "figure");
        l_run = ~isempty(fig) && fig.Visible == "on";
    end

    l_has = ~isempty(obj.h_flowTimer) && isvalid(obj.h_flowTimer);
    if l_run && ~l_has
        wr = matlab.lang.WeakReference(obj);
        obj.u_flowTic = tic;
        obj.h_flowTimer = timer("ExecutionMode", "fixedSpacing", "Period", 0.04, "BusyMode", "drop", ...
            "Tag", "GUILDA:GraphNetDiagram:Flow", "TimerFcn", @(h, ~) flow_tick(h, wr));
        obj.lis_flowAxes = listener(obj.ax(1), "ObjectBeingDestroyed", @(~, ~) flow_stop(wr));
        start(obj.h_flowTimer);
    elseif ~l_run
        if l_has
            stop(obj.h_flowTimer);
            delete(obj.h_flowTimer);
        end
        obj.h_flowTimer = [];
        if ~isempty(obj.lis_flowAxes) && isvalid(obj.lis_flowAxes)
            delete(obj.lis_flowAxes);
        end
        obj.lis_flowAxes = [];
    end
end


function flow_tick(h_timer, wr)
% One frame of the timer: advance the dots of the diagram by the real time since the last frame.
    arguments (Input)
        h_timer  % The timer. <@Type> timer
        wr       % Weak reference to the diagram. <@Type> matlab.lang.WeakReference
    end
    G = wr.Handle;
    if is_gone(G)
        stop(h_timer);                   % the diagram, its axes, its dots (cla) or its figure are gone
        delete(h_timer);
        return
    end
    try
        fig = ancestor(G.ax(1), "figure");
        if fig.Visible ~= "on"           % hidden: draw nothing, keep the timer
            G.u_flowTic = tic;
            return
        end
        r_dt = min(toc(G.u_flowTic), 0.1);
        G.u_flowTic = tic;
        G.step_flow(r_dt);
        drawnow limitrate
    catch err
        l_gone = is_gone(G);             % the window closed during the frame: stop quietly
        if isvalid(G)
            G.flow_timer("stop");
        elseif isvalid(h_timer)
            stop(h_timer);
            delete(h_timer);
        end
        if ~l_gone
            show_msg("warning", "GUILDA:GraphNetDiagram:FlowTimer", err.message);
        end
    end
end


function l_gone = is_gone(G)
% True when the diagram is going away: it, its axes or its dots are gone, or its figure is
% missing or being deleted (a frame can run while a window closes; then the axes may have no figure).
    arguments (Input)
        G  % The diagram, or empty. <@Type> GraphNetDiagram
    end
    arguments (Output)
        l_gone (1,1) logical  % True when the timer should stop without a warning.
    end
    try
        l_gone = isempty(G) || ~isvalid(G) || validate(G) || ~any(isgraphics(G.sct_plt.FlowBranch));
        if ~l_gone
            fig = ancestor(G.ax(1), "figure");
            l_gone = isempty(fig) || ~isvalid(fig) || fig.BeingDeleted == "on" ...
                || any(arrayfun(@(h) h.BeingDeleted == "on", G.ax));
        end
    catch
        l_gone = true;                   % the graphics changed under the check: they are going away
    end
end


function flow_stop(wr)
% Stop the timer of the diagram held by the weak reference wr (its axes are being deleted).
    arguments (Input)
        wr  % Weak reference to the diagram. <@Type> matlab.lang.WeakReference
    end
    G = wr.Handle;
    if ~isempty(G) && isvalid(G)
        G.flow_timer("stop");
    end
end
