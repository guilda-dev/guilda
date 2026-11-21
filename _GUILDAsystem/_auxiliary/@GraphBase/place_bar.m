function place_bar(obj, l_hide)
% Put the playback bar below the axes, or hide it and give its place to the axes.
%
% The tiled layout of the axes keeps its left edge and width (show_controls may have
% narrowed it) and gives up the bottom strip of about 34 pixels, which the bar takes with
% the same left edge and width. l_hide true hides the bar and gives the strip back to the
% axes (export_video, so that the frames show only the graph). Called when the bar is
% made, when its container is resized, and when the panel of controls is shown or
% removed. Nothing happens without a bar.
    arguments (Input)
        obj
        l_hide (1,1) logical = false  % Hide the bar and let the axes fill its strip.
    end
    h_bar = obj.h_bar;
    if isempty(h_bar) || ~isgraphics(h_bar) || isempty(obj.ax) || ~isgraphics(obj.ax(1))
        return
    end
    tl = obj.ax(1).Parent;
    if ~isa(tl, "matlab.graphics.layout.TiledChartLayout")
        return
    end
    tl.Units = "normalized";
    rv_pos = tl.OuterPosition;
    if l_hide
        h_bar.Visible = "off";
        tl.OuterPosition = [rv_pos(1), 0, rv_pos(3), 1];
        return
    end
    rv_px = getpixelposition(h_bar.Parent);
    r_h   = min(0.4, 34 / max(rv_px(4), 1));
    tl.OuterPosition = [rv_pos(1), r_h, rv_pos(3), 1 - r_h];
    h_bar.Position   = [rv_pos(1), 0, rv_pos(3), r_h];
    h_bar.Visible    = "on";
end
