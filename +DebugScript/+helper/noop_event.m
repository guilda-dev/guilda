function ev = noop_event(net, tspan)
% 外乱のないシナリオを系統に作り、Time を時間区間にする
%
%   ev  = DebugScript.helper.noop_event(net, [0,5]);
%   sol = net.simulate(ev.s_tag, Time=[0,5]);
%
    arguments (Input)
        net    % 電力系統
        tspan  % [s] 時間区間
    end
    arguments (Output)
        ev  % 追加したシナリオ
    end
    ev = DebugScript.helper.scenario("noop", net);
    if numel(tspan) == 2
        ev.Time = tspan;
    end
end
