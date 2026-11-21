function set_style(obj, sr_tag, opt)
% Set the appearance of the elements with the given tags.
%
% Each option writes the vector property of the kind of each element (see
% style_properties of the subclass and tab_element), so G.set_style("B001", Color="r")
% and setting the row of B001 in the color vector are the same; only the changed elements
% are drawn again. An element kind that has no such option is passed over when another
% element with the same tag has it (e.g. the arrows that share the tag of their node); if
% none of the elements of a tag has the option, it is an error that names the kinds and
% their options. An unknown tag is an error.
%
% - `Color`: a color name, "#RRGGBB" or an RGB triplet.
% - `Label`: one text, or one per tag.
% - `MarkerSize`, `LineWidth`: one value, or one per tag.
% - `Marker`, `LineStyle`, `Visible`: one value for all tags.
%
% <@Examples>
% ```matlab
% G = net.plot_spring_model();
% G.set_style(["B001", "B002"], Color="r", MarkerSize=20);
% G.set_style("B003", Label="load", Visible=true);
% G.set_style(["B001", "B002", "B003"], MarkerSize=[10 15 20]);
% ```
    arguments (Input)
        obj
        sr_tag (1,:) string                           % Tags of the elements (see tab_element).
        opt.Color                                     % Color of the elements. <@Type> string|double
        opt.Label (1,:) string                        % Label of the elements: one, or one per tag.
        opt.Marker (1,1) string                       % Marker of the elements.
        opt.MarkerSize (1,:) double {mustBePositive}  % Size of the markers: one, or one per tag.
        opt.LineWidth (1,:) double {mustBePositive}   % Width of the lines: one, or one per tag.
        opt.LineStyle (1,1) string                    % Style of the lines.
        opt.Visible (1,1) logical                     % Show the elements.
    end
    tab     = obj.tab_element;
    sct_map = obj.style_properties();
    sv_bad  = sr_tag(~ismember(sr_tag, tab.Tag));
    if ~isempty(sv_bad)
        error(msg("GUILDA:GraphBase:UnknownTag", join(sv_bad, ", "), class(obj)));
    end
    sv_opt = string(fieldnames(opt))';
    if isfield(opt, "Color")
        try
            opt.Color = validatecolor(opt.Color);
        catch
            error(msg("GUILDA:GraphBase:StyleValue", "Color", "a color name, ""#RRGGBB"" or an RGB triplet"));
        end
    end
    sv_perTag = ["Label", "MarkerSize", "LineWidth"];              % options with one value per tag
    for s_opt = intersect(sv_perTag, sv_opt, "stable")
        if numel(opt.(s_opt)) ~= 1 && numel(opt.(s_opt)) ~= numel(sr_tag)
            error(msg("GUILDA:GraphBase:StyleValue", s_opt, "one value or " + numel(sr_tag) + " values (one per tag)"));
        end
    end

    % Rows to write, property by property: index in the vector and value
    sv_tagAll  = tab.Tag;
    sv_kindAll = tab.Kind;
    iv_idxAll  = tab.Index;
    sv_kinds   = unique(sv_kindAll, "stable");
    sct_has    = struct();                                         % option -> rows of tab whose kind has it
    for s_opt = sv_opt
        l_kind = arrayfun(@(s) isfield(sct_map, s) && isfield(sct_map.(s), s_opt), sv_kinds);
        sct_has.(s_opt) = ismember(sv_kindAll, sv_kinds(l_kind));
    end
    sct_write = struct();
    for i_tag = 1:numel(sr_tag)
        iv_tag = find(sv_tagAll == sr_tag(i_tag));
        for s_opt = sv_opt
            iv_has = iv_tag(sct_has.(s_opt)(iv_tag));
            if isempty(iv_has)
                sv_kind = unique(sv_kindAll(iv_tag), "stable")';
                sv_allow = arrayfun(@(s) s + ": " + allowed_text(sct_map, s), sv_kind);
                error(msg("GUILDA:GraphBase:StyleNotApplicable", s_opt, sr_tag(i_tag), join(sv_allow, "; ")));
            end
            val = opt.(s_opt);
            if any(s_opt == sv_perTag) && ~isscalar(val)
                val = val(i_tag);
            end
            for i_row = iv_has'
                s_prop = sct_map.(sv_kindAll(i_row)).(s_opt);
                if ~isfield(sct_write, s_prop)
                    sct_write.(s_prop) = struct("iv", zeros(0, 1), "c_val", {{}});
                end
                sct_write.(s_prop).iv(end+1, 1)  = iv_idxAll(i_row);
                sct_write.(s_prop).c_val{end+1} = val;
            end
        end
    end

    % One assignment per property: its setter draws the changed elements again
    for s_prop = string(fieldnames(sct_write))'
        v = obj.(s_prop);
        w = sct_write.(s_prop);
        for j = 1:numel(w.iv)
            v(w.iv(j), :) = w.c_val{j};
        end
        obj.(s_prop) = v;
    end
end


function s = allowed_text(sct_map, s_kind)
% Options of set_style that apply to a kind, as text.
    arguments (Input)
        sct_map (1,1) struct  % Options and properties of each kind.
        s_kind (1,1) string   % Kind of element.
    end
    arguments (Output)
        s (1,1) string  % The options, or "none".
    end
    s = "none";
    if isfield(sct_map, s_kind) && ~isempty(fieldnames(sct_map.(s_kind)))
        s = join(string(fieldnames(sct_map.(s_kind)))', ", ");
    end
end
