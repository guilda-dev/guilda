function flag = edit_flag(obj)
% LayerPackage の編集状態 s_edit.str_flag ("unset"/"initialized"/"editted") を読む
%
%   flag = DebugScript.helper.edit_flag(net)
    arguments (Input)
        obj
    end
    arguments (Output)
        flag  % 編集状態 s_edit.str_flag
    end
    flag = string(obj.s_edit.str_flag);
end
