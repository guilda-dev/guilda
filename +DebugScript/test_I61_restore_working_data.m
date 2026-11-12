% I61 シミュレーションはモデルに何も書かない
%
%   trip・地絡・入力・オフセットの状態と変数の位置は SolverODE の実行コンテキスト (ctx) にだけあり、
%   終端まで続く外乱の後も、例外の後も、モデルのオブジェクトは実行前と同じ。
%   モデルには作業用のプロパティ (iv_ode*, l_isConnect, l_isFault, rv_Xoffset, rv_Uoffset) が無い
%
% 実行: runtests("DebugScript.test_I61_restore_working_data")  または  DebugScript.run_all("Features","I61")

% 共通設定 (実行は 1 度だけで、net は全テストで共有される。net を変えるテストは自分の網を作る)
net = DebugScript.helper.build_ieee14();
DebugScript.helper.quiet(@() net.initialize);
gen = net.a_Bus{2}.a_Component{1};


c_quiet = DebugScript.helper.user_config("TimeSimulation", struct("Progress", "none"));   % 進捗表示なし (各テストの終わりに元へ戻す)

%% Unit stays connected after a trip lasting to the end time
c_before = snapshot(net);
ev = DebugScript.helper.scenario("trip", net, "TimeSpan", [1,5], "TripUnit", "B002SG1");
DebugScript.helper.quiet(@() net.simulate([0,2], ev));
assert_untouched(net, c_before)


%% Bus has no fault after a fault lasting to the end time
c_before = snapshot(net);
ev = DebugScript.helper.scenario("fault", net, "TimeSpan", [1,5], "FaultBus", "B008");
DebugScript.helper.quiet(@() net.simulate([0,2], ev));
assert_untouched(net, c_before)


%% Offsets are cleared after an input and an offset
c_before = snapshot(net);
ev_os = DebugScript.helper.scenario("offset", net, "TimeSpan", 1, "OffsetUnit", "B002SG1", "OffsetState", "delta", "OffsetValue", 0.01);
ev_in = DebugScript.helper.scenario("input", net, "TimeSpan", [1,2], "InputUnit", "B002SG1", "InputName", "Pmech", "InputValue", 0.01);
DebugScript.helper.quiet(@() net.simulate([0,2], ev_os, ev_in));
assert_untouched(net, c_before)


%% Working data is restored after an error during a fault and trips
net = DebugScript.helper.build_ieee14();
agc = net.add_global_controller("agc-PI", ["B001SG1","B002SG1"], parameter=struct(kP=100, kI=500));
DebugScript.helper.quiet(@() net.initialize);
c_before = snapshot(net);
ev_fault = DebugScript.helper.scenario("fault", net, "TimeSpan", [0.4,5], "FaultBus", "B008");
ev_trip  = DebugScript.helper.scenario("trip", net, "TimeSpan", [0.4,5], "TripUnit", ["B003SG1";agc.s_tag]);
ev_error = DebugScript.helper.scenario("input", net, "TimeSpan", [0.4,5], "InputUnit", "B002SG1", "InputName", "Pmech", ...
                       "InputValue", @bad_input);
s_id = "";
try
    DebugScript.helper.quiet(@() net.simulate([0,2], ev_fault, ev_trip, ev_error));
catch me
    s_id = DebugScript.helper.msg_id(me);
end
assert(s_id == "GUILDA:SolverODE:PhaseFailed", "入力関数のエラーで止まる: " + s_id)
assert_untouched(net, c_before)


%% Rerun after a trip matches a run on a fresh network
ev = DebugScript.helper.scenario("trip", net, "TimeSpan", [1,5], "TripUnit", "B002SG1");
DebugScript.helper.quiet(@() net.simulate([0,2], ev));
sol = DebugScript.helper.quiet(@() net.simulate([0,2]));

net2 = DebugScript.helper.build_ieee14();
DebugScript.helper.quiet(@() net2.initialize);
ref = DebugScript.helper.quiet(@() net2.simulate([0,2]));
assert(isequaln(sol.rm_variable, ref.rm_variable))


%% Models have no simulation working data
sv_work = ["iv_odeX","iv_odeU","iv_odeY","iv_odeI","lv_odeUfromLC","iv_odeYtoU","l_isConnect","l_isFault","rv_Xoffset","rv_Uoffset","sv_route"];
for mc = [?Component, ?LocalController, ?GlobalController, ?Bus]
    sv_prop = string({mc.PropertyList.Name});
    assert(~any(ismember(sv_work, sv_prop)), mc.Name + ": " + join(intersect(sv_work, sv_prop), ", "))
end


function v = bad_input(t)
    if t > 0.01
        error("DebugScript:I61", "入力関数のエラー");
    end
    v = 0;
end

function c = snapshot(net)
% すべての母線・機器・局所制御器・大域制御器のプロパティの値
    a_obj = [net.a_Bus; net.a_GlobalController];
    for i = 1:numel(net.a_Bus)
        for j = 1:numel(net.a_Bus{i}.a_Component)
            comp = net.a_Bus{i}.a_Component{j};
            a_obj = [a_obj; {comp}; controllers(comp)]; %#ok<AGROW>
        end
    end
    w = warning("off", "MATLAB:structOnObject");
    c_w = onCleanup(@() warning(w));
    c = cellfun(@(o) builtin("struct", o), a_obj, 'UniformOutput', false);   % struct はオーバーロードされている
end

function assert_untouched(net, c_before)
    c_after = snapshot(net);
    assert(numel(c_after) == numel(c_before))
    for k = 1:numel(c_before)
        sv = string(fieldnames(c_before{k}))';
        for s = sv
            assert(isequaln(c_before{k}.(s), c_after{k}.(s)), "simulate が " + s + " を書き換えた")
        end
    end
end

function list = controllers(parent)
    list = cell(0,1);
    for k = 1:numel(parent.a_LocalController)
        list = [list; parent.a_LocalController(k); controllers(parent.a_LocalController{k})]; %#ok<AGROW>
    end
end
