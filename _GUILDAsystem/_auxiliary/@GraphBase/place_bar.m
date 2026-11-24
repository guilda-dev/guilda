function place_bar(obj, l_hide)
% Put the playback bar below the axes, or hide it and give its place to the axes.
%
% The tiled layout of the axes keeps its left edge and width (show_controls may have
% narrowed it) and gives up the bottom strip of 34 pixels (at most 0.9 of a very low
% container), which the bar takes with the same left edge and width. l_hide true hides the
% bar and gives the strip back to the axes (export_video, so that the frames show only the
% graph). Called when the bar is made, when the panel of controls is shown or removed, and
% by the listeners of refresh_bar: SizeChanged of the container and MarkedClean of the tiled
% layout. A container does not always send SizeChanged (an invisible figure, a uifigure or
% uipanel whose AutoResizeChildren is on, the cell of a uigridlayout), and without being
% placed again the normalized share of the strip would grow and shrink with it; the size
% read when the tiled layout is drawn may still be the one before, and SizeChanged then
% corrects it. Units, positions and visibility that are already right are not set again,
% so that the drawing does not loop. Nothing happens without a bar.
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
    if tl.Units ~= "normalized"
        tl.Units = "normalized";
    end
    rv_pos = tl.OuterPosition;
    if l_hide
        if h_bar.Visible ~= "off"
            h_bar.Visible = "off";
        end
        rv_tl = [rv_pos(1), 0, rv_pos(3), 1];
    else
        rv_px = getpixelposition(h_bar.Parent);
        r_h   = min(0.9, 34 / max(rv_px(4), 1));
        rv_tl = [rv_pos(1), r_h, rv_pos(3), 1 - r_h];
        rv_bar = [rv_pos(1), 0, rv_pos(3), r_h];
        if h_bar.Units ~= "normalized"
            h_bar.Units = "normalized";
        end
        if max(abs(h_bar.Position - rv_bar)) > 1e-9
            h_bar.Position = rv_bar;
        end
        if h_bar.Visible ~= "on"
            h_bar.Visible = "on";
        end
    end
    if max(abs(rv_pos - rv_tl)) > 1e-9
        tl.OuterPosition = rv_tl;
    end
end
