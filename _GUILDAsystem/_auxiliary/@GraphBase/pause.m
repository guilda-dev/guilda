function pause(obj)
% Stop the playback of play (or of the Play button of the playback bar).
%
% The timer is stopped and deleted and the sample shown stays. A blocking animate that
% runs stops at its next frame. Nothing happens when nothing plays.
%
% <@Examples>
% ```matlab
% G.play();
% G.pause();
% ```
    arguments (Input)
        obj
    end
    obj.play_bar(false);
    if obj.l_animating
        obj.l_stopAnimate = true;
    end
end
