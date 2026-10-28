% F6 時間応答シミュレーション (simulate / odeEventSet / odeSimulationResult)
%
% イベントの種類ごとに IEEE14 母線系統の応答を計算し、結果を確認する。
%   ev  = odeEventSet("名前", net, "TimeSpan", [t1,t2], <イベントの指定>);
%   sol = net.simulate([t0,tend], ev1, ev2, ...);
%   r   = sol.odeResults;     % r.t, r.Bus(i).V / I / PQ, r.Bus(i).Component(j).X / U
%
%   FaultBus   : 母線の地絡 (電圧 0)
%   TripUnit   : 機器の解列
%   OffsetState: 状態の初期値のずらし
%   InputValue : 機器入力への加算 (数値 / 関数ハンドル)
%
% 実行: runtests("DebugScript.test_F6_simulation")  または  DebugScript.run_all("Features","F6")

% 共通設定 (各テストの前に毎回実行される)
net = DebugScript.helper.build_ieee14();       % 進捗表示なし (Reporter = "none")
DebugScript.helper.quiet(@() net.initialize);
inwin = @(t, t1, t2) t > t1 + 1e-3 & t < t2 - 1e-3;   % 区間の内側 (境界の重複点を除く)


%% Simulation result structure
ev  = odeEventSet("fault", net, "TimeSpan", [1,1.05], "FaultBus", "B008");
sol = net.simulate([0,3], ev);
assert(isa(sol, "odeSimulationResult"))

r = sol.odeResults;
nt = numel(r.t);
assert(r.t(1) == 0 && r.t(end) == 3 && all(diff(r.t) >= 0))

% 母線: V (Vreal, Vimag), I (Ireal, Iimag), PQ (P, Q)
assert(numel(r.Bus) == numel(net.a_Bus))
assert(isequal(string(r.Bus(1).V.Properties.VariableNames),  ["Vreal","Vimag"]))
assert(isequal(string(r.Bus(1).I.Properties.VariableNames),  ["Ireal","Iimag"]))
assert(isequal(string(r.Bus(1).PQ.Properties.VariableNames), ["P","Q"]))
assert(height(r.Bus(1).V) == nt)

