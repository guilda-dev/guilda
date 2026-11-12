function sc = scenario(tag, net, varargin)
% 外乱 1 つのシナリオ (Scenario) を系統に作る (旧 ODEevent(tag, net, ...) の書き換え用)
%
%   sc  = DebugScript.helper.scenario("fault", net, "TimeSpan", [1,1.05], "FaultBus", "B008");
%   sol = net.simulate([0,5], sc);
%
% 外乱のタグは tag (output.phases の列名)。シナリオのタグも tag だが、系統に同じタグの
% シナリオがあれば tag_2, tag_3, ... にする (旧 ODEevent と同じく、同じタグで何度でも作れる)。
% 母線などの子と重なったときは net.add_scenario が番号を足す。
% 引数は Scenario.add_disturbance の Name-Value。検査は追加の時点で行われ、失敗したらシナリオを削除する。
    arguments (Input)
        tag  % タグの接尾辞
        net  % 電力系統
    end
    arguments (Input, Repeating)
        varargin  % Scenario.add_disturbance の Name-Value
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
        sc.add_disturbance(tag, varargin{:});
    catch ME
        net.remove_scenario(sc.s_tag);
        rethrow(ME)
    end
end
