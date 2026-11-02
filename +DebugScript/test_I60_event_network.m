% I60 イベントと系統の対応 (ODEevent)
%
% イベントが生成時の系統の写しに依存せず、他の系統のイベントとタグの問題が明示エラーになることを確認する。
%
% 実行: runtests("DebugScript.test_I60_event_network")  または  DebugScript.run_all("Features","I60")

% 共通設定 (各テストの前に毎回実行される)
net = DebugScript.helper.build_ieee14();
DebugScript.helper.quiet(@() net.initialize);


%% An event created before a topology change gives the same result as a new one
args = {"TimeSpan", [1,1.05], "FaultBus", "B008"};
old = ODEevent("fault", net, args{:});
net.a_Bus{1}.a_Component{1}.add_local_controller(controller.avr.AVR_ST1("avr1"));
DebugScript.helper.quiet(@() net.initialize);
r_old = DebugScript.helper.quiet(@() net.simulate([0,2], old));
r_new = DebugScript.helper.quiet(@() net.simulate([0,2], ODEevent("fault", net, args{:})));
assert(isequaln(r_old.odeResults, r_new.odeResults))


%% An event created before adding a global controller still works
old = ODEevent("fault", net, "TimeSpan", [1,1.05], "FaultBus", "B008");
net.add_global_controller(controller.agc.broadcast_PI_AGC(net, "agc", "SG1B001", "SG1B002"));
DebugScript.helper.quiet(@() net.initialize);
[~, flag] = DebugScript.helper.quiet(@() net.simulate([0,2], old));
assert(flag == 1)


%% An event of another network is rejected, even with the same structure
other = DebugScript.helper.build_ieee14();
DebugScript.helper.quiet(@() other.initialize);
ev = ODEevent("fault", other, "TimeSpan", [1,1.05], "FaultBus", "B008");
assert(error_id(@() net.simulate([0,2], ev)) == "GUILDA:ODEevent:OtherNetwork")
% 2 番目以降のイベントも検査する
ok = ODEevent("ok", net, "TimeSpan", [1,1.05], "FaultBus", "B008");
assert(error_id(@() net.simulate([0,2], ok, ev)) == "GUILDA:ODEevent:OtherNetwork")


%% Duplicate tags
ev1 = ODEevent("same", net, "TimeSpan", [1,1.05], "FaultBus", "B008");
ev2 = ODEevent("same", net, "TimeSpan", [2,2.05], "FaultBus", "B003");
assert(error_id(@() net.simulate([0,3], ev1, ev2)) == "GUILDA:ODEevent:DuplicateTag")


%% Reserved tags
for tag = ["t1","t2","NoAction1","NoAction12","Properties","Row","Variables",""]
    ev = ODEevent(tag, net, "TimeSpan", [1,1.05], "FaultBus", "B008");
    assert(error_id(@() net.simulate([0,2], ev)) == "GUILDA:ODEevent:ReservedTag")
end
% 予約名に似ているだけのタグは使える
ev = ODEevent("NoAction", net, "TimeSpan", [1,1.05], "FaultBus", "B008");
[~, flag] = DebugScript.helper.quiet(@() net.simulate([0,2], ev));
assert(flag == 1)


%% An event array is rejected
ev1 = ODEevent("a", net, "TimeSpan", [1,1.05], "FaultBus", "B008");
ev2 = ODEevent("b", net, "TimeSpan", [2,2.05], "FaultBus", "B003");
assert(error_id(@() net.simulate([0,3], [ev1,ev2])) == "GUILDA:ODEevent:EventArray")
assert(error_id(@() net.simulate([0,3], ev1, [ev2,ev2])) == "GUILDA:ODEevent:EventArray")


function id = error_id(f)
    id = "";
    try
        DebugScript.helper.quiet(f);
    catch me
        id = string(me.identifier);
    end
end
