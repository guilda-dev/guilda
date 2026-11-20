function sv_tag = parse_tags(s_text)
% Tags typed in a tag field: separated by commas, semicolons, spaces or |, quotes and brackets ignored.
    arguments (Input)
        s_text (1,1) string  % Text of the field, e.g. "B001, B002" or ["B001", "B002"].
    end
    arguments (Output)
        sv_tag (1,:) string  % Tags in the order typed (strings(1,0) for none).
    end
    sv_tag = reshape(string(regexp(erase(s_text, ["""", "'", "[", "]"]), "[^\s,;|]+", "match")), 1, []);
end
