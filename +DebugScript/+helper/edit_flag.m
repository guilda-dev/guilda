function flag = edit_flag(net)
% PowerNetwork の編集状態を "unset" (initialize 前) / "initialized" (編集なし) / "editted" (編集あり) で返す
% (l_initialized と disp_edit から求める)
%
%   flag = DebugScript.helper.edit_flag(net)
    arguments (Input)
        net
    end
    arguments (Output)
        flag  % 編集状態 ("unset" / "initialized" / "editted")
    end
    if ~net.l_initialized
        flag = "unset";
    elseif height(net.disp_edit()) > 0
        flag = "editted";
    else
        flag = "initialized";
    end
end
