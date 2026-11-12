function n = next_tag_number(sv_tags, s_prefix)
% Return the number for a new automatic tag "<prefix><header><number>".
%
% The number is one more than the largest number among the tags in use (max+1).
% A removed number is not reused while a larger one remains, and the new tag
% never equals a tag in use: reading its trailing digits gives at least n,
% which is larger than every number in use. The prefix is the tag of the parent
% (e.g. the bus tag for the components of a bus), so its digits are not counted.
%
% <@Examples>
% ```matlab
% n = tools.next_tag_number(string(net.a_Branch))
% n = tools.next_tag_number(string(bus.a_Component), bus.s_tag)
% ```
    arguments (Input)
        sv_tags    string % Tags in use.
        s_prefix   (1,1) string = "" % Prefix of the tags to count; tags without it are ignored.
    end
    arguments (Output)
        n % Number for the new tag.
    end
    sv_tags  = sv_tags(:);
    sv_tags  = sv_tags(startsWith(sv_tags, s_prefix));
    sv_body  = extractAfter(sv_tags, strlength(s_prefix));
    sv_num   = regexp(sv_body, "\d+$", "match", "once");
    n = max([0; double(string(sv_num))], [], "omitnan") + 1;
end
