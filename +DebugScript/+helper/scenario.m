function sc = scenario(tag, net, varargin)
% 外乱 1 つのシナリオ (Scenario) を系統に作る (旧 ODEevent(tag, net, ...) の書き換え用)
%
%   sc  = DebugScript.helper.scenario("fault", net, "TimeSpan", [1,1.05], "FaultBus", "B008");
%   sol = net.simulate(sc.s_tag, Time=[0,5]);
%
% Name-Value の FaultBus は sc.add_fault に TimeSpan で、TripUnit, OpenBranch は sc.add_trip,
% sc.add_open_branch に TimeSpan(1) で渡す (解列と開放は終わりまで続く。タグは Fault001,
% Parallel001, ...。sc.tab_event.Tag で読む)。
% Offset* は sc.add_offset(OffsetUnit, OffsetState, OffsetValue, TimeSpan(1), Tag=tag) に、
% Input* は sc.add_input(InputUnit, InputName, InputValue, TimeSpan, Method=InputMethod, Tag=tag) に渡す
% (与えない項目は空の値)。スカラーの TimeSpan は [t, t] として add_fault や add_input に渡す。
% 外乱の指定がなければ外乱のないシナリオになる。
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
    sc = net.add_scenario(s_sc);
    try
        d = struct("TimeSpan", [0, 10], "OffsetUnit", "", "OffsetState", strings(0,1), "OffsetValue", zeros(0,1), ...
                   "InputUnit", "", "InputName", strings(0,1), "InputValue", zeros(0,1));
        sv_name = string(varargin(1:2:end));
        for k = 1:numel(sv_name)
            d.(sv_name(k)) = varargin{2*k};
        end
        time = d.TimeSpan([1, end]);
        if isfield(d, "FaultBus")
            sc.add_fault(string(d.FaultBus), time);
        end
        if isfield(d, "TripUnit")
            sc.add_trip(string(d.TripUnit), time(1));
        end
        if isfield(d, "OpenBranch")
            sc.add_open_branch(string(d.OpenBranch), time(1));
        end
        if any(startsWith(sv_name, "Offset"))
            sc.add_offset(d.OffsetUnit, d.OffsetState, d.OffsetValue, time(1), Tag=tag);
        end
        if any(startsWith(sv_name, "Input"))
            c_opt = {};
            if isfield(d, "InputMethod")
                c_opt = {"Method", d.InputMethod};
            end
            sc.add_input(d.InputUnit, d.InputName, d.InputValue, time, c_opt{:}, Tag=tag);
        end
    catch ME
        net.remove_scenario(sc.s_tag);
        rethrow(ME)
    end
end
