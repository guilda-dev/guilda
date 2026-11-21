function play(obj)
% Start playing the samples without blocking, as the Play button of the playback bar.
%
% A timer shows the samples from the one shown (from the first when the last is shown)
% at PlaySpeed times real time, and play returns at once; pause stops it, and so do
% closing the figure and deleting the axes or the graph. The bar shows Pause meanwhile. A
% play while a playback (play or animate) runs does nothing, and so does a play in matlab
% -batch or for a figure that is not visible (no timer is made). A graph with one sample
% has nothing to play: it is an error. animate plays the same samples and blocks.
%
% <@Examples>
% ```matlab
% G = res.plot_diagram();
% G.PlaySpeed = 0.5;
% G.play();
% G.pause();
% ```
    arguments (Input)
        obj
    end
    if numel(obj.rv_t) < 2
        error(msg("GUILDA:GraphBase:OneSample", "play"));
    end
    if isempty(obj.ax) || ~all(isgraphics(obj.ax))
        error(msg("GUILDA:GraphBase:NoAxes", class(obj)));
    end
    obj.play_bar(true);
end
