function export_video(obj, s_file, opt)
% Write the animation to an MPEG-4 video file.
%
% Frames are taken every TimeStep seconds of the data (the nearest sample each) and
% written at FrameRate frames per second; FrameRate x TimeStep = 1 is real time. The last
% frame is held for HoldTime seconds. Capture "figure" records the whole figure (other
% axes moved by UpdateFcn included), "axes" only the axes of the picture. The frames are
% padded to an even width and height, as H.264 requires.
%
% <@Examples>
% ```matlab
% G.export_video("swing.mp4", FrameRate=20, TimeStep=0.05);
% ```
    arguments (Input)
        obj
        s_file (1,1) string                                 % Path of the video file (.mp4).
        opt.FrameRate (1,1) double {mustBePositive} = 20    % [1/s] Frames per second of the video.
        opt.TimeStep (1,1) double {mustBePositive} = 0.05   % [s] Time of the data between frames.
        opt.HoldTime (1,1) double {mustBeNonnegative} = 1   % [s] Time the last frame is held.
        opt.UpdateFcn = []                                  % Function called as UpdateFcn(t) at every frame; [] for none. <@Type> function_handle
        opt.Capture (1,1) string {mustBeMember(opt.Capture, ["figure", "axes"])} = "figure" % Part of the window recorded.
    end
    rv_t     = obj.sct_data.rv_t;
    rv_frame = rv_t(1):opt.TimeStep:rv_t(end);
    if rv_frame(end) < rv_t(end) - 1e-9
        rv_frame(end+1) = rv_t(end);
    end
    if opt.Capture == "figure"
        h_capture = ancestor(obj.ax, "figure");
    else
        h_capture = obj.ax;
    end

    vw = VideoWriter(s_file, "MPEG-4");
    vw.FrameRate = opt.FrameRate;
    vw.Quality   = 95;
    open(vw);
    c_close = onCleanup(@() close(vw));
    iv_size = [];
    for i_frame = 1:numel(rv_frame)
        obj.set_time(rv_frame(i_frame));
        if ~isempty(opt.UpdateFcn)
            opt.UpdateFcn(rv_t(obj.i_time));
        end
        drawnow;
        n_repeat = 1 + (i_frame == numel(rv_frame)) * round(opt.HoldTime * opt.FrameRate);
        iv_size  = GraphSpringBase.write_frame(vw, h_capture, iv_size, n_repeat);
    end
end
