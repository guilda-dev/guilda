function flag = edit_flag(net)
% PowerNetwork の状態を "unset" (initialize 前) / "initialized" (最新) / "editted" (古いものがある) で返す
% (sct_stale から求める。初期メッセージ "initialize has not been run" があれば "unset")
%
%   flag = DebugScript.helper.edit_flag(net)
    arguments (Input)
        net
    end
    arguments (Output)
        flag  % 状態 ("unset" / "initialized" / "editted")
    end
    sv = DebugScript.helper.stale(net);
    if any(sv == net.s_notInitialized)
        flag = "unset";
    elseif ~isempty(sv)
        flag = "editted";
    else
        flag = "initialized";
    end
end
