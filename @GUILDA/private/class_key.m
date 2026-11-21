function s_key = class_key(s_class)
% Return the model key of a class: the Constant `key` of a concrete class.
%
% GUILDA.dictionary reads the key of each class it finds with this function, and
% GUILDA.keymap takes the keys from the table of GUILDA.dictionary.
%
% See also GUILDA.dictionary, GUILDA.keymap
    arguments (Input)
        s_class (1,1) string  % Class name with its packages.
    end
    arguments (Output)
        s_key  % Model key; "" for an abstract class, a class without a key, or a class that cannot be loaded.
    end
    s_key = "";
    mc = meta.class.fromName(s_class);
    if isempty(mc) || mc.Abstract
        return
    end
    pr = mc.PropertyList(string({mc.PropertyList.Name}) == "key");
    if ~isempty(pr) && pr.Constant && ~pr.Abstract && ~isempty(pr.DefaultValue)
        s_key = string(pr.DefaultValue);
    end
end
