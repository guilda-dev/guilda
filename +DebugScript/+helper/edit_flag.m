function flag = edit_flag(obj)
% LayerPackage の編集状態 str_editFlag ("unset"/"initialized"/"editted") を読む
%
%   flag = DebugScript.helper.edit_flag(net)
%
% str_editFlag は protected なので、テスト用に builtin struct で取り出す。
    w = warning("off", "MATLAB:structOnObject");
    c = onCleanup(@() warning(w));
    s = builtin("struct", obj);
    flag = string(s.str_editFlag);
end
