function s_tag = no_disturbance(net)
% 外乱のないシナリオを系統に作り、そのタグを返す (旧 net.simulate([t0,tend]) の書き換え用)
%
%   sol = net.simulate(DebugScript.helper.no_disturbance(net), Time=[0,5]);
%
% タグは "free"。系統に同じタグのシナリオがあれば free_2, free_3, ... にする。
% 母線などの子と重なったときは net.add_scenario が番号を足す。
    arguments (Input)
        net  % 電力系統
    end
    arguments (Output)
        s_tag (1,1) string  % 追加したシナリオのタグ
    end
    sv_have = string(cellfun(@(s) s.s_tag, net.a_Scenario, 'UniformOutput', false));
    s_tag = "free";
    n = 1;
    while ismember(s_tag, sv_have)
        n = n + 1;
        s_tag = "free_" + n;
    end
    s_tag = string(net.add_scenario(s_tag).s_tag);
end
