function flag = edit_flag(net)
% PowerNetwork の編集状態を "unset" (initialize 前) / "initialized" (編集なし) / "editted" (編集あり) で返す
% (sct_edit.l_initialized と tab_editLog から求める)
%
%   flag = DebugScript.helper.edit_flag(net)
    if ~net.sct_edit.l_initialized
        flag = "unset";
    elseif height(net.tab_editLog) > 0
        flag = "editted";
    else
        flag = "initialized";
    end
end
