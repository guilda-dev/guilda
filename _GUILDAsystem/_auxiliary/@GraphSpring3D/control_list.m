function sct_ctl = control_list(obj)
% Controls of the panel of show_controls: those of GraphSpringBase and the surface opacity.
%
% See GraphBase.control_list for the fields.
    arguments (Input)
        obj
    end
    arguments (Output)
        sct_ctl struct  % Controls of the panel, one row each.
    end
    sct_ctl = control_list@GraphSpringBase(obj);
    sct_ctl(end+1) = struct("Property", "SurfaceAlpha", "Widget", "slider", "Limits", [0 1], ...
                            "Step", [], "Label", "Surface opacity", "Group", "View");
end
