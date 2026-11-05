function s_tag = next_tag(sv_tag, s_kind)
% <s_kind><n> with n the largest number in use with this prefix plus one
    sv_num = extractAfter(sv_tag(startsWith(sv_tag, s_kind)), strlength(s_kind));
    rv_num = str2double(sv_num(matches(sv_num, digitsPattern)));
    n = max([0; rv_num(:)]) + 1;
    s_tag = s_kind + n;
end
