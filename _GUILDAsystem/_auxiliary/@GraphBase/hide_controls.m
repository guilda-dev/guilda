function hide_controls(obj)
% Remove the panel of controls of show_controls.
%
% The axes take back their place when the panel was put next to them. The graph does not
% change. Nothing happens when no panel is shown.
%
% <@Examples>
% ```matlab
% G.show_controls();
% G.hide_controls();
% ```
    arguments (Input)
        obj
    end
    if ~isempty(obj.h_controls) && isgraphics(obj.h_controls)
        delete(obj.h_controls);   % its DeleteFcn puts the axes back
    end
    obj.h_controls = gobjects(0);
end
