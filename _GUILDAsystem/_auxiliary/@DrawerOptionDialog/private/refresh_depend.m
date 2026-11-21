function sct_field = refresh_depend(sct_field, sv_changed, history, a_object)
% Evaluate again the choices and defaults of the fields that refer to the inputs changed, and of the fields that refer to those.
%
% A dropdown or list takes the new items and keeps the values still among them (a dropdown
% else takes its first item); while an input it refers to is empty, it has no items and its
% hint says "Select <label> first". A number, string or expression field whose default refers
% to another input (`From.Time, else [0, 10]`) takes the new default, and shows it while the
% field still shows the old one; when no alternative evaluates, the field is empty with the
% default in words as its hint. Only these fields are evaluated, so a change of another field
% costs nothing. A field not drawn yet takes the new value as the value it shows first.
    arguments (Input)
        sct_field struct           % Fields of the form (sct_field of build_form).
        sv_changed (1,:) string    % Names of the inputs changed.
        history                    % HistoryGUILDA of the call, or [].
        a_object                   % Object of the call, or [].
    end
    arguments (Output)
        sct_field struct           % The fields with their items, defaults, values and hints updated.
    end
    sv_queue = sv_changed;
    while ~isempty(sv_queue)
        s_changed = sv_queue(1);
        sv_queue(1) = [];
        for j = find(arrayfun(@(c) ismember(s_changed, c.sv_depend), sct_field))
            sct = sct_field(j);
            h = sct.h;
            if sct.s_choices ~= ""
                [c_items, l_items, sct.s_wait] = eval_depend(sct.s_choices, sct.sv_depend, sct_field, history, a_object);
                sv_items = strings(0, 1);
                if l_items
                    sv_items = unique(reshape(string(c_items), [], 1), "stable");
                    sv_items = sv_items(sv_items ~= "");
                end
                if sct.widget == "choice" && ~(sct.kind == "required" && ~isempty(sv_items))
                    sv_items = [""; sv_items];    %#ok<AGROW> "" leaves the option out
                end
                sct.items = sv_items;
                if ismember(sct.widget, ["tags", "choice"])
                    sv_now = reshape(string(sct.shown), [], 1);
                    if sct.l_built
                        sv_now = reshape(string(h.Value), [], 1);
                    end
                    sv_keep = intersect(sv_now, sv_items, "stable");
                    if sct.widget == "choice" && isempty(sv_keep)
                        sv_keep = sv_items(1);
                    elseif sct.widget == "choice"
                        sv_keep = sv_keep(1);
                    end
                    if sct.l_built
                        h.Items = cellstr(sv_items);
                        if sct.widget == "tags"
                            h.Value = cellstr(sv_keep);
                        else
                            h.Value = char(sv_keep);
                        end
                    else
                        sct.shown = sv_keep;
                    end
                end
            end
            if ~isempty(sct.sv_default) && ismember(sct.widget, ["number", "string", "expression"])
                s_old = sct.s_base;
                [default, l_default] = eval_depend(sct.sv_default, sct.sv_depend, sct_field, history, a_object);
                sct.s_hint = "";
                if ~l_default
                    sct.s_hint = sct.s_default;
                end
                sct = field_baseline(sct, default, l_default);
                if sct.l_built && strtrim(string(h.Value)) == s_old    % unchanged: the new default
                    h.Value = char(sct.s_base);
                elseif ~sct.l_built && strtrim(string(sct.shown)) == s_old
                    sct.shown = sct.s_base;
                end
            end
            if sct.l_built && isa(sct.h_extra, "matlab.ui.control.Label") && string(sct.h_extra.Text) ~= hint_text(sct)
                sct.h_extra.Text = hint_text(sct);
            end
            sct_field(j) = sct;
            sv_queue(end+1) = sct.name;    %#ok<AGROW>
        end
    end
end
