function lv_below = elements_below(net, sv_tag, sv_parent, s_owner)
% Rows of the elements below the element s_owner (children, their children, ...; not
% s_owner itself), from the tags and parent tags of element_list.
%
% Shared by get_element_table and get_parameter. An s_owner that is not a tag stops with
% GUILDA:PowerNetwork:ElementNotFound.
    arguments (Input)
        net       PowerNetwork    % Network of the elements (for the message).
        sv_tag    (:,1) string    % Tags of the elements.
        sv_parent (:,1) string    % Tag of the parent of each element ("" under the network).
        s_owner   (1,1) string    % Tag of the owner element.
    end
    arguments (Output)
        lv_below (:,1) logical    % True for the elements below s_owner.
    end
    if ~any(sv_tag == s_owner)
        error(msg("GUILDA:PowerNetwork:ElementNotFound", char(s_owner), char(net.s_tag)))
    end
    % s_owner is among the ancestors: the parent, its parent, ...
    lv_below = false(size(sv_tag));
    sv_up = sv_parent;
    while any(sv_up ~= "")
        lv_below = lv_below | sv_up == s_owner;
        [~, iv_up] = ismember(sv_up, sv_tag);
        sv_up(iv_up > 0)  = sv_parent(iv_up(iv_up > 0));
        sv_up(iv_up == 0) = "";
    end
end
