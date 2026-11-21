function s_text = tags_text(sv_tag)
% Text of a tag field for tags: "B001, B002" ("" for none).
    arguments (Input)
        sv_tag string  % Tags.
    end
    arguments (Output)
        s_text (1,1) string  % Tags separated by ", ".
    end
    s_text = "";
    if ~isempty(sv_tag)
        s_text = join(reshape(sv_tag, 1, []), ", ");
    end
end
