function dic = keymap(category)
% Return the model keys of a category and the names of their classes.
%
% The keys are the column Key of the table of GUILDA.dictionary: the Constant property
% `key` of the concrete classes under the category (a class without a key is left out).
% The result is a dictionary from the key (string) to the class name (string). The caller makes the
% constructor handle with str2func, because a model constructor may be accessible only
% from the class that builds it (e.g. `Access={?Bus}`). The map is built on the first
% call and kept until GUILDA.update_keymap rebuilds it, so a new model class is found
% after `GUILDA.update_keymap` (also run at startup).
%
% <@Examples>
% ```matlab
% dic = GUILDA.keymap("Component");
% keys(dic)                          % "gen-classical", "gen-park", ...
% dic("gen-park")                    % "component.generator.park"
% ```
%
% See also GUILDA.update_keymap, GUILDA.dictionary, tools.mustBeKeyOf
    arguments (Input)
        category (1,1) string {mustBeMember(category, ["Component","Branch","LocalController","GlobalController"])}  % Model category.
    end
    arguments (Output)
        dic  % dictionary: model key (string) -> class name (string).
    end
    persistent sct_cache
    if isempty(sct_cache)
        sct_cache = build_cache();
    end
    dic = sct_cache.(category);
end

function sct_cache = build_cache()
    % One dictionary per category, from the classes and keys found by GUILDA.dictionary
    arguments (Output)
        sct_cache  % struct: category -> dictionary of model key -> class name.
    end
    sv_cat = ["Component", "Branch", "LocalController", "GlobalController"];
    c_tab  = GUILDA.dictionary("PowerSystemModel", "disp", false, "output", sv_cat);
    sct_cache = struct();
    for i = 1:numel(sv_cat)
        sv_class = reshape(string(c_tab{i}.filename), [], 1);
        sv_key   = reshape(string(c_tab{i}.Key), [], 1);
        lv = sv_key ~= "";
        sct_cache.(sv_cat(i)) = dictionary(sv_key(lv), sv_class(lv));
    end
end
