function animate(obj, opt)
% Play the samples as an animation in the figure.
%
% Frames are taken every TimeStep seconds of the data (the nearest sample each) and shown
% Speed times faster than real time when the drawing keeps up. UpdateFcn(t) is called at
% every frame with the time of the sample, e.g. to move an xline in other axes. Closing
% the figure stops the animation.
%
% <@Examples>
% ```matlab
% h = xline(ax_other, 0);
% G.animate(Speed=0.5, UpdateFcn=@(t) set(h, "Value", t));
% ```
    arguments (Input)
        obj
        opt.Speed (1,1) double {mustBePositive} = 1     % Playback speed relative to real time (Inf: as fast as possible).
        opt.TimeStep (1,1) double {mustBePositive} = 0.05 % [s] Time of the data between frames.
        opt.UpdateFcn = []                              % Function called as UpdateFcn(t) at every frame; [] for none. <@Type> function_handle
    end
    rv_t     = obj.sct_data.rv_t;
    rv_frame = rv_t(1):opt.TimeStep:rv_t(end);
    if rv_frame(end) < rv_t(end) - 1e-9
        rv_frame(end+1) = rv_t(end);
    end
    t_start = tic;
    for t = rv_frame
        if ~isgraphics(obj.ax)
            return
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
end
