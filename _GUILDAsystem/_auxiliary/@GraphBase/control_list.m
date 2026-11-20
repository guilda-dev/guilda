function sct_ctl = control_list(obj)
% Controls of the panel of show_controls: none in the base class.
%
% A subclass returns one row per control, with the fields
%
% - `Property`: the property set by the control (string). The time is not a control: it is
%   in the playback bar (see GraphBase).
% - `Widget`: "dropdown" (Items), "checkbox" (logical), "slider" (Limits), "spinner"
%   (Limits, Step), "range" (a 1 x 2 [min max]: two spinners; Limits, Step) or "toggle"
%   (a logical as a button).
% - `Items`: the choices of a dropdown (string). For a range that may be automatic (a NaN
%   in the property), a function @(G) [a b] giving the values in use while it is: the
%   row then has an Auto checkbox (checked: the property is [NaN NaN]; unchecked, or a
%   spinner changed: the values of the spinners), and the spinners show those values.
% - `Limits`: [min max] of a slider, spinner or range; `Step`: the step of a spinner or
%   range ([] automatic).
% - `Label`: the text shown ("" the property name); `Group`: the heading the control is
%   shown under (the groups keep the order of their first row).
% - `EnableFcn`: [] or a function @(G) logical; the control is disabled while it is false.
%
% A declared property must be SetObservable (the panel follows its changes) and scalar
% (or the 1 x 2 of a range). A field left out takes its default ([] or "").
    arguments (Input)
        obj
    end
    arguments (Output)
        sct_ctl struct  % Controls of the panel, one row each.
    end
    sct_ctl = struct("Property", {}, "Widget", {}, "Items", {}, "Limits", {}, "Step", {}, ...
                     "Label", {}, "Group", {}, "EnableFcn", {});
end
