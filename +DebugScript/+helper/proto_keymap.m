function tab = proto_keymap(category, opt)
% Prototype of GUILDA.keymap: model key -> class table of a category, cached
%
% Scratch helper for the completion checks (DebugScript.manual_keymap_completion); not product
% code. The list is built from GUILDA.dictionary and the Constant `key` of each class,
% and kept in a persistent variable until Refresh=true.
%
% >> tab = DebugScript.helper.proto_keymap("Component");    % columns key, class
    arguments (Input)
        category    (1,1) string {mustBeMember(category, ["Component","Branch","LocalController","GlobalController"])}   % Model category.
        opt.Refresh (1,1) logical = false   % Rebuild the cache from the classes on the path.
    end
    arguments (Output)
        tab   % Table with the columns key (string) and class (string), in dictionary order.
    end
    persistent sct_cache
    if opt.Refresh || isempty(sct_cache)
        sv_cat = ["Component","Branch","LocalController","GlobalController"];
        c_tab  = GUILDA.dictionary("PowerSystemModel", "disp", false, "output", sv_cat);
        sct_cache = struct();
        for i = 1:numel(sv_cat)
            sv_class = string(c_tab{i}.filename);
            sv_key   = strings(size(sv_class));
            for k = 1:numel(sv_class)
                mc = meta.class.fromName(sv_class(k));
                pr = mc.PropertyList(string({mc.PropertyList.Name}) == "key");
                if ~isempty(pr) && pr.Constant && ~pr.Abstract && ~isempty(pr.DefaultValue)
                    sv_key(k) = string(pr.DefaultValue);
                end
            end
            lv = sv_key ~= "";
            sct_cache.(sv_cat(i)) = table(sv_key(lv), sv_class(lv), 'VariableNames', ["key","class"]);
        end
    end
    tab = sct_cache.(category);
end
