function select(obj, sr_tag)
% Add elements to the selection by tag and draw the selection overlay.
%
% Every element with a selected tag is highlighted in SelectionColor (e.g. a bus and the
% link of a component share the tag of the component). The overlay does not change the
% appearance set by set_style. Selecting a tag twice changes nothing; an unknown tag is
% an error.
%
% <@Examples>
% ```matlab
% G = net.plot_diagram();
% G.select(["B001", "B002"]);
% G.Selection             % ["B001", "B002"]
% G.clear_selection();
% ```
    arguments (Input)
        obj
        sr_tag (1,:) string  % Tags to select (see tab_element).
    end
    tab = obj.element_table();
    sv_bad = sr_tag(~ismember(sr_tag, tab.Tag));
    if ~isempty(sv_bad)
        error(msg("GUILDA:GraphBase:UnknownTag", join(sv_bad, ", "), class(obj)));
    end
    obj.Selection = unique([obj.Selection, sr_tag], "stable");
    if ~isempty(obj.sct_plt) && all(isgraphics(obj.ax))
        obj.apply_selection();
    end
end
