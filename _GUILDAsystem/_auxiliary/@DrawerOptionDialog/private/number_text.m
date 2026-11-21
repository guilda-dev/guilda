function s_text = number_text(value, r_auto, r_none, s_auto)
% Text of a number field for a value: "auto" (or s_auto) or "none" for the special values of the field, else mat2str.
%
% A value equal to r_auto (NaN where NaN means automatic), or a vector of only NaN such as
% ColorLimits [NaN NaN], is s_auto ("auto", or the word of gui_forms.json "labels" for NaN,
% e.g. "bus"), one equal to r_none
% (NaN, Inf or -Inf where it means no limit) is "none"; [] is "". get_code reads the words back.
    arguments (Input)
        value               % Number or numeric array (double, or [] for none).
        r_auto              % Value shown as "auto" (NaN), or [] when the field has none.
        r_none              % Value shown as "none" (NaN, Inf or -Inf), or [] when the field has none.
        s_auto (1,1) string % Word shown for r_auto, e.g. "auto".
    end
    arguments (Output)
        s_text (1,1) string % Text of the field.
    end
    if isempty(value)
        s_text = "";
    elseif isscalar(value) && ~isempty(r_none) && isequaln(double(value), r_none)
        s_text = "none";
    elseif ~isempty(r_auto) && isnan(r_auto) && isnumeric(value) && all(isnan(value), "all")
        s_text = s_auto;
    else
        s_text = string(mat2str(double(value), 15));
    end
end
