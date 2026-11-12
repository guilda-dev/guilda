function sc = combine(net, varargin)
% 複数のシナリオの外乱を 1 つのシナリオにまとめて系統に作る (旧 net.simulate(t, sc1, sc2, ...) の書き換え用)
%
%   sc  = DebugScript.helper.combine(net, ev1, ev2);
%   sol = net.simulate(sc.s_tag, Time=[0,5]);
%
% 1 つ目のシナリオを From で複製し (Time, Description も)、残りのシナリオの外乱を順に足す。
% 外乱は系統に対して add_disturbance と同じ検査を受ける。失敗したらシナリオを削除する。
% タグは "combined" (重なれば combined_2, ...)。
    arguments (Input)
        net  % 電力系統
    end
    arguments (Input, Repeating)
        varargin  % まとめるシナリオ (Scenario)
    end
    arguments (Output)
        sc  % 追加したシナリオ
    end
    sv_have = string(cellfun(@(s) s.s_tag, net.a_Scenario, 'UniformOutput', false));
    s_tag = "combined";
    n = 1;
    while ismember(s_tag, sv_have)
        n = n + 1;
        s_tag = "combined_" + n;
    end
    sc = net.add_scenario(s_tag, From=varargin{1});
    try
        for k = 2:numel(varargin)
            tab = varargin{k}.tab_disturbance;
            sv_var = string(tab.Properties.VariableNames(2:end));
            for r = 1:height(tab)
                c_nv = cell(1, 0);
                for s_var = sv_var
                    x = tab.(s_var)(r,:);
                    if iscell(x)
                        x = x{1};
                    end
                    if s_var == "InputMethod" && x == ""
                        continue
                    end
                    c_nv = [c_nv, {s_var, x}]; %#ok<AGROW>
                end
                sc.add_disturbance(tab.Tag(r), c_nv{:});
            end
        end
    catch ME
        net.remove_scenario(sc.s_tag);
        rethrow(ME)
    end
end
