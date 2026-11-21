function s_text = hint_text(sct)
% Text of the muted hint beside a field: a request for the input its choices need, the default in words, or the hint of gui_forms.json.
%
% "Select unit first" while the choices of the field wait for another input (s_wait); else
% "default: <words>" for a default in words, shortened ("from GUILDA.setting" for a setting,
% the value of "true (calculate_optimal_powerflow)", at most 24 characters); else the hint of
% gui_forms.json "labels"; else "".
    arguments (Input)
        sct (1,1) struct     % The field (sct_field of build_form).
    end
    arguments (Output)
        s_text (1,1) string  % Text of the hint label.
    end
    s_text = sct.s_note;
    if sct.s_wait ~= ""
        s_text = sct.s_wait;
    elseif sct.s_hint ~= ""
        s_hint = sct.s_hint;
        s_value = regexp(s_hint, "^(\S+) \(", "tokens", "once");    % "true (calculate_optimal_powerflow)": true
        if contains(s_hint, "GUILDA.setting") || contains(s_hint, "GUILDA.config")
            s_hint = "from GUILDA.setting";
        elseif ~isempty(s_value)
            s_hint = string(s_value);
        elseif strlength(s_hint) > 24
            s_hint = extractBefore(s_hint, 23) + "…";
        end
        s_text = "default: " + s_hint;
    end
end
