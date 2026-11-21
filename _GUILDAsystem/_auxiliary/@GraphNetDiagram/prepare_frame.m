function prepare_frame(obj, r_dt)
% Advance the flow dots by the time between two frames of export_video, without the timer.
%
% Before each frame the timer is stopped and the dots move by r_dt (step_flow), so one
% second of the video moves them as far as one second on the screen. NaN (after the last
% frame, also when the export stops with an error) starts the timer again when it should
% run (flow_timer).
    arguments (Input)
        obj
        r_dt (1,1) double  % [s] Time between frames, or NaN after the last frame.
    end
    if isnan(r_dt)
        obj.l_flowHold = false;
        obj.flow_timer("auto");
        return
    end
    obj.l_flowHold = true;
    obj.flow_timer("stop");
    obj.step_flow(r_dt);
end
