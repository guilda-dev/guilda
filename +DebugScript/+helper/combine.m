function sc = combine(net, varargin)
% 複数のシナリオの外乱を 1 つのシナリオにまとめて系統に作る (旧 net.simulate(t, sc1, sc2, ...) の書き換え用)
%
%   sc  = DebugScript.helper.combine(net, ev1, ev2);
%   sol = net.simulate(sc.s_tag, Time=[0,5]);
%
% 1 つ目のシナリオを From で複製し (Time, Description も)、残りのシナリオの外乱を順に足す。
% tab_event の外乱はタグごとに add_fault, add_trip, add_open_branch で足し直す (タグは番号が振り直される)。
% tab_offset と tab_input の行は add_offset, add_input でタグのまま足す。
% 外乱は系統に対して追加の時点と同じ検査を受ける。失敗したらシナリオを削除する。
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
            tab = varargin{k}.tab_event;
            for s_ev = reshape(unique(tab.Tag, "stable"), 1, [])
                tab_t = tab(tab.Tag == s_ev, :);
                sv_target = unique(tab_t.Target, "stable");
                time   = tab_t.Time(1:min(2, end)).';   % 解列と開放は 1 行 (time(1) だけ使う)
                s_status = tab_t.Status(1);
                if s_status == "open"
                    sc.add_trip(sv_target, time(1));
                elseif ismember(s_status, ["3open", "6open"])
                    sc.add_open_branch(sv_target, time(1), Status=s_status);
                elseif s_status == "BG"
                    sc.add_fault(sv_target, time);
                else
                    sc.add_fault(sv_target, time, Status=s_status, Point=tab_t.Point(1));
                end
            end
            tab_o = varargin{k}.tab_offset;
            for r = 1:height(tab_o)
                sc.add_offset(tab_o.OffsetUnit(r), tab_o.OffsetState{r}, tab_o.OffsetValue{r}, tab_o.TimeSpan(r), Tag=tab_o.Tag(r));
            end
            tab_i = varargin{k}.tab_input;
            for r = 1:height(tab_i)
                c_opt = {};
                if tab_i.InputMethod(r) ~= ""
                    c_opt = {"Method", tab_i.InputMethod(r)};
                end
                sc.add_input(tab_i.InputUnit(r), tab_i.InputName{r}, tab_i.InputValue{r}, tab_i.TimeSpan(r,:), c_opt{:}, Tag=tab_i.Tag(r));
            end
        end
    catch ME
        net.remove_scenario(sc.s_tag);
        rethrow(ME)
    end
end
