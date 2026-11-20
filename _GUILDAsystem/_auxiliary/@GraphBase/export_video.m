function export_video(obj, s_file, opt)
% Write the animation to an MPEG-4 video file.
%
% Frames are taken every TimeStep seconds of the data (the nearest sample each) and
% written at FrameRate frames per second; FrameRate x TimeStep = 1 is real time. When the
% data names its samples (s_sampleName, e.g. steps) and TimeStep is not given, every sample
% is one frame. The last
% frame is held for HoldTime seconds. Capture "figure" records the whole figure (other
% axes moved by UpdateFcn included), "axes" only the axes of the graph (the first panel
% when it has several). The frames are padded to an even width and height, as H.264
% requires. The linked graphs (see link) move with it, but only the figure of this graph
% is recorded: linked graphs in other figures are not in the video. A graph with one
% sample has nothing to record: it is an error. The playback bar is hidden while the video
% is written (its strip goes to the axes), so no frame shows it. Before each frame the graph is told the
% time between frames (prepare_frame(1/FrameRate)), and after the last one NaN, so that a
% graph that moves by real time follows the video instead of the clock.
%
% <@Examples>
% ```matlab
% G.export_video("swing.mp4", FrameRate=20, TimeStep=0.05);
% ```
    arguments (Input)
        obj
        s_file (1,1) string                                % Path of the video file (.mp4).
        opt.FrameRate (1,1) double {mustBePositive} = 20   % [1/s] Frames per second of the video.
        opt.TimeStep (1,1) double {mustBePositive}         % Time of the data between frames [s] (default 0.05), or the step of the sample values for samples named by the data (default: one frame per sample).
        opt.HoldTime (1,1) double {mustBeNonnegative} = 1  % [s] Time the last frame is held.
        opt.UpdateFcn = []                                 % Function called as UpdateFcn(t) at every frame; [] for none. <@Type> function_handle
        opt.Capture (1,1) string {mustBeMember(opt.Capture, ["figure", "axes"])} = "figure"  % Part of the window recorded.
    end
    rv_t = obj.rv_t;
    if numel(rv_t) < 2
        error(msg("GUILDA:GraphBase:OneSample", "export_video"));
    end
    if ~isfield(opt, "TimeStep") && obj.s_sampleName ~= ""
        rv_frame = rv_t;                    % samples named by the data (e.g. steps): one frame each
    else
        if ~isfield(opt, "TimeStep")
            opt.TimeStep = 0.05;
        end
        rv_frame = rv_t(1):opt.TimeStep:rv_t(end);
        if rv_frame(end) < rv_t(end) - 1e-9
            rv_frame(end+1) = rv_t(end);
        end
    end
    if opt.Capture == "figure"
        h_capture = ancestor(obj.ax(1), "figure");
    else
        h_capture = obj.ax(1);
    end

    vw = VideoWriter(s_file, "MPEG-4");
    vw.FrameRate = opt.FrameRate;
    vw.Quality   = 95;
    open(vw);
    c_close = onCleanup(@() close(vw));
    c_frame = onCleanup(@() obj.prepare_frame(NaN));
    obj.place_bar(true);
    c_bar   = onCleanup(@() obj.place_bar());
    iv_size = [];
    for i_frame = 1:numel(rv_frame)
        obj.prepare_frame(1 / opt.FrameRate);
        obj.set_time(rv_frame(i_frame));
        if ~isempty(opt.UpdateFcn)
            opt.UpdateFcn(rv_t(obj.i_time));
        end
        drawnow;
        n_repeat = 1 + (i_frame == numel(rv_frame)) * round(opt.HoldTime * opt.FrameRate);
        iv_size  = GraphBase.write_frame(vw, h_capture, iv_size, n_repeat);
    end
end
