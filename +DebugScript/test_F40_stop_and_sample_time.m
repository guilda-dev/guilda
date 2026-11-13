% F40 回転子角による停止 (StopOnOutOfStep, StopAngle) と出力の時刻 (SampleTime)
%
%   [res, flag, output] = net.simulate(tag, StopOnOutOfStep=true, StopAngle=180);   % flag = 2
%   output.outOfStep                                  % Time, Unit, Reference, Angle [deg]
%   res = net.simulate(tag, SampleTime=0.01);         % t0 + k*0.01 と区間の開始・終わり
%
% 基準はスラック母線の発電機。基準の解列中は止まらない。flag = 2 は SimulationIncomplete の
% 警告を出さない。SampleTime はソルバーの刻みを変えず、記録する時刻だけを決める。
%
% 実行: runtests("DebugScript.test_F40_stop_and_sample_time")  または  DebugScript.run_all("Features","F40")


c_quiet = DebugScript.helper.user_config("TimeSimulation", struct("Progress", "none"));   % 進捗表示なし (各テストの終わりに元へ戻す)

%% Stop on out of step
% IEEE9 の長い地絡 (B007, [1, 1.5]) は脱調する。StopAngle=180 で止まり、止まるまでの軌道は停止なしと同じ
n9 = ieee9();
sc = n9.add_scenario("long", Time=[0,5]);
sc.add_fault("B007", [1,1.5]);
lastwarn("");
[r2, f2, o2] = n9.simulate(sc.s_tag, StopOnOutOfStep=true, StopAngle=180);
assert(f2 == 2 && r2.flag == 2, "flag = %d", f2)
assert(isempty(lastwarn()), "flag = 2 で警告が出た: %s", lastwarn())
st = o2.outOfStep;
assert(st.Reference == "B001SG1" && st.Angle == 180 && st.Time == o2.tEnd && o2.tEnd == r2.rv_t(end) && o2.tEnd < 5)
assert(contains(o2.message, "StopOnOutOfStep") && contains(o2.message, st.Unit))
rv_rel = rel_angle(r2, st.Unit, "B001SG1");
assert(abs(abs(rv_rel(end)) - 180) < 1e-6, "止まった時刻の角の差 %.9g deg", rv_rel(end))
assert(all(abs(rv_rel(1:end-1)) < 180 + 1e-6))
[~, k_max] = max(abs(rel_angle_all(r2, "B001SG1", numel(r2.rv_t))));
assert(r2.tab_variable.Owner(k_max) == st.Unit, "脱調した発電機でない")
% 停止なしの同じ計算と、止まる前の時刻まで一致する
ws = warning("off", "GUILDA:PowerNetwork:SimulationIncomplete");  c_ws = onCleanup(@() warning(ws));
r1 = n9.simulate(sc.s_tag);
clear c_ws
n = numel(r2.rv_t) - 1;
assert(isequaln(r1.rv_t(1:n), r2.rv_t(1:n)) && isequaln(r1.rm_variable(1:n,:), r2.rm_variable(1:n,:)))
% 判定: StopAngle < Threshold は "incomplete"、StopAngle >= Threshold は "out-of-step"
v = r2.judge_out_of_step();
assert(v.Verdict == "incomplete" && isnan(v.Time), v.Verdict)
v = r2.judge_out_of_step(Threshold=180);
assert(v.Verdict == "out-of-step" && v.Time == o2.tEnd && ismember(st.Unit, v.Units), v.Verdict)
v = r2.judge_out_of_step(Threshold=120);
assert(v.Verdict == "out-of-step" && v.Time < o2.tEnd, v.Verdict)


%% Default StopAngle and a run that does not stop
% 既定の StopAngle (360) と判定の既定 Threshold (360)
n9 = ieee9();
sc = n9.add_scenario("long", Time=[0,5]);
sc.add_fault("B007", [1,1.5]);
[r3, f3, o3] = n9.simulate(sc.s_tag, StopOnOutOfStep=true);
assert(f3 == 2 && o3.outOfStep.Angle == 360)
v = r3.judge_out_of_step();
assert(v.Verdict == "out-of-step" && v.Time <= o3.tEnd, v.Verdict)
% 止まらない計算の outOfStep は空
[~, f4, o4] = n9.simulate(sc.s_tag, Time=[0, 1.2], StopOnOutOfStep=true, StopAngle=180);
assert(f4 == 1 && isempty(o4.outOfStep) && isstruct(o4.outOfStep))


%% StopOnOutOfStep from GUILDA.setting
n9 = ieee9();
sc = n9.add_scenario("long", Time=[0,5]);
sc.add_fault("B007", [1,1.5]);
c_cfg = DebugScript.helper.user_config("TimeSimulation", struct("Progress", "none", "StopOnOutOfStep", true, "StopAngle", 180));
[r, f] = n9.simulate(sc.s_tag);
assert(f == 2 && r.options.StopOnOutOfStep && r.options.StopAngle == 180)
[~, f] = n9.simulate(sc.s_tag, StopOnOutOfStep=false);     % 呼び出しの値が設定に勝つ
assert(f ~= 2)
clear c_cfg


%% The reference tripped does not stop
% 基準 (B001SG1) の解列中は、ほかの発電機の角が解列の時の基準の角から離れても止まらない
n9 = ieee9();
sc = n9.add_scenario("ref", Time=[0,3]);
sc.add_trip("B001SG1", [1,3]);
[r, f] = n9.simulate(sc.s_tag, StopOnOutOfStep=true, StopAngle=30);
assert(f == 1, "flag = %d", f)
i_ref = find(r.tab_variable.Owner == "B001SG1" & r.tab_variable.Name == "delta");
i_2   = find(r.tab_variable.Owner == "B002SG1" & r.tab_variable.Name == "delta");
k1 = find(r.rv_t == 1, 1, "first");          % 解列の直前 (第 1 区間の終わり)
assert(max(abs(r.rm_variable(k1:end, i_2) - r.rm_variable(k1, i_ref)))*180/pi > 30, ...
       "解列中にほかの発電機の角が動かず、この節の確認にならない")
