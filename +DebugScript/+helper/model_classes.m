function tab = model_classes(group)
% GUILDA.dictionary が見つけた具象モデルクラスの一覧を返す
%
%   tab = DebugScript.helper.model_classes("Component")   % tab.Class, tab.Key
%
% 手書きのキー一覧の代わりに使うと、新しいクラスは追加するだけで試験の対象になる。
% 読み込めないクラスを dictionary は警告だけで除くので、試験から漏れないようにエラーにする。
    arguments (Input)
        group (1,1) string {mustBeMember(group, ["Component","Branch","LocalController","GlobalController"])}
    end
    arguments (Output)
        tab  % クラス名 Class とキー Key の表
    end
    lastwarn("");
    list = GUILDA.dictionary("PowerSystemModel", "disp", false, "output", group);
    [str_warn, str_id] = lastwarn(); str_id = DebugScript.helper.msg_id(str_warn, str_id);
    if str_id == "GUILDA:dictionary:ClassNotLoaded"
        error("DebugScript:ModelNotLoaded", "%s", str_warn);
    end

    sv_class = reshape(string(list.filename), [], 1);
    lv = arrayfun(@(c) ~meta.class.fromName(c).Abstract, sv_class);
    Class = sv_class(lv);
    Key = arrayfun(@default_key, Class);
    tab = table(Class, Key);
end


function str_key = default_key(str_class)
    arguments (Input)
        str_class  % クラス名
    end
    arguments (Output)
        str_key  % クラスの既定のキー
    end
    prop = findobj(meta.class.fromName(str_class).PropertyList, "Name", "key");
    str_key = "";
    if ~isempty(prop) && prop.HasDefault && ~isempty(prop.DefaultValue)
        str_key = string(prop.DefaultValue);
    end
end
