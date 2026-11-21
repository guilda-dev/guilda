function s_code = code_strings(sv_text)
% MATLAB code of a string array: "B001" for one, ["B001", "B002"] for several, strings(1,0) for none.
    arguments (Input)
        sv_text string  % Strings.
    end
    arguments (Output)
        s_code (1,1) string  % Code text.
    end
    sv_quoted = """" + replace(reshape(sv_text, 1, []), """", """""") + """";
    if isempty(sv_text)
        s_code = "strings(1,0)";
    elseif isscalar(sv_text)
        s_code = sv_quoted;
    else
        s_code = "[" + join(sv_quoted, ", ") + "]";
    end
end
