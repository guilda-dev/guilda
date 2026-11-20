function sct = field_baseline(sct, default, l_default)
% The default of a field as a value of its widget (baseline) and as the text of a text field (s_base).
%
% build_form calls it for every field; form_event again for a number, string or expression
% field whose default refers to another input (`Default: From.Time, else [0, 10]`) when that
% input changes. A choice field without a default listed in its items gets "" as its first
% item (which leaves the option out), except a required input, which takes its first item.
    arguments (Input)
        sct (1,1) struct          % The field (sct_field of build_form): widget, items, kind, s_default, r_auto, r_none, s_auto.
        default                   % Value of the default.
        l_default (1,1) logical   % True when the default was evaluated.
    end
    arguments (Output)
        sct (1,1) struct          % The field with baseline, s_base (and items, s_hint) set.
    end
    s_default = sct.s_default;
    switch sct.widget
        case {"tags", "tagtext"}
            sct.baseline = strings(0, 1);
            if l_default && (isstring(default) || ischar(default) || iscellstr(default))
                sct.baseline = reshape(string(default), [], 1);
                if sct.widget == "tags"
                    sct.baseline = intersect(sct.baseline, sct.items, "stable");
                end
            elseif l_default && isnumeric(default)    % indices (from_to: [1,2]): an empty field with the hint
                sct.s_hint = s_default;
            end
            sct.s_base = tags_text(sct.baseline);
        case "choice"
            if l_default && isscalar(string(default)) && ismember(string(default), sct.items)
                sct.baseline = string(default);
            elseif sct.kind == "required" && ~isempty(sct.items)
                sct.baseline = sct.items(1);
            else
                sct.items = [""; sct.items];    % "" leaves the option out
                sct.baseline = "";
            end
        case "flag"
            sct.items    = ["", "true", "false"].';
            sct.baseline = "";
        case "logical"
            sct.baseline = l_default && isscalar(default) && (isequal(default, true) || isequal(default, 1));
        case "number"
            sct.baseline = [];
            if l_default && (isnumeric(default) || islogical(default)) && isreal(default)
                sct.baseline = double(default);
            end
            if numel(sct.baseline) > 16    % a large default (a colormap): its expression
                sct.s_base = s_default;
            else
                sct.s_base = number_text(sct.baseline, sct.r_auto, sct.r_none, sct.s_auto);
            end
        case "string"
            sct.baseline = "";
            if l_default && isscalar(string(default))
                sct.baseline = string(default);
            end
            sct.s_base = sct.baseline;
        case "expression"
            sct.baseline = "";
            if l_default
                if (isstring(default) || ischar(default)) && size(string(default), 1) == 1 && isscalar(string(default))
                    sct.baseline = code_strings(string(default));
                elseif (isstring(default) || iscellstr(default)) && isempty(default)
                    sct.baseline = "";    % no text (strings(1,0)): an empty field, left out
                elseif (isstring(default) || iscellstr(default)) && isvector(default) && numel(default) <= 16
                    sct.baseline = code_strings(string(default));
                elseif (isnumeric(default) || islogical(default)) && numel(default) <= 16 && ismatrix(default)
                    sct.baseline = string(mat2str(default, 6));
                else
                    sct.baseline = s_default;
                end
            end
            sct.s_base = sct.baseline;
            if sct.baseline == "NaN" && ~isempty(sct.r_auto)
                sct.s_base = sct.s_auto;
            end
    end
end
