function prepare_frame(obj, r_dt)
% Prepare the next frame of export_video: nothing in the base class.
%
% export_video calls it before each frame with the time between frames r_dt [s]
% (1/FrameRate), and once with NaN after the last frame (also when the export stops with
% an error). A subclass that moves something by real time (e.g. a flow animation driven
% by a timer) overrides it to advance by r_dt and to restore its state on NaN.
    arguments (Input)
        obj
        r_dt (1,1) double  % [s] Time between frames, or NaN after the last frame.
    end
end
