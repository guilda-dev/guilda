function n = next_tag_number(str_tags, str_suffix)
% Return the number for a new automatic tag "<header><number><suffix>".
%
% The number is one more than the largest number among the tags in use (max+1).
% A removed number is not reused while a larger one remains, and the new tag
% never equals a tag in use: reading its trailing digits gives at least n,
% which is larger than every number in use.
%
% <@Examples>
% ```matlab
% n = tools.next_tag_number(string(net.a_Branch))
% n = tools.next_tag_number(string(bus.a_Component), bus.str_tag)
% ```
    arguments
        str_tags   string % Tags in use.
        str_suffix (1,1) string = "" % Suffix of the tags to count; tags without it are ignored.
    end
    arguments (Output)
        n % Number for the new tag.
    end
    str_tags = str_tags(:);
    str_tags = str_tags(endsWith(str_tags, str_suffix));
    str_body = extractBefore(str_tags, strlength(str_tags) - strlength(str_suffix) + 1);
    str_num  = regexp(str_body, "\d+$", "match", "once");
    n = max([0; double(string(str_num))], [], "omitnan") + 1;
end
