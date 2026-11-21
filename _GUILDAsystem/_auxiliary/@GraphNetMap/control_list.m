function sct_ctl = control_list(obj)
% Controls of the panel of show_controls: the range of the branch widths.
%
% The colors of the buses (s_color) and the arrows (s_arrow) are data of the map, chosen
% by res.plot_network, so the panel has no control for them, and no property switches the
% labels. See GraphBase.control_list for the fields.
    arguments (Input)
        obj
    end
    arguments (Output)
        sct_ctl struct  % Controls of the panel, one row each.
    end
    sct_ctl = struct("Property", "BranchWidthRange", "Widget", "range", "Limits", [0.5 20], ...
                     "Step", 0.5, "Label", "Width range [pt]", "Group", "Size");
end
