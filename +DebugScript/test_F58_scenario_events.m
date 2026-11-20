% F58 シナリオのイベントのクラス (EventBase と 5 つのサブクラス)
%
%   ev = sc.add_fault("B008", [1, 1.05]);       % EventFault を返す (タグ Fault001)
%   ev.edit(Time=[1, 1.1]);                     % 変更。シナリオがすべてのイベントを検査し、失敗なら戻す
%   sc.remove_event(ev.s_tag);                  % 削除
%   sc2 = net.add_scenario("b", Event={EventFault("B008", [1, 1.05])}, From=sc);
%
% イベントの作成、追加、edit (失敗なら元に戻る)、remove_event、add_scenario の Event= と From= での複製、
% JSON の往復、3 つの表の列が変わらないことを確かめる (シナリオ全体の動作は F31)。
%
% 実行: runtests("DebugScript.test_F58_scenario_events")  または  DebugScript.run_all("Features","F58")


%% The constructors make events outside a scenario; the add methods return them
ev = EventFault("B008", [1, 1.05]);
assert(isa(ev, "EventBase") && ev.s_tag == "" && isempty(ev.a_Scenario))
assert(ev.s_status == "BG" && isnan(ev.r_point) && isequal(ev.rr_time, [1, 1.05]))
assert(isequal(EventTrip(["B002SG1"; "B002SG1"], 1).sv_unit, "B002SG1"), "同じ対象は 1 つ")
assert(EventOpenBranch("EL003", 1).s_status == "6open")
ev_o = EventOffset("B001SG1", "delta", 0.1);
assert(ev_o.r_time == 0 && ev_o.s_tag == "")
ev_i = EventInput("B002SG1", "Pmech", table([0; 2], [0; 0.02], 'VariableNames', ["Time","Pmech"]), [1, 3], Tag="ramp");
assert(isequal(ev_i.rm_value, [0, 0; 2, 0.02]) && ev_i.s_method == "foh" && ev_i.s_tag == "ramp")
assert(EventInput("B002SG1", "Pmech", 0.05, [1, 2]).s_method == "")
% コンストラクターは型だけを検査する (時刻の順などは追加の時点)
EventFault("B008", [2, 1]);
assert(error_id(@() EventFault("B008", [1, 2], Status="3open")) == "MATLAB:validators:mustBeMember")
assert(error_id(@() EventInput("B002SG1", "Pmech", 0.1, [1, 2], Method="zoh")) == "GUILDA:EventInput:MethodWithoutSeries")
assert(error_id(@() EventInput("B002SG1", "Pmech", table([0; 1], 'VariableNames', "t"), [1, 2])) == "GUILDA:EventInput:InvalidInputTable")

