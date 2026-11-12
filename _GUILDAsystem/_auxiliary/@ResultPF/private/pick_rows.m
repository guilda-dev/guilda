function iv = pick_rows(sv_all, sv_given, s_kind)
% Rows of the tags sv_given in sv_all (all rows when sv_given is empty); an unknown tag
% stops with GUILDA:ResultPF:UnknownTag
    arguments (Input)
        sv_all   (:,1) string  % Tags of the rows, in order.
        sv_given (1,:) string  % Tags asked for; empty for all.
        s_kind   (1,1) string  % "bus" or "branch", for the message.
    end
    arguments (Output)
        iv (:,1) double        % Row numbers, in the order of sv_all.
    end
    if isempty(sv_given)
        iv = (1:numel(sv_all))';
        return
    end
    lv_known = ismember(sv_given, sv_all);
    if ~all(lv_known)
        error(msg("GUILDA:ResultPF:UnknownTag", char(s_kind), char(join(sv_given(~lv_known), ", "))))
    end
    iv = find(ismember(sv_all, sv_given));
end