assert(all(isnan(r.rm_variable(k1+1:end, i_ref))))


%% StopNoRotorAngle
% 回転子角を比べる発電機がない系統
net = PowerNetwork("OneGen");
net.add_bus("V", 1.0);
net.add_bus();
net.add_branch("pi", [1,2], "R", 0.01, "X", 0.1);
net.a_Bus{1}.add_component("gen-1axis", "P", 0.5, "Q", nan);
net.a_Bus{2}.add_component("load-power", "P", -0.5, "Q", -0.1);
evalc("net.a_Bus{1}.l_isSlack = true;");
DebugScript.helper.quiet(@() net.initialize);
s_tag = DebugScript.helper.no_disturbance(net);
ME = caught(@() net.simulate(s_tag, Time=[0, 0.1], StopOnOutOfStep=true));
assert(DebugScript.helper.msg_id(ME) == "GUILDA:PowerNetwork:StopNoRotorAngle", ME.message)
assert(contains(ME.message, "B001SG1"))
[~, f] = net.simulate(s_tag, Time=[0, 0.1]);            % 停止なしは動く
assert(f == 1)


%% SampleTime records a uniform grid and the phase boundaries
n9 = ieee9();
sc = n9.add_scenario("ok", Time=[0,3]);
sc.add_fault("B007", [1,1.05]);
r0 = n9.simulate(sc.s_tag);
r  = n9.simulate(sc.s_tag, SampleTime=0.01);
t  = r.rv_t;
assert(t(1) == 0 && t(end) == 3)
assert(nnz(t == 1) == 2 && nnz(abs(t - 1.05) < 1e-12) == 2, "区間の境界が 2 回でない")
d = diff(t);
assert(all(abs(d(d > 0) - 0.01) < 1e-9 | ismember(find(d > 0), find(abs(t - 1.05) < 1e-12) + [-1, 0])), "間隔が 0.01 でない")
rv_grid = round(t(abs(t/0.01 - round(t/0.01)) < 1e-9)/0.01);
assert(isequal(unique(rv_grid).', 0:300), "格子の時刻が欠けている")
% 値はソルバーの刻みの計算と許容誤差の範囲で一致 (第 3 区間 [1.05, 3] の内部)
iv_d = find(r.tab_variable.Kind == "x");
lv0 = r0.rv_t > 1.05 + 1e-9;   lv = t > 1.06 & t < 2.99;
m0  = interp1(r0.rv_t(lv0), r0.rm_variable(lv0, iv_d), t(lv), "pchip");
assert(max(abs(m0 - r.rm_variable(lv, iv_d)), [], "all") < 1e-2, "SampleTime の値がずれる")
% Format="struct" の sol.t も同じ
sol = n9.simulate(sc.s_tag, SampleTime=0.01, Format="struct");
assert(isequal(sol.t, t) && height(sol.a_Bus{1}.V) == numel(t))
% NaN と 0 は SampleTime なしと同じ
r_nan = n9.simulate(sc.s_tag, SampleTime=NaN);
r_0   = n9.simulate(sc.s_tag, SampleTime=0);
assert(isequaln(r_nan.rv_t, r0.rv_t) && isequaln(r_nan.rm_variable, r0.rm_variable))
assert(isequaln(r_0.rv_t, r0.rv_t) && isequaln(r_0.rm_variable, r0.rm_variable))
% 停止と一緒に: 最後の時刻は止まった時刻
sc2 = n9.add_scenario("long", Time=[0,5]);
sc2.add_fault("B007", [1,1.5]);
[rs, fs, os] = n9.simulate(sc2.s_tag, SampleTime=0.01, StopOnOutOfStep=true, StopAngle=180);
assert(fs == 2 && rs.rv_t(end) == os.tEnd && all(diff(rs.rv_t) >= 0))
rv_rel = rel_angle(rs, os.outOfStep.Unit, "B001SG1");
assert(abs(abs(rv_rel(end)) - 180) < 1e-6)
assert(~isempty(caught(@() n9.simulate(sc.s_tag, SampleTime=-1, Time=[0 0.1]))), "SampleTime < 0 が通った")


function net = ieee9()
% 初期化した IEEE9bus
    net = network.IEEE9bus;
    DebugScript.helper.quiet(@() net.initialize);
end

function rv = rel_angle(r, s_unit, s_ref)
% [deg] s_unit の回転子角の s_ref からの差
    tab = r.tab_variable;
    i_u = find(tab.Owner == s_unit & tab.Name == "delta");
    i_r = find(tab.Owner == s_ref & tab.Name == "delta");
    rv  = (r.rm_variable(:, i_u) - r.rm_variable(:, i_r))*180/pi;
end

function rv = rel_angle_all(r, s_ref, k)
% [deg] 時刻 k の各列の s_ref の回転子角からの差 (delta 以外は 0)
    tab = r.tab_variable;
    i_r = find(tab.Owner == s_ref & tab.Name == "delta");
    lv  = tab.Name(1:size(r.rm_variable,2)) == "delta" & tab.Kind(1:size(r.rm_variable,2)) == "x";
    rv  = zeros(1, size(r.rm_variable, 2));
    rv(lv) = (r.rm_variable(k, lv) - r.rm_variable(k, i_r))*180/pi;
end

function ME = caught(f)
% f のエラー (なければ空)
    ME = [];
    try
        f();
    catch ME
    end
end