net = new_ieee14();
sc = net.add_scenario("a", Time=[0, 3]);
ev_f = sc.add_fault("B008", [1, 1.05]);
ev_t = sc.add_trip("B003LPQ2", 1);
ev_b = sc.add_open_branch("EL003", 1.05, Status="3open");
ev_o = sc.add_offset("B001SG1", "delta", 0.1);
ev_i = sc.add_input("B002SG1", "Pmech", 0.05, [1, 2], Tag="step");
assert(isa(ev_f, "EventFault") && isa(ev_t, "EventTrip") && isa(ev_b, "EventOpenBranch") && isa(ev_o, "EventOffset") && isa(ev_i, "EventInput"))
assert(isequal(string(cellfun(@(e) e.s_tag, sc.a_Event, 'UniformOutput', false)).', ["Fault001","Parallel001","Parallel002","offset1","step"]))
assert(all(cellfun(@(e) e.a_Scenario == sc, sc.a_Event)))
assert(error_id(@() set_prop(ev_f, "rr_time", [1, 2])) ~= "", "プロパティは読み取り専用")


%% The tables keep their columns and are built from the events
net = new_ieee14();
sc = net.add_scenario("tables");
assert(isequal(string(sc.tab_event.Properties.VariableNames), ["Tag","Target","Time","Status","Point"]))
assert(isequal(string(sc.tab_offset.Properties.VariableNames), ["Tag","TimeSpan","OffsetUnit","OffsetState","OffsetValue"]))
assert(isequal(string(sc.tab_input.Properties.VariableNames), ["Tag","TimeSpan","InputUnit","InputName","InputValue","InputMethod"]))
assert(height(sc.tab_event) == 0 && isstring(sc.tab_event.Tag) && size(sc.tab_input.TimeSpan, 2) == 2)
sc.add_fault("EL004", [1, 1.05], Status="6LG", Point=0.4);
sc.add_trip(["B003LPQ2"; "B004LPQ1"], 1);
sc.add_offset("B001SG1", ["delta"; "omega"], [0.1; 0], 0.5);
sc.add_input("B002SG1", "Pmech", [0, 0; 1, 0.01], [1, 3], Method="zoh");
tab = sc.tab_event;
assert(isequal(tab.Tag, ["Fault001"; "Fault001"; "Parallel001"; "Parallel001"]))
assert(isequal(tab.Target, ["EL004"; "EL004"; "B003LPQ2"; "B004LPQ1"]), "解列は対象ごとに 1 行")
assert(isequal(tab.Time, [1; 1.05; 1; 1]) && isequal(tab.Status, ["6LG"; "none"; "open"; "open"]))
assert(isequaln(tab.Point, [0.4; 0.4; NaN; NaN]))
assert(sc.tab_offset.TimeSpan == 0.5 && isequal(sc.tab_offset.OffsetState{1}, ["delta"; "omega"]))
assert(isequal(sc.tab_input.TimeSpan, [1, 3]) && sc.tab_input.InputMethod == "zoh" && isequal(sc.tab_input.InputValue{1}, [0, 0; 1, 0.01]))


%% edit changes an event; a failing edit is undone
net = new_ieee14();
sc = net.add_scenario("edit", Time=[0, 3]);
ev = sc.add_fault("B008", [1, 1.05]);
ev2 = sc.add_fault("B008", [2, 2.05]);
ev.edit(Time=[1, 1.1]);
assert(isequal(ev.rr_time, [1, 1.1]) && isequal(sc.tab_event.Time(1:2), [1; 1.1]), "表は Dependent")
% 時刻、重なり、対象、Status と Point の検査: 失敗すれば値は戻る
assert(error_id(@() ev.edit(Time=[2, 1])) == "GUILDA:Scenario:InvalidTimeSpan")
assert(error_id(@() ev.edit(Time=[1, 2.01])) == "GUILDA:Scenario:OverlappingEvents")
assert(error_id(@() ev.edit(Target="B999")) == "GUILDA:Scenario:UnknownFaultTarget")
assert(error_id(@() ev.edit(Target="EL003")) == "GUILDA:Scenario:InvalidFaultStatus")
assert(isequal(ev.rr_time, [1, 1.1]) && ev.sv_target == "B008" && ev.s_status == "BG")
ev.edit(Target="EL003", Status="3LG", Point=0.3);
assert(isequal(sc.tab_event.Status(1:2), ["3LG"; "none"]) && isequal(sc.tab_event.Point(1:2), [0.3; 0.3]))
assert(ev2.s_tag == "Fault002", "Fault のタグは変わらない")
% 解列と開放
tr = sc.add_trip("B003LPQ2", 1);
tr.edit(Unit="B004LPQ1");
assert(isequal(tr.sv_unit, "B004LPQ1"))
assert(error_id(@() tr.edit(Unit="B999")) == "GUILDA:Scenario:UnknownParallelTarget" && tr.sv_unit == "B004LPQ1")
br = sc.add_open_branch("EL005", 1);
br.edit(Status="3open", Time=1.5);
assert(br.s_status == "3open" && br.r_time == 1.5)
assert(error_id(@() br.edit(Time=[1, 2])) ~= "" && br.r_time == 1.5, "時刻は 1 つ")
% オフセット: タグも変えられる。予約語と重複は戻る
os = sc.add_offset("B001SG1", "delta", 0.1);
os.edit(Value=0.2, Time=0.5, Tag="kick");
assert(sc.tab_offset.Tag == "kick" && sc.tab_offset.OffsetValue{1} == 0.2 && sc.tab_offset.TimeSpan == 0.5)
assert(error_id(@() os.edit(Tag="Fault009")) == "GUILDA:Scenario:ReservedTag" && os.s_tag == "kick")
assert(error_id(@() os.edit(State="nosuch")) == "GUILDA:Scenario:UnknownOffsetState" && os.sv_state == "delta")
% 入力: Value だけなら Method は値から決め直す。Method だけなら今の値に使う
in = sc.add_input("B002SG1", "Pmech", [0, 0; 1, 0.01], [1, 3], Tag="in");
assert(error_id(@() os.edit(Tag="in")) == "GUILDA:Scenario:DuplicateTag" && os.s_tag == "kick")
in.edit(Method="zoh");
assert(in.s_method == "zoh" && isequal(in.rm_value, [0, 0; 1, 0.01]))
in.edit(Value=0.05);
assert(in.s_method == "" && in.rm_value == 0.05 && sc.tab_input.InputMethod == "")
assert(error_id(@() in.edit(Method="foh")) == "GUILDA:EventInput:MethodWithoutSeries" && in.s_method == "")
assert(error_id(@() in.edit(Name=["Pmech"; "Vfield"; "x"])) == "GUILDA:Scenario:UnknownInputName" && in.sv_name == "Pmech")
% シナリオにないイベントは検査なしで変わる
ev0 = EventFault("B999", [1, 2]);
ev0.edit(Time=[3, 1]);
assert(isequal(ev0.rr_time, [3, 1]))
% 追加が失敗すれば何も足さない
n_ev = numel(sc.a_Event);
assert(error_id(@() sc.add_trip("B999", 1)) == "GUILDA:Scenario:UnknownParallelTarget" && numel(sc.a_Event) == n_ev)


%% remove_event takes events out of the scenario
net = new_ieee14();
sc = net.add_scenario("rm");
ev = sc.add_fault("B008", [1, 1.05]);
os = sc.add_offset("B001SG1", "delta", 0.1);
sc.add_trip("B003LPQ2", 1);
sc.remove_event([ev.s_tag, os.s_tag]);
assert(numel(sc.a_Event) == 1 && height(sc.tab_event) == 1 && height(sc.tab_offset) == 0)
assert(isempty(ev.a_Scenario) && isempty(os.a_Scenario))
assert(error_id(@() sc.remove_event("Fault001")) == "GUILDA:Scenario:DisturbanceNotFound")
ev.edit(Target="B999");   % 外したイベントは検査されない
assert(ev.sv_target == "B999")
assert(sc.add_fault("B008", [1, 1.05]).s_tag == "Fault001", "使われていない番号")


%% add_scenario copies events from Event= and From=
net = new_ieee14();
ev_f = EventFault("B008", [0.1, 0.17]);
ev_b = EventOpenBranch("EL003", 0.17);
ev_o = EventOffset("B001SG1", "delta", 0.1, Tag="kick");
sc = net.add_scenario("ev", Time=[0, 3], Event={ev_f, ev_b, ev_o});
assert(isequal(string(cellfun(@(e) e.s_tag, sc.a_Event, 'UniformOutput', false)).', ["Fault001","Parallel001","kick"]))
assert(sc.a_Event{1} ~= ev_f && ev_f.s_tag == "" && isempty(ev_f.a_Scenario), "渡したイベントは変わらない")
% From= はタグのまま複製し、Event= は後に足す (Fault/Parallel は番号を振り直す)
sc2 = net.add_scenario("cp", From=sc, Event={EventTrip("B003LPQ2", 1)});
ev_f.edit(Time=[2, 2.1]);
sc3 = net.add_scenario("cp2", From=sc, Event={ev_f});
assert(isequal(unique(sc3.tab_event.Tag, "stable").', ["Fault001","Parallel001","Fault002"]))
assert(isequaln(sc2.tab_offset, sc.tab_offset) && isequal(sc2.Time, [0, 3]))
assert(all(cellfun(@(e) e.a_Scenario == sc2, sc2.a_Event)) && all(cellfun(@(e) e.a_Scenario == sc, sc.a_Event)))
sc2.a_Event{1}.edit(Time=[0.1, 0.2]);
assert(isequal(sc.a_Event{1}.rr_time, [0.1, 0.17]), "複製は元と別のオブジェクト")
% From の既定は Scenario.empty
sc4 = net.add_scenario("none", From=Scenario.empty);
assert(isempty(sc4.a_Event))
% イベントでない要素と、検査に失敗するイベントはシナリオを作らない
n_sc = numel(net.a_Scenario);
assert(error_id(@() net.add_scenario("bad", Event={ev_f, 1})) == "GUILDA:PowerNetwork:NotAnEvent")
assert(error_id(@() net.add_scenario("bad", Event={EventFault("B008", [2, 1])})) == "GUILDA:Scenario:InvalidTimeSpan")
assert(error_id(@() net.add_scenario("bad", Event={ev_o, ev_o})) == "GUILDA:Scenario:DuplicateTag")
assert(numel(net.a_Scenario) == n_sc)
% copy は値とタグを写し、シナリオから外す
cp = copy(sc.a_Event{3});
assert(cp.s_tag == "kick" && isempty(cp.a_Scenario) && cp.rv_value == 0.1)
% シナリオを消してもイベントの edit は使える
ev_k = sc4.add_fault("B008", [1, 2]);
net.remove_scenario("none");
ev_k.edit(Time=[1, 3]);
assert(isequal(ev_k.rr_time, [1, 3]))


%% Scenario files: the events survive a round trip
net = DebugScript.helper.build_ieee14();
sc = net.add_scenario("rt", Time=[0, 5]);
sc.add_fault("EL003", [1, 1.1], Status="3LG", Point=0.3);
sc.add_fault(["B004"; "B005"], [2, 2.05]);
sc.add_trip("B003LPQ2", 1);
sc.add_open_branch("EL005", 1, Status="3open");
sc.add_offset("B001SG1", ["delta"; "omega"], [0.1; 0], 0.5, Tag="kick");
sc.add_input("B002SG1", "Pmech", [0, 0; 1, 0.02], [1, 4], Method="spline");
sc.add_input("B002SG1", "Vfield", 0.01, [2, 3]);
[s_dir, c] = temp_folder(); %#ok<ASGLU>
s_path = DebugScript.helper.quiet(@() net.export(fullfile(s_dir, "Net")));
net2 = DebugScript.helper.quiet(@() PowerNetwork.import(s_path, Initialize=false));
sc2 = net2.a_Scenario{1};
assert(isequaln(sc2.tab_event, sc.tab_event) && isequaln(sc2.tab_offset, sc.tab_offset) && isequaln(sc2.tab_input, sc.tab_input))
assert(isequal(cellfun(@class, sc2.a_Event, 'UniformOutput', false), cellfun(@class, sc.a_Event, 'UniformOutput', false)))
assert(isequal(sc2.a_Event{2}.sv_target, ["B004"; "B005"]))
% 1 つのタグの行が 1 つのイベントにならなければ InvalidEventRows
s_file = fullfile(s_path, "scenario", "rt.json");
writelines(['{"Format": "GUILDAscenario", "version": 2, "Event": [' ...
            '{"Tag": "Fault001", "Target": "B004", "Time": 1, "Status": "BG"}, {"Tag": "Fault001", "Target": "B004", "Time": 2, "Status": "none"}, ' ...
            '{"Tag": "Fault001", "Target": "B005", "Time": 1, "Status": "BG"}, {"Tag": "Fault001", "Target": "B005", "Time": 3, "Status": "none"}]}'], s_file);
assert(error_id(@() PowerNetwork.import(s_path, Initialize=false)) == "GUILDA:Scenario:InvalidEventRows")
% 同じタグのオフセットと入力は DuplicateTag
writelines(['{"Format": "GUILDAscenario", "version": 2, ' ...
            '"Offset": [{"Tag": "k", "TimeSpan": [1], "OffsetUnit": "B001SG1", "OffsetState": ["delta"], "OffsetValue": [0.1]}], ' ...
            '"Input": [{"Tag": "k", "TimeSpan": [1, 2], "InputUnit": "B002SG1", "InputName": ["Pmech"], "InputValue": [0.1]}]}'], s_file);
assert(error_id(@() PowerNetwork.import(s_path, Initialize=false)) == "GUILDA:Scenario:DuplicateTag")


function id = error_id(f)
    id = "";
    try
        DebugScript.helper.quiet(f);
    catch me
        id = string(DebugScript.helper.msg_id(me));
    end
end

function set_prop(obj, s_name, val)
    obj.(s_name) = val;
end

function net = new_ieee14()
    net = DebugScript.helper.build_ieee14();
    DebugScript.helper.quiet(@() net.initialize);
end

function [s_dir, c] = temp_folder()
    s_dir = tempname;
    mkdir(s_dir);
    c = onCleanup(@() rmdir(s_dir, "s"));
end
