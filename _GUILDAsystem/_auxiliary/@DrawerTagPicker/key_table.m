function tab = key_table(s_category)
% Return one row per model key of a category: the key, its class and the first help line of the class.
%
% The rows are the keys of GUILDA.keymap(s_category), sorted by Key. Description is the
% first comment line of the class file (its H1 line). The table is kept for the MATLAB
% session, because reading the class files is slow; it is rebuilt when the classes of the
% key map change (after GUILDA.update_keymap finds a new model class).
%
% <@Examples>
% ```matlab
% tab = DrawerTagPicker.key_table("Component")      % Key, Class, Description
% s_key = DrawerTagPicker.pick(fig, tab, Column="Key", Title="Component type");
% ```
%
% See also DrawerTagPicker.pick, GUILDA.keymap
    arguments (Input)
        s_category (1,1) string {mustBeMember(s_category, ["Component","Branch","LocalController","GlobalController"])}  % Model category of GUILDA.keymap.
    end
    arguments (Output)
        tab table  % One row per key: Key, Class, Description (strings).
    end
    persistent sct_cache
    if isempty(sct_cache)
        sct_cache = struct();
    end
    dic = GUILDA.keymap(s_category);
    [Key, iv_order] = sort(reshape(keys(dic), [], 1));
    Class = reshape(values(dic), [], 1);
    Class = Class(iv_order);
    if isfield(sct_cache, s_category) && isequal(sct_cache.(s_category).Key, Key) && isequal(sct_cache.(s_category).Class, Class)
        tab = sct_cache.(s_category);
        return
    end
    Description = strings(numel(Key), 1);
    for i = 1:numel(Key)
        s_file = which(Class(i));
        if s_file == "" || ~isfile(s_file)
            continue
        end
        sv_line = strtrim(readlines(s_file));
        i_help = find(startsWith(sv_line, "%"), 1);
        if ~isempty(i_help)
            Description(i) = strtrim(extractAfter(sv_line(i_help), "%"));
        end
    end
    tab = table(Key, Class, Description);
    sct_cache.(s_category) = tab;
end
