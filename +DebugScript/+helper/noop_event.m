function ev = noop_event(net, tspan)
% 何もしない外乱 (時間区間だけを持つ外乱) のシナリオを系統に作り、Time を時間区間にする
%
%   ev  = DebugScript.helper.noop_event(net, [0,5]);
%   sol = net.simulate([0,5], ev);
%
% 外乱なしの応答は net.simulate([0,5]) でも計算できるが、時間区間を外乱で与える
% テストのためにこのシナリオを使う。
    arguments (Input)
        net    % 電力系統
        tspan  % [s] 時間区間
    end
    arguments (Output)
        ev  % 追加したシナリオ
    end
    ev = DebugScript.helper.scenario("noop", net, "TimeSpan", tspan);
    if numel(tspan) == 2
        ev.Time = tspan;
    end
end
