function sct_ctl = control_list(obj)
% Controls of the panel of show_controls: none.
%
% The appearance of a chart is per element (vector properties), and the time of a chart
% that changes with it is in the playback bar (see has_playback), so the panel has no
% controls. See GraphBase.control_list for the fields.
    arguments (Input)
        obj
    end
    arguments (Output)
        sct_ctl struct  % Controls of the panel, one row each.
    end
    sct_ctl = struct("Property", {}, "Widget", {}, "Label", {}, "Group", {});
end
