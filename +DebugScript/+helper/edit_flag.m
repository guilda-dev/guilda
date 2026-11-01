function flag = edit_flag(obj)
% LayerPackage の編集状態 s_edit.str_flag ("unset"/"initialized"/"editted") を読む
%
%   flag = DebugScript.helper.edit_flag(net)
    flag = string(obj.s_edit.str_flag);
end