% 機器: X (状態), U (入力) の列名は sv_x, sv_u
gen = net.a_Bus{1}.a_Component{1};
assert(isequal(string(r.Bus(1).Component(1).X.Properties.VariableNames), gen.sv_x(:)'))
assert(isequal(string(r.Bus(1).Component(1).U.Properties.VariableNames), gen.sv_u(:)'))
assert(height(r.Bus(1).Component(1).X) == nt)

% 初期値は平衡点
assert(norm(r.Bus(1).Component(1).X{1,:}' - gen.rv_Xequilibrium) < 1e-8)
V1 = r.Bus(1).V{1,:} * [1;1j];
assert(abs(V1 - net.a_Bus{1}.c_Vequilibrium) < 1e-8)


%% Fault bus
% B008 で 1.00〜1.05 秒に地絡 (旧 Task7)
ev  = odeEventSet("fault", net, "TimeSpan", [1,1.05], "FaultBus", "B008");
sol = net.simulate([0,5], ev);
r   = sol.odeResults;

% 地絡中は故障母線の電圧が 0
lv = inwin(r.t, 1, 1.05);
assert(any(lv) && max(abs(r.Bus(8).V{lv,:}), [], "all") < 1e-8)

% 地絡前は平衡点、地絡で発電機の周波数が動き、除去後は電圧が戻る
assert(max(abs(r.Bus(1).Component(1).X.omega(r.t < 1))) < 1e-8)
assert(max(abs(r.Bus(1).Component(1).X.omega)) > 1e-4)
V8_end = r.Bus(8).V{end,:} * [1;1j];
assert(abs(abs(V8_end) - abs(net.a_Bus{8}.c_Vequilibrium)) < 0.05)


%% Trip generator
% 発電機 SG1B002 を 1.00〜1.05 秒に解列 (旧 Task8)
ev  = odeEventSet("trip", net, "TimeSpan", [1,1.05], "TripUnit", "SG1B002");
sol = net.simulate([0,5], ev);
r   = sol.odeResults;
X   = r.Bus(2).Component(1).X.Variables;

% 解列中の状態は NaN、再並列後は有限値
assert(all(isnan(X(inwin(r.t,1,1.05),:)), "all"))
assert(all(isfinite(X(r.t > 1.1,:)), "all"))
assert(all(isfinite(X(r.t < 1,:)), "all"))


%% Trip load
% 負荷 LPQ2B003 を 1.00〜1.05 秒に解列 → 母線 B003 の消費電力が減る
ev  = odeEventSet("trip", net, "TimeSpan", [1,1.05], "TripUnit", "LPQ2B003");
sol = net.simulate([0,5], ev);
r   = sol.odeResults;

P3 = r.Bus(3).PQ.P;
lv = inwin(r.t, 1, 1.05);
assert(any(lv))
assert(min(P3(lv)) - P3(1) > 0.3, "負荷解列中も B003 の消費電力が減っていない")


%% Offset state at time zero
% 計算開始時に SG1B001 の内部位相 delta を 0.1 rad ずらす (旧 Task16)
gen = net.a_Bus{1}.a_Component{1};
ev  = odeEventSet("offset", net, "TimeSpan", 0, "OffsetUnit", "SG1B001", "OffsetState", "delta", "OffsetValue", 0.1);
sol = net.simulate([0,5], ev);
r   = sol.odeResults;

delta = r.Bus(1).Component(1).X.delta;
assert(abs(delta(1) - (gen.rv_Xequilibrium(1) + 0.1)) < 1e-8)
assert(max(abs(r.Bus(1).Component(1).X.omega)) > 1e-5)


%% Offset state after time zero
% t = 1 秒で delta を 0.1 rad ずらす (旧 Task10 の ev1)
gen = net.a_Bus{1}.a_Component{1};
ev  = odeEventSet("offset", net, "TimeSpan", 1, "OffsetUnit", "SG1B001", "OffsetState", "delta", "OffsetValue", 0.1);
sol = net.simulate([0,5], ev);
r   = sol.odeResults;

delta = r.Bus(1).Component(1).X.delta;
assert(max(abs(delta(r.t < 1) - gen.rv_Xequilibrium(1))) < 1e-8)
i1 = find(r.t > 1, 1);                         % 1 秒の直後の点
assert(abs(delta(i1) - (gen.rv_Xequilibrium(1) + 0.1)) < 1e-2, "t = 1 のオフセットが反映されていない")


%% Offset state during a trip
% 他の機器の解列中 (区間の初期値の再計算が必要な場合) にもオフセットが残る
os = odeEventSet("offset", net, "TimeSpan", 1.5, "OffsetUnit", "SG1B001", "OffsetState", "delta", "OffsetValue", 0.1);
tr = odeEventSet("trip", net, "TimeSpan", [1,2], "TripUnit", "SG1B002");
r  = net.simulate([0,3], os, tr).odeResults;
d  = r.Bus(1).Component(1).X.delta;
k  = find(abs(r.t - 1.5) < 1e-9);              % 1.5 秒の前後の区間の境界点 (2 点)
assert(numel(k) == 2 && abs(d(k(2)) - d(k(1)) - 0.1) < 1e-8, "解列中の t = 1.5 のオフセットが反映されていない")


%% Offset state is applied only once
% オフセットの期間が他のイベントで分割されても、オフセットは開始時刻に 1 回だけ加わる
% (分割用のイベントは入力 0 で、応答には影響しない)
os  = odeEventSet("offset", net, "TimeSpan", [1,3], "OffsetUnit", "SG1B001", "OffsetState", "delta", "OffsetValue", 0.1);
cut = odeEventSet("cut", net, "TimeSpan", [2,2.5], "InputUnit", "SG1B002", "InputName", "Pmech", "InputValue", 0);
r1  = net.simulate([0,4], os).odeResults;
r2  = net.simulate([0,4], os, cut).odeResults;
d1  = r1.Bus(1).Component(1).X.delta;
d2  = r2.Bus(1).Component(1).X.delta;
assert(abs(d2(end) - d1(end)) < 1e-3, "オフセットが分割された区間ごとに重ねて加わっている")


%% Input value numeric
% SG1B002 の機械入力 Pmech に 1〜3 秒の間 0.1 を加える
gen = net.a_Bus{2}.a_Component{1};
ev  = odeEventSet("input", net, "TimeSpan", [1,3], "InputUnit", "SG1B002", "InputName", "Pmech", "InputValue", 0.1);
sol = net.simulate([0,5], ev);
r   = sol.odeResults;

Pm  = r.Bus(2).Component(1).U.Pmech;
Pm0 = gen.rv_Uequilibrium(gen.sv_u == "Pmech");
assert(max(abs(Pm(inwin(r.t,1,3)) - (Pm0 + 0.1))) < 1e-8)
assert(max(abs(Pm(r.t > 3.01) - Pm0)) < 1e-8)
assert(max(abs(r.Bus(2).Component(1).X.omega)) > 1e-5)


%% Input value function handle
% 負荷 LPQ2B002 の Pload に時間関数を加える (旧 Task10 の ev3)
% 関数の引数 t はイベント開始からの経過時間
load2 = net.a_Bus{2}.a_Component{2};
ev  = odeEventSet("input", net, "TimeSpan", [1,3], "InputUnit", "LPQ2B002", ...
                  "InputName", ["Pload";"Qload"], "InputValue", {@(t) 0.1*t; @(t) 0});
sol = net.simulate([0,5], ev);
r   = sol.odeResults;

U   = r.Bus(2).Component(2).U;
P0  = load2.rv_Uequilibrium(load2.sv_u == "Pload");
lv  = inwin(r.t, 1, 3);
assert(max(abs(U.Pload(lv) - (P0 + 0.1*(r.t(lv) - 1)))) < 1e-8)
assert(max(abs(U.Pload(r.t > 3.01) - P0)) < 1e-8)


%% Offset and input names in any order
% OffsetState / InputName は sv_x / sv_u と違う順に並べても名前で対応する
gen = net.a_Bus{1}.a_Component{1};
g2  = net.a_Bus{2}.a_Component{1};
os  = odeEventSet("offset", net, "TimeSpan", 0, "OffsetUnit", "SG1B001", "OffsetState", ["omega";"delta"], "OffsetValue", [0.01;0.1]);
in  = odeEventSet("input", net, "TimeSpan", [1,2], "InputUnit", "SG1B002", "InputName", ["Vfield";"Pmech"], "InputValue", [0.02;0.1]);
r   = net.simulate([0,2], os, in).odeResults;

X = r.Bus(1).Component(1).X;
assert(abs(X.delta(1) - (gen.rv_Xequilibrium(gen.sv_x == "delta") + 0.1)) < 1e-8)
assert(abs(X.omega(1) - (gen.rv_Xequilibrium(gen.sv_x == "omega") + 0.01)) < 1e-8)
U  = r.Bus(2).Component(1).U;
lv = inwin(r.t, 1, 2);
assert(max(abs(U.Pmech(lv)  - (g2.rv_Uequilibrium(g2.sv_u == "Pmech")  + 0.1)))  < 1e-8)
assert(max(abs(U.Vfield(lv) - (g2.rv_Uequilibrium(g2.sv_u == "Vfield") + 0.02))) < 1e-8)


%% Several events on the same unit
% 同じ機器への複数のオフセット・入力は足し合わされる
gen = net.a_Bus{1}.a_Component{1};
g2  = net.a_Bus{2}.a_Component{1};
o = cell(4,1);
o{1} = odeEventSet("os1", net, "TimeSpan", 0,     "OffsetUnit", "SG1B001", "OffsetState", "delta", "OffsetValue", 0.05);
o{2} = odeEventSet("os2", net, "TimeSpan", 0,     "OffsetUnit", "SG1B001", "OffsetState", "delta", "OffsetValue", 0.05);
o{3} = odeEventSet("in1", net, "TimeSpan", [1,3], "InputUnit", "SG1B002", "InputName", "Pmech", "InputValue", 0.1);
o{4} = odeEventSet("in2", net, "TimeSpan", [2,3], "InputUnit", "SG1B002", "InputName", "Pmech", "InputValue", @(t) 0.05);
r = net.simulate([0,4], o{:}).odeResults;

assert(abs(r.Bus(1).Component(1).X.delta(1) - (gen.rv_Xequilibrium(gen.sv_x == "delta") + 0.1)) < 1e-8)
Pm  = r.Bus(2).Component(1).U.Pmech;
Pm0 = g2.rv_Uequilibrium(g2.sv_u == "Pmech");
assert(max(abs(Pm(inwin(r.t,1,2)) - (Pm0 + 0.1)))  < 1e-8)
assert(max(abs(Pm(inwin(r.t,2,3)) - (Pm0 + 0.15))) < 1e-8)
assert(max(abs(Pm(r.t > 3.01) - Pm0)) < 1e-8)


%% Events beyond the simulation time
% 計算時間の外にはみ出すイベントで計算時間は変わらない。関数の引数はイベント開始からの経過時間のまま
g2  = net.a_Bus{2}.a_Component{1};
Pm0 = g2.rv_Uequilibrium(g2.sv_u == "Pmech");
ev  = odeEventSet("input", net, "TimeSpan", [1,5], "InputUnit", "SG1B002", "InputName", "Pmech", "InputValue", @(t) 0.1*t);

r = net.simulate([0,2], ev).odeResults;
assert(r.t(1) == 0 && r.t(end) == 2)

r = net.simulate([2,4], ev).odeResults;
assert(r.t(1) == 2 && r.t(end) == 4)
Pm = r.Bus(2).Component(1).U.Pmech;
assert(max(abs(Pm - (Pm0 + 0.1*(r.t - 1)))) < 1e-8)


%% Multiple events in one simulation
% 複数のイベントをまとめて渡す (旧 Task10 の構成を短縮)
o = cell(4,1);
o{1} = odeEventSet("ev1", net, "TimeSpan", 0,        "OffsetState", "delta", "OffsetUnit", "SG1B001", "OffsetValue", pi/36);
o{2} = odeEventSet("ev2", net, "TimeSpan", [1,1.5],  "InputUnit", "SG1B002", "InputName", ["Pmech";"Vfield"], "InputValue", {0.05; @(t) 0.01*t});
o{3} = odeEventSet("ev4", net, "TimeSpan", [2,2.02], "FaultBus", "B008");
o{4} = odeEventSet("ev5", net, "TimeSpan", [3,3.5],  "TripUnit", "LPQ2B003");
sol = net.simulate([0,5], o{:});
r   = sol.odeResults;

assert(r.t(end) == 5)
assert(max(abs(r.Bus(8).V{inwin(r.t,2,2.02),:}), [], "all") < 1e-8)
assert(all(isfinite(r.Bus(1).Component(1).X.Variables), "all"))


%% Simulate without events
% イベントを渡さなければ外乱なしの応答になるべき
sol = net.simulate([0,3]);
assert(sol.odeResults.t(end) == 3)
assert(DebugScript.helper.max_state_drift(sol) < 1e-6)


%% Repeated simulation gives the same result
% 同じ net で続けて計算しても結果は変わらない (状態が残らない)
ev = odeEventSet("fault", net, "TimeSpan", [1,1.05], "FaultBus", "B008");
s1 = net.simulate([0,3], ev);
s2 = net.simulate([0,3], ev);
o1 = s1.odeResults.Bus(1).Component(1).X.omega;
o2 = s2.odeResults.Bus(1).Component(1).X.omega;
assert(isequal(size(o1), size(o2)) && max(abs(o1 - o2)) < 1e-10)


%% Shorter simulation after a longer one
% 区間数の少ない計算を後から行っても、前の計算の区間が結果に残らない
o1 = odeEventSet("f1", net, "TimeSpan", [1,1.05], "FaultBus", "B008");
o2 = odeEventSet("f2", net, "TimeSpan", [2,2.05], "FaultBus", "B008");
net.simulate([0,3], o1, o2);
r = net.simulate([0,2], o1).odeResults;
assert(r.t(end) == 2 && all(diff(r.t) >= 0))


%% Fault with local controllers
% AVR + PSS を付けた系統での地絡応答 (旧 Task11 + Task12)
net = DebugScript.helper.build_ieee14();
net.a_Bus{1}.a_Component{1}.add_local_controller(controller.avr.AVR_ST1("avr1"), controller.pss.PSS1("pss1"));
net.a_Bus{2}.a_Component{1}.add_local_controller(controller.avr.AVR_ST1("avr2"), controller.pss.PSS1("pss2"));
DebugScript.helper.quiet(@() net.initialize);

ev  = odeEventSet("fault", net, "TimeSpan", [1,1.05], "FaultBus", "B008");
sol = net.simulate([0,5], ev);
r   = sol.odeResults;
assert(r.t(end) == 5)

% AVR が動作して界磁電圧 Vfield (発電機の入力) が変化する
Vfd = r.Bus(1).Component(1).U.Vfield;
assert(max(Vfd) - min(Vfd) > 1e-3)
assert(all(isfinite(Vfd)))


%% Load step with global controller
% AGC 付き系統で負荷を増やす (旧 Task13 + Task14)
net = DebugScript.helper.build_ieee14();
c{1} = net.a_Bus{1}.a_Component{1};
c{2} = net.a_Bus{2}.a_Component{1};
agc  = controller.agc.broadcast_PI_AGC(net, "agc", c{:}, alpha=[1;1], beta=[1;1], kP=100, kI=500);
net.add_global_controller(agc);
DebugScript.helper.quiet(@() net.initialize);

ev  = odeEventSet("step", net, "TimeSpan", [1,20], "InputUnit", "LPQ1B005", "InputName", "Pload", "InputValue", -0.1);
sol = net.simulate([0,20], ev);
r   = sol.odeResults;

% AGC が発電機の機械入力を増やし、周波数偏差を 0 に戻す
omega = r.Bus(1).Component(1).X.omega;
Pm    = r.Bus(1).Component(1).U.Pmech;
assert(max(abs(omega)) > 1e-4)
assert(abs(omega(end)) < 1e-4)
assert(Pm(end) > Pm(1))

% 比較: AGC なしでは周波数偏差が残る
net0 = DebugScript.helper.build_ieee14();
DebugScript.helper.quiet(@() net0.initialize);
ev0  = odeEventSet("step", net0, "TimeSpan", [1,20], "InputUnit", "LPQ1B005", "InputName", "Pload", "InputValue", -0.1);
r0   = net0.simulate([0,20], ev0).odeResults;
assert(abs(r0.Bus(1).Component(1).X.omega(end)) > 10*abs(omega(end)))


%% Network Hz sets the rotor angle dynamics
% 系統の周波数 (net.tab_parameter.base.Hz) が発電機の d(delta)/dt = 2*pi*Hz*omega に使われる。
% omega をずらして始めると、短時間の delta の変化は Hz に比例する (50 Hz / 60 Hz)
ddelta = zeros(1,2);
sv_Hz  = [50, 60];
for k = 1:2
    [net, gen] = DebugScript.helper.build_3bus("gen-classical");
    net.tab_parameter.base.Hz = sv_Hz(k);
    DebugScript.helper.quiet(@() net.initialize);
    i_bus = find(cellfun(@(b) b == gen.a_Bus, net.a_Bus));
    ev  = odeEventSet("offset", net, "TimeSpan", 0, "OffsetUnit", string(gen), "OffsetState", "omega", "OffsetValue", 1e-3);
    r   = net.simulate([0,0.02], ev).odeResults;
    X   = r.Bus(i_bus).Component(1).X;
    ddelta(k) = interp1(r.t, X.delta, 0.01) - X.delta(1);
end
assert(all(ddelta > 0))
assert(abs(ddelta(1)/ddelta(2) - 50/60) < 1e-2, "delta の変化の比 " + ddelta(1)/ddelta(2) + " が 50/60 にならない")
% 1e-3 の omega で 0.01 秒 → 2*pi*60*1e-3*0.01 ≈ 3.8e-3 rad
assert(abs(ddelta(2) - 2*pi*60*1e-3*0.01) < 0.1 * 2*pi*60*1e-3*0.01)
