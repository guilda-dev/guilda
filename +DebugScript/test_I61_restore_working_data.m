% I61 シミュレーション後の作業データの復元と書き込み制限
%
%   復元 : trip・地絡が終端まで続いた後、例外の後も、作業データは実行前の値に戻る
%   制限 : Component の rv_Xoffset / rv_Uoffset は解析クラスだけが書ける
%
% 実行: runtests("DebugScript.test_I61_restore_working_data")  または  DebugScript.run_all("Features","I61")

% 共通設定 (実行は 1 度だけで、net は全テストで共有される。net を変えるテストは自分の網を作る)
net = DebugScript.helper.build_ieee14();
DebugScript.helper.quiet(@() net.initialize);
gen = net.a_Bus{2}.a_Component{1};


%% Unit stays connected after a trip lasting to the end time
ev = odeEventSet("trip", net, "TimeSpan", [1,5], "TripUnit", "SG1B002");
DebugScript.helper.quiet(@() net.simulate([0,2], ev));
assert_restored(net)


%% Bus has no fault after a fault lasting to the end time
ev = odeEventSet("fault", net, "TimeSpan", [1,5], "FaultBus", "B008");
DebugScript.helper.quiet(@() net.simulate([0,2], ev));
assert_restored(net)


%% Offsets are cleared after an input and an offset
ev_os = odeEventSet("offset", net, "TimeSpan", 1, "OffsetUnit", "SG1B002", "OffsetState", "delta", "OffsetValue", 0.01);
ev_in = odeEventSet("input", net, "TimeSpan", [1,2], "InputUnit", "SG1B002", "InputName", "Pmech", "InputValue", 0.01);
DebugScript.helper.quiet(@() net.simulate([0,2], ev_os, ev_in));
assert_restored(net)


%% Working data is restored after an error during a fault and trips
net = DebugScript.helper.build_ieee14();
agc = controller.agc.broadcast_PI_AGC(net, "agc", "SG1B001", "SG1B002", kP=100, kI=500);
net.add_global_controller(agc);
DebugScript.helper.quiet(@() net.initialize);
ev_fault = odeEventSet("fault", net, "TimeSpan", [0.4,5], "FaultBus", "B008");
ev_trip  = odeEventSet("trip", net, "TimeSpan", [0.4,5], "TripUnit", ["SG1B003";"agc"]);
ev_error = odeEventSet("input", net, "TimeSpan", [0.4,5], "InputUnit", "SG1B002", "InputName", "Pmech", ...
                       "InputValue", @bad_input);
str_id = "";
try
    DebugScript.helper.quiet(@() net.simulate([0,2], ev_fault, ev_trip, ev_error));
catch me
    str_id = me.identifier;
end
assert(str_id == "GUILDA:odeSimulator:PhaseFailed", "入力関数のエラーで止まる: " + str_id)
assert_restored(net)


%% Rerun after a trip matches a run on a fresh network
ev = odeEventSet("trip", net, "TimeSpan", [1,5], "TripUnit", "SG1B002");
DebugScript.helper.quiet(@() net.simulate([0,2], ev));
sol = DebugScript.helper.quiet(@() net.simulate([0,2]));

net2 = DebugScript.helper.build_ieee14();
DebugScript.helper.quiet(@() net2.initialize);
ref = DebugScript.helper.quiet(@() net2.simulate([0,2]));
assert(isequaln(sol.rm_variable, ref.rm_variable))


%% Offsets of a component cannot be written from outside
assert(~can_write(gen, "rv_Xoffset"))
assert(~can_write(gen, "rv_Uoffset"))


%% Offsets of a component stay readable
assert(isempty(gen.rv_Xoffset) && isempty(gen.rv_Uoffset))


%% Local controller has no connection flag
mc = ?LocalController;
assert(~ismember("l_isConnect", string({mc.PropertyList.Name})))


function v = bad_input(t)
    if t > 0.01
        error("DebugScript:I61", "入力関数のエラー");
    end
    v = 0;
end

function assert_restored(net)
    a_gc = net.a_GlobalController;
    for k = 1:numel(a_gc)
        assert(a_gc{k}.l_isConnect, "大域制御器 " + a_gc{k}.str_tag)
    end
    for i = 1:numel(net.a_Bus)
        bus = net.a_Bus{i};
        assert(~get_private(bus, "l_isFault"), "母線 " + bus.str_tag)
        for j = 1:numel(bus.a_Component)
            comp = bus.a_Component{j};
            assert(get_private(comp, "l_isConnect"), "機器 " + comp.str_tag)
            assert(isempty(comp.rv_Xoffset) && isempty(comp.rv_Uoffset), "機器 " + comp.str_tag)
        end
    end
end

function v = get_private(obj, str)
    w = warning("off", "MATLAB:structOnObject");
    c = onCleanup(@() warning(w));
    s = builtin("struct", obj);      % struct はオーバーロードされている
    v = s.(str);
end

function l = can_write(obj, str)
    try
        obj.(str) = [];
        l = true;
    catch
        l = false;
    end
end
