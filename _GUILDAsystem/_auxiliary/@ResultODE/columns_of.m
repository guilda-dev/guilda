function iv = columns_of(obj, tab_map)
% Columns of rm_variable for the rows of tab_map (matched by Kind, Owner, Name, Bus)
    f_key = @(T) string(T.Kind) + "|" + string(T.Owner) + "|" + string(T.Name) + "|" + string(T.Bus);
    if height(tab_map) == 0
        iv = zeros(0,1);
        return
    end
    if ~all(ismember(["Kind","Owner","Name","Bus"], string(tab_map.Properties.VariableNames)))
        error(msg("GUILDA:ResultODE:InvalidMap"))
    end
    [lv, iv] = ismember(f_key(tab_map), f_key(obj.tab_variable));
    if ~all(lv)
        sv_label = string(tab_map.Label(~lv));
        error(msg("GUILDA:ResultODE:UnknownVariable", join(sv_label(1:min(end,5)), ", ")))
    end
end
