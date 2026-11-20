function animate(obj, opt)
% Play the samples as an animation in the figure.
%
% Frames are taken every TimeStep seconds of the data (the nearest sample each) and shown
% Speed times faster than real time when the drawing keeps up (Speed not given: PlaySpeed).
% animate blocks until the last frame; the Play button of the playback bar plays without
% blocking (see GraphBase). When the data names its
% samples (s_sampleName, e.g. the steps of a continuation power flow) and TimeStep is not
% given, every sample is one frame (one sample value per second at Speed=1). UpdateFcn(t) is called at
% every frame with the time of the sample, e.g. to move an xline in other axes. Closing
% the figure stops the animation, and so does the Pause button of the playback bar (at the
% next frame). While it plays, the button of the bar shows Pause, and a press of Play does
% not start a second playback. A playback of the bar that runs is stopped first. The linked graphs (see link) move with it. A graph with
% one sample has nothing to play: it is an error.
%
% <@Examples>
% ```matlab
% h = xline(ax_other, 0);
% G.animate(Speed=0.5, UpdateFcn=@(t) set(h, "Value", t));
% ```
    arguments (Input)
        obj
        opt.Speed (1,1) double {mustBePositive}            % Playback speed relative to real time (Inf: as fast as possible); default PlaySpeed.
        opt.TimeStep (1,1) double {mustBePositive}         % Time of the data between frames [s] (default 0.05), or the step of the sample values for samples named by the data (default: one frame per sample).
        opt.UpdateFcn = []                                 % Function called as UpdateFcn(t) at every frame; [] for none. <@Type> function_handle
    end
    arguments (Output)
    end
    rv_t = obj.rv_t;
    if numel(rv_t) < 2
        error(msg("GUILDA:GraphBase:OneSample", "animate"));
    end
    if ~isfield(opt, "Speed")
        opt.Speed = obj.PlaySpeed;
    end
    obj.play_bar(false);
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
    obj.l_stopAnimate = false;
    obj.l_animating = true;
    obj.refresh_bar();
    err = [];
    try
        t_start = tic;
        for t = rv_frame
            if obj.l_stopAnimate || ~all(isgraphics(obj.ax))
                break
            end
            obj.set_time(t);
            if ~isempty(opt.UpdateFcn)
                opt.UpdateFcn(rv_t(obj.i_time));
            end
            drawnow;
            r_wait = (t - rv_t(1)) / opt.Speed - toc(t_start);
            if r_wait > 0
                pause(r_wait);
            end
        end
    catch err
    end
    if isvalid(obj)
        obj.l_stopAnimate = false;
        obj.l_animating = false;
        obj.refresh_bar();
    end
    if ~isempty(err)
        rethrow(err);
    end
end

