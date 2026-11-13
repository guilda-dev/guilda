function sc = scenario(tag, net, varargin)
% 外乱 1 つのシナリオ (Scenario) を系統に作る (旧 ODEevent(tag, net, ...) の書き換え用)
%
%   sc  = DebugScript.helper.scenario("fault", net, "TimeSpan", [1,1.05], "FaultBus", "B008");
%   sol = net.simulate(sc.s_tag, Time=[0,5]);
%
% Name-Value の FaultBus, TripUnit, OpenBranch はそれぞれ sc.add_fault, sc.add_trip,
% sc.add_open_branch に TimeSpan で渡す (タグは Fault001, Parallel001, ...。sc.tab_event.Tag で読む)。
% 残りの Name-Value (TimeSpan と Offset*, Input*) は Scenario.add_disturbance(tag, ...) に渡す。
% FaultBus, TripUnit, OpenBranch がなければ、オフセットと入力がなくても add_disturbance を呼ぶ
% (タグ tag は output.phases の列名)。スカラーの TimeSpan は [t, t] として add_fault などに渡す。
% シナリオのタグも tag だが、系統に同じタグのシナリオがあれば tag_2, tag_3, ... にする
% (旧 ODEevent と同じく、同じタグで何度でも作れる)。母線などの子と重なったときは
% net.add_scenario が番号を足す。検査は追加の時点で行われ、失敗したらシナリオを削除する。
    arguments (Input)
        tag  % タグの接尾辞
        net  % 電力系統
    end
    arguments (Input, Repeating)
        varargin  % Name-Value (TimeSpan, FaultBus, TripUnit, OpenBranch, Offset*, Input*)
    end
    arguments (Output)
        sc  % 追加したシナリオ
    end
    s_sc = tag;
    if strlength(s_sc) == 0
        s_sc = "event";
    end
    sv_have = string(cellfun(@(s) s.s_tag, net.a_Scenario, 'UniformOutput', false));
    n = 1;
    while ismember(s_sc, sv_have)
        n = n + 1;
        s_sc = tag + "_" + n;
    end
    sc = net.add_scenario(s_sc);    % 外乱は系統に対して旧 ODEevent と同じ順で検査される
    try
        sv_name = string(varargin(1:2:end));
        c_value = varargin(2:2:end);
        time = [0, 10];
        if ismember("TimeSpan", sv_name)
            time = c_value{find(sv_name == "TimeSpan", 1, "last")};
        end
        sr_event = ["FaultBus", "TripUnit", "OpenBranch"];
        c_add = {@(x) sc.add_fault(x, time([1, end])), @(x) sc.add_trip(x, time([1, end])), ...
                 @(x) sc.add_open_branch(x, time([1, end]))};
        for k = 1:numel(sr_event)
            if ismember(sr_event(k), sv_name)
                c_add{k}(string(c_value{find(sv_name == sr_event(k), 1, "last")}));
            end
        end
        lv_rest = ~ismember(sv_name, sr_event);
        if ~any(ismember(sr_event, sv_name)) || any(~ismember(sv_name(lv_rest), "TimeSpan"))
            c_nv = [cellstr(sv_name(lv_rest)); c_value(lv_rest)];
            sc.add_disturbance(tag, c_nv{:});
        end
    catch ME
        net.remove_scenario(sc.s_tag);
        rethrow(ME)
    end
end
