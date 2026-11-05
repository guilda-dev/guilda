function tab = model_classes(group)
% GUILDA.dictionary が見つけた具象モデルクラスの一覧を返す
%
%   tab = DebugScript.helper.model_classes("Component")   % tab.Class, tab.Key
%
% 手書きのキー一覧の代わりに使うと、新しいクラスは追加するだけで試験の対象になる。
% 読み込めないクラスを dictionary は警告だけで除くので、試験から漏れないようにエラーにする。
    arguments
        group (1,1) string {mustBeMember(group, ["Component","Branch","LocalController","GlobalController"])}
    end
    lastwarn("");
    list = GUILDA.dictionary("PowerSystemModel", "disp", false, "output", group);
    [s_warn, s_id] = lastwarn(); s_id = DebugScript.helper.msg_id(s_warn, s_id);
    if s_id == "GUILDA:dictionary:ClassNotLoaded"
        error("DebugScript:ModelNotLoaded", "%s", s_warn);
    end

    sv_class = reshape(string(list.filename), [], 1);
    lv = arrayfun(@(c) ~meta.class.fromName(c).Abstract, sv_class);
    Class = sv_class(lv);
    Key = arrayfun(@default_key, Class);
    tab = table(Class, Key);
end


function s_key = default_key(s_class)
    prop = findobj(meta.class.fromName(s_class).PropertyList, "Name", "key");
    s_key = "";
    if ~isempty(prop) && prop.HasDefault && ~isempty(prop.DefaultValue)
        s_key = string(prop.DefaultValue);
    end
end
