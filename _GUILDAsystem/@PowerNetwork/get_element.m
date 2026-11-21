function obj_elem = get_element(obj, Tag)
% Return the element of the network with the given tag.
%
% Looks the tag up among the buses, branches, components, local controllers, global
% controllers and scenarios of the network. One tag returns the object; several tags
% return a cell array of the objects, in the order of Tag. A tag that no element has stops
% with GUILDA:PowerNetwork:ElementNotFound, which names it; a tag that two elements share
% (tags are unique only among siblings) stops with GUILDA:PowerNetwork:ElementAmbiguous.
% The network is not changed.
%
% <@Examples>
% ```matlab
% net = network.IEEE9bus();
% gen = net.get_element("B001SG1");                 % the generator on bus B001
% c   = net.get_element(["B001", "B001SG1CA1"]);    % {bus, AVR}
% net.get_element_table(Kind="local")               % the tags of the local controllers
% ```
%
% See also PowerNetwork.get_element_table, PowerNetwork.get_parameter
%
% <@Group> Queries and display
    arguments (Input)
        obj
        Tag (1,:) string  % Tags of the elements.
    end
    arguments (Output)
        obj_elem  % The element (one tag) or a cell array of the elements (several tags).
    end
    c_elem = element_list(obj);
    sv_tag = string(cellfun(@(e) e.s_tag, c_elem, "UniformOutput", false));
    c_out  = cell(size(Tag));
    for i = 1:numel(Tag)
        i_hit = find(sv_tag == Tag(i));
        if isempty(i_hit)
            error(msg("GUILDA:PowerNetwork:ElementNotFound", char(Tag(i)), char(obj.s_tag)))
        elseif numel(i_hit) > 1
            error(msg("GUILDA:PowerNetwork:ElementAmbiguous", char(Tag(i)), ...
                char(strjoin(string(cellfun(@class, c_elem(i_hit), "UniformOutput", false)), ", "))))
        end
        c_out{i} = c_elem{i_hit};
    end
    if isscalar(Tag)
        obj_elem = c_out{1};
    else
        obj_elem = c_out;
    end
end
