function ev = noop_event(net, tspan)
% 何もしないイベント (時間区間だけを持つ odeEventSet) を作成する
%
%   ev  = DebugScript.helper.noop_event(net, [0,5]);
%   sol = net.simulate([0,5], ev);
%
% net.simulate はイベントを1つも渡さないとエラーになるため
% (test_F6_simulation の既知の不具合参照)、外乱なしの応答はこのイベントで計算する。
    ev = odeEventSet("noop", net, "TimeSpan", tspan);
end
