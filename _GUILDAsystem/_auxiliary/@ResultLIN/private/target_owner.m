function sv_select = target_owner(tab_owner, target)
% Tags of the elements that target names: a tag, a class (with its subclasses) or a
% package (get_contribution, get_reduced_matrix)
    arguments (Input)
        tab_owner table          % Owner and Class of each element (sct_sys.tab_owner of a section).
        target    (1,:) string   % Tags and class (or package) names.
    end
    arguments (Output)
        sv_select (:,1) string   % Tags of the selected elements.
    end
    lv_own = false(height(tab_owner),1);
    sv_class = unique(tab_owner.Class);
    c_super = cell(size(sv_class));
    for k = 1:numel(sv_class)
        c_super{k} = [sv_class(k); reshape(string(superclasses(char(sv_class(k)))), [], 1)];
    end
    for t = target
        lv_t = tab_owner.Owner == t;
        if ~any(lv_t)
            lv_cls = cellfun(@(c) any(c == t) || any(startsWith(c, t + ".")), c_super);
            lv_t = ismember(tab_owner.Class, sv_class(lv_cls));
        end
        if ~any(lv_t)
            error(msg("GUILDA:ResultLIN:UnknownTarget", t))
        end
        lv_own = lv_own | lv_t;
    end
    sv_select = tab_owner.Owner(lv_own);
end
