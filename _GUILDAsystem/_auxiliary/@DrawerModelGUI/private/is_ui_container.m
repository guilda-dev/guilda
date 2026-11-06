function l_ok = is_ui_container(h)
% True for a container of a uifigure: uifigure, uipanel, uitab or uigridlayout.
    arguments (Input)
        h  % Candidate container.
    end
    arguments (Output)
        l_ok (1,1) logical  % True when the GUI can be drawn in h.
    end
    l_ok = false;
    if ~(isa(h, "matlab.ui.Figure") || isa(h, "matlab.ui.container.Panel") ...
            || isa(h, "matlab.ui.container.Tab") || isa(h, "matlab.ui.container.GridLayout"))
        return
    end
    if ~isscalar(h) || ~isvalid(h)
        return
    end
    % Since R2025a figure() also takes UI components; only uifigure() adds the dynamic
    % property isUIFigure, which tells the two apart.
    h_fig = ancestor(h, "figure");
    l_ok = ~isempty(h_fig) && isprop(h_fig, "isUIFigure");
end
