% F30 調速機 (key "governor") と IEEJ 標準モデルの調速機系 (付図1.2: LPT=1, 3, 4)
%
%   機器は AVR ("avr" / "local") の枠とは別に調速機の枠を1つ持つ。変数の順序は接続の順に
%   よらず「機器、AVR (と配下の PSS)、調速機」。2つの最上位制御器の出力は重ならない。
%   IEEJ_LPT1/3/4 は omega を観測し Pmech を駆動する。Pref (65M) と Plimit (77M) は
%   PLM [%] から平衡点で決まり、定常状態では垂下率どおり ΔPmech/Δomega = -Prate*100/droop
%   になる。サーボの速度制限と位置制限 (non-windup)、LVG の 77M で出力が止まる。
%
% 実行: runtests("DebugScript.test_F30_governor")  または  DebugScript.run_all("Features","F30")

% 共通設定 (各テストの前に毎回実行される)
c_cls = ["controller.governor.IEEJ_LPT1"; "controller.governor.IEEJ_LPT3"; "controller.governor.IEEJ_LPT4"];
c_key = ["gov-LPT1"; "gov-LPT3"; "gov-LPT4"];    % c_cls のモデルキー
r_step = -0.05;    % B001SG1 の Pmech のステップ (負荷の増加と同じ向き)


c_quiet = DebugScript.helper.user_config("TimeSimulation", struct("Progress", "none"));   % 進捗表示なし (各テストの終わりに元へ戻す)

%% Governors have the key, ports, tag and figure defaults of the report
[~, comp, gov] = build_gov("gov-LPT1");
assert(gov.s_role == "governor" && gov.key == "gov-LPT1" && gov.s_tag == comp.s_tag + "CG1")
assert(isequal(gov.sv_u, ["omega";"Pref";"Plimit"]) && gov.sv_y == "Pmech")
assert(isequal(gov.sv_x, ["Pgov";"Psv";"Pch";"Prh"]))
tab = gov.tab_parameter.dynamics;
assert(tab.droop == 4 && tab.Tg == 0.2 && tab.Ks == 5 && tab.rate_max == 0.2 && tab.rate_min == -1000)
assert(tab.pos_max == 1.05 && tab.pos_min == 0 && tab.Tch == 0.25 && tab.Trh == 9 && tab.Fhp == 0.3 && tab.Frh == 0.7)
[~, ~, gov] = build_gov("gov-LPT3");
tab = gov.tab_parameter.dynamics;
assert(tab.droop == 5 && tab.Tg == 10 && tab.Ts == 0.3 && tab.rate_max == 0.1 && tab.pos_max == 1.05)
[~, ~, gov] = build_gov("gov-LPT4");
assert(isequal(gov.sv_x, ["Pgov";"Pdr";"Psv";"Pw"]))
tab = gov.tab_parameter.dynamics;
assert(tab.droop == 4 && tab.Tg == 4 && tab.Kt == 0.6 && tab.Tt == 12 && tab.Ts == 7 && tab.rate_max == 0.1)
assert(tab.pos_max == 1.02 && tab.Tw == 1.5 && tab.Kw == 3 && tab.Kv == -2)


%% The slots keep a fixed order whatever the order of attachment
[net1, comp1, avr1, pss1, gov1] = build_full("before");
[net2, comp2, avr2, pss2, gov2] = build_full("after");
assert(same_list(comp1.a_LocalController, {avr1; gov1}) && avr1.a_LocalController{1} == pss1)
assert(same_list(comp2.a_LocalController, {avr2; gov2}) && avr2.a_LocalController{1} == pss2)
tab1 = net1.get_variable_map();  tab2 = net2.get_variable_map();
% 制御器のタグの番号は接続の順で変わるので、net1 の所有者を net2 のタグへ読み替えて比べる
sv_own  = string(tab1.Owner);
sv_tag2 = [avr2.s_tag; pss2.s_tag; gov2.s_tag];
[lv, iv] = ismember(sv_own, [avr1.s_tag; pss1.s_tag; gov1.s_tag]);
sv_own(lv) = sv_tag2(iv(lv));
assert(isequal(sv_own, string(tab2.Owner)) && isequal(tab1.Name, tab2.Name) && isequal(tab1.Kind, tab2.Kind))
tab = comp1.get_variable_map();
sv_owner = unique(tab.Owner(tab.Kind == "x"), "stable");
assert(isequal(sv_owner, [comp1.s_tag; avr1.s_tag; pss1.s_tag; gov1.s_tag]))
assert(isequal(comp1.rv_Xequilibrium_all, [comp1.rv_Xequilibrium; avr1.rv_Xequilibrium; pss1.rv_Xequilibrium; gov1.rv_Xequilibrium]))
sys = comp1.get_sys();
assert(isequal(string(sys.StateName), tab.Label(tab.Kind == "x")))
% 調速機だけのときは {1} が調速機
[~, comp] = build_gov("gov-LPT3");
assert(numel(comp.a_LocalController) == 1 && comp.a_LocalController{1}.s_role == "governor")


%% Without events the network with AVR, PSS and governors stays at the equilibrium
[net, comp, ~, ~, gov] = build_full("after");
net.a_Bus{1}.a_Component{1}.add_local_controller("gov-LPT4", parameter=struct(Prate=2, PLM=10));
DebugScript.helper.quiet(@() net.initialize);
sol = DebugScript.helper.quiet(@() net.simulate(DebugScript.helper.no_disturbance(net), Time=[0,10]));
assert(sol.flag == 1)
assert(DebugScript.helper.max_state_drift(sol) < 1e-9, "drift %g", DebugScript.helper.max_state_drift(sol))
rv_pm = trajectory(sol, comp.s_tag, "Pmech");
assert(max(abs(rv_pm - comp.rv_Uequilibrium(1))) < 1e-9)
assert(all(abs(trajectory(sol, gov.s_tag, "Psv") - gov.rv_Xequilibrium(2)) < 1e-9))


%% Each LPT settles with its droop after a load step
c_case = {c_key(1), struct(Prate=1, PLM=10), 25;
          c_key(2), struct(Prate=0.8, PLM=10), 0.8*20;
          c_key(3), struct(Prate=1, PLM=10), 25};
for k = 1:height(c_case)
    [sol, comp] = simulate_step(c_case{k,1}, c_case{k,2}, r_step, [1,400], 400);
    rv_pm = trajectory(sol, comp.s_tag, "Pmech");
    rv_w  = trajectory(sol, comp.s_tag, "omega");
    r_dP = rv_pm(end) - rv_pm(1);
    r_dw = rv_w(end) - rv_w(1);
    assert(sol.flag == 1)
    assert(r_dw < -1e-4, "%s: the frequency does not drop (%g)", c_case{k,1}, r_dw)
    r_ratio = -r_dP/r_dw;
    assert(abs(r_ratio/c_case{k,3} - 1) < 5e-3, "%s: dPmech/domega = %g (expected %g)", c_case{k,1}, -r_ratio, -c_case{k,3})
end


%% The load limiter 77M caps the output
for k = 1:numel(c_cls)
    [sol, comp, gov] = simulate_step(c_key(k), struct(PLM=1), r_step, [1,100], 100);
    rv_pm = trajectory(sol, comp.s_tag, "Pmech");
    r_P0 = comp.rv_Uequilibrium(1);
    assert(gov.rv_Uequilibrium(3) - gov.rv_Uequilibrium(2) - 0.01 < 1e-12)
    assert(max(rv_pm) <= r_P0 + 0.01 + 1e-6, "%s: Pmech %g above 77M", c_cls(k), max(rv_pm) - r_P0)
    assert(abs(rv_pm(end) - (r_P0 + 0.01)) < 1e-4, "%s: Pmech %g does not reach 77M", c_cls(k), rv_pm(end) - r_P0)
end


%% Load-limit operation (PLM < 0) keeps Pmech for a frequency drop
for k = 1:numel(c_cls)
    [sol, comp, gov] = simulate_step(c_key(k), struct(PLM=-5), r_step, [1,60], 60);
    r_P0 = comp.rv_Uequilibrium(1);
    assert(abs(gov.rv_Uequilibrium(2) - (r_P0 + 0.05)) < 1e-12 && abs(gov.rv_Uequilibrium(3) - r_P0) < 1e-12)
    rv_pm = trajectory(sol, comp.s_tag, "Pmech");
    rv_w  = trajectory(sol, comp.s_tag, "omega");
    assert(min(rv_w) < -1e-3)
    assert(max(abs(rv_pm - r_P0)) < 1e-9, "%s: Pmech moved by %g", c_cls(k), max(abs(rv_pm - r_P0)))
end


%% PLM = 0 sets 77M to the upper limit of the servo position
[~, ~, gov] = build_gov("gov-LPT3", struct(PLM=0));
assert(gov.rv_Uequilibrium(3) == 1.05 && gov.rv_Uequilibrium(2) == gov.rv_Xequilibrium(2))


%% The servo position stops at its limit without windup
% 位置の上限 0.51 で止まり、ステップが終わるとすぐに戻り始める (積分器が溜め込まない)
% 制限への到達は事象検出をしないので、AVR_DC1 の界磁電圧制限と同じく積分の1ステップ分だけ越えうる
[sol, comp, gov] = simulate_step("gov-LPT1", struct(PLM=10, pos_max=0.51), r_step, [1,40], 80);
rv_t   = sol.rv_t;
rv_pos = trajectory(sol, gov.s_tag, "Psv");
assert(max(rv_pos) <= 0.51 + 1e-3, "Psv %g above the limit", max(rv_pos))
assert(max(rv_pos) >= 0.51, "the limit is not reached: %g", max(rv_pos))
lv_hold = rv_t > 20 & rv_t < 40;    % 制限で止まっている間は動かない
assert(max(rv_pos(lv_hold)) - min(rv_pos(lv_hold)) < 1e-9, "Psv moves at the limit")
% LVG の出力 g = Pref - Pgov が上限を下回れば、すぐに戻り始める
rv_g = gov.rv_Uequilibrium(2) - trajectory(sol, gov.s_tag, "Pgov");
t_g = rv_t(find(rv_t > 40 & rv_g < 0.51 - 1e-3, 1));
assert(~isempty(t_g), "the gate does not fall below the limit")
r_after = interp1(unique_time(rv_t), rv_pos(unique_index(rv_t)), t_g + 1);
assert(r_after < max(rv_pos) - 1e-4, "Psv %g stays at the limit after the gate falls (windup)", r_after)
assert(rv_pos(end) < 0.505, "Psv %g does not return", rv_pos(end))
rv_pm = trajectory(sol, comp.s_tag, "Pmech");
assert(max(rv_pm) <= 0.51 + 1e-3)


%% The rate limit bounds the servo speed
r_rate = 0.002;
[sol, ~, gov] = simulate_step("gov-LPT1", struct(PLM=10, rate_max=r_rate), r_step, [1,60], 60);
rv_t   = sol.rv_t;
rv_pos = trajectory(sol, gov.s_tag, "Psv");
rv_rise = rv_pos - rv_pos(1);
assert(all(rv_rise <= r_rate*max(rv_t - 1, 0) + 1e-7), "the servo is faster than rate_max")
% 要求 25*Δomega (約 0.02) に届くまでの間は rate_max で動く
rv_at = interp1(unique_time(rv_t), rv_rise(unique_index(rv_t)), [4, 8]);
r_speed = diff(rv_at)/4;
assert(abs(r_speed/r_rate - 1) < 1e-3, "servo speed %g (rate_max %g)", r_speed, r_rate)


%% An equilibrium outside the servo position limits is an error
for k = 1:numel(c_cls)
    [net, comp] = DebugScript.helper.build_3bus("gen-park");
    gov = comp.add_local_controller(c_key(k), parameter=struct(Prate=0.2));    % 0.5/0.2 = 2.5 pu: 上限より大きい
    ME = [];
    try
        DebugScript.helper.quiet(@() net.initialize);
    catch ME
    end
    s_cls = extractAfter(c_cls(k), "controller.governor.");
    assert(~isempty(ME), "%s: no error", s_cls)
    assert(DebugScript.helper.msg_id(ME) == "GUILDA:" + s_cls + ":OutputOutOfRange", "ID " + DebugScript.helper.msg_id(ME))
    assert(contains(ME.message, gov.s_tag) && contains(ME.message, "Prate"), ME.message)
end


%% validate passes and the analytic Jacobians agree at the equilibrium
for k = 1:numel(c_cls)
    [~, ~, gov] = build_gov(c_key(k), struct(PLM=5));
    flag = gov.validate(false);
    lv = flag.contract.status == "FAIL";
    assert(~any(lv), "%s: %s", c_cls(k), join(flag.contract.Properties.RowNames(lv), ", "))
    for fn = ["Axx","Bxv","Bxu","Cyx","Dyv","Dyu"]
        if isfield(flag, fn) && ~isempty(flag.(fn)) && width(flag.(fn)) > 0
            r = max(flag.(fn){:,:}, [], "all");
            assert(r < 1e-5, "%s %s %g", c_cls(k), fn, r);
        end
    end
    assert(all(flag.inputs{"omega","source"} ~= "equilibrium (not connected)"))
end


%% The analytic Jacobians agree with finite differences on every branch
% (Pgov, Psv, Pref, Plimit): LVG を通る / 77M で止まる / 速度制限 / 位置上限で外へ / 上限から内へ
rm_point = [0.01, 0.50, 0.52, 0.60;
            0.00, 0.50, 0.70, 0.52;
            0.00, 0.50, 0.90, 1.00;
            0.00, 1.06, 1.20, 1.30;
            0.00, 1.06, 0.90, 1.30];
for k = 1:numel(c_cls)
    [~, ~, gov] = build_gov(c_key(k), struct(pos_max=1.05));
    param = gov.tab_parameter.dynamics{:, cellstr(gov.sv_para)}';
    for m = 1:height(rm_point)
        [x, u] = branch_point(gov, rm_point(m,:));
        [r_dx, r_y] = jacobian_error(c_cls(k), x, u, param);
        assert(r_dx < 1e-6 && r_y < 1e-6, "%s point %d: %g %g", c_cls(k), m, r_dx, r_y)
    end
end


%% get_sys includes the governor states, and the model stays finite
[net0, comp0] = build_full("none");
[net,  comp ] = build_full("after");
e0 = DebugScript.helper.finite_eigs(net0.get_sys());
e  = DebugScript.helper.finite_eigs(net.get_sys());
assert(numel(e) == numel(e0) + 4)
assert(all(isfinite(e)) && max(real(e)) < 1e-6, "max real %g", max(real(e)))
sys = comp.get_sys();
gov = comp.a_LocalController{2};
assert(all(ismember(string(gov.attach_tag(gov.sv_x)), string(sys.StateName))))
assert(numel(sys.StateName) == numel(comp0.get_sys().StateName) + 4)


%% A small step matches the linear model with the governor
[net, comp] = build_full("after");
[r_err, r_max] = error_to_linear(net, "B001SG1", comp, 1e-3);
assert(r_max > 1e-6, "the step has no effect: %g", r_max)
assert(r_err < 0.01, "relative error %g", r_err)


%% remove_local_controller removes one slot and leaves the other
[net, comp, avr, pss, gov] = build_full("after");
comp.remove_local_controller(gov.s_tag);
assert(same_list(comp.a_LocalController, {avr}) && avr.a_LocalController{1} == pss && ~isvalid(gov))
assert(DebugScript.helper.is_stale(net))
gov = comp.add_local_controller("gov-LPT1", parameter=struct(PLM=5));
ME = caught(@() comp.remove_local_controller(avr.s_tag));
assert(ME.identifier == "GUILDA:Component:ControllerHasNested")
assert(same_list(comp.a_LocalController, {avr; gov}))
comp.remove_local_controller(pss.s_tag);
assert(same_list(comp.a_LocalController, {avr; gov}) && isempty(avr.a_LocalController))
pss = comp.add_local_controller("pss-PSS1");
comp.remove_local_controller(avr.s_tag, RemoveNested=true);
assert(same_list(comp.a_LocalController, {gov}) && gov.a_Component == comp)
assert(~isvalid(avr) && ~isvalid(pss))
DebugScript.helper.quiet(@() net.initialize);
sol = DebugScript.helper.quiet(@() net.simulate(DebugScript.helper.no_disturbance(net), Time=[0,2]));
assert(sol.flag == 1 && DebugScript.helper.max_state_drift(sol) < 1e-9)
% PSS は調速機の下には付かない
ME = caught(@() comp.add_local_controller("pss-PSS1"));
assert(ME.identifier == "GUILDA:Component:NotExtAvr")
assert(same_list(comp.a_LocalController, {gov}))


%% A new governor replaces the attached one with a warning
[net, comp, avr, ~, gov] = build_full("after");
s_gov = gov.s_tag;
lastwarn("", "");
gov2 = comp.add_local_controller("gov-LPT3");
[str, id] = lastwarn();
assert(string(DebugScript.helper.msg_id(str, id)) == "GUILDA:Component:ReplaceController")
assert(contains(str, gov2.s_tag) && contains(str, s_gov) && contains(str, "Governor"))
assert(same_list(comp.a_LocalController, {avr; gov2}) && ~isvalid(gov))
% AVR を置き換えても調速機は残る
lastwarn("", "");
comp.add_local_controller("avr-ST1");
assert(numel(comp.a_LocalController) == 2 && comp.a_LocalController{2} == gov2)


%% A governor and a local controller cannot drive the same input
s_id = "GUILDA:Component:ControllerOutputOverlap";
[net, comp] = DebugScript.helper.build_3bus("gen-park");
gov = comp.add_local_controller("gov-LPT1");
sv_log = DebugScript.helper.stale(net);
ME = caught(@() comp.add_local_controller("local-LQR"));    % 既定ではすべての入力 (Pmech を含む) を駆動する
assert(ME.identifier == s_id)
assert(contains(ME.message, "Pmech") && contains(ME.message, gov.s_tag) && contains(ME.message, comp.s_tag + "CL2"))
assert(same_list(comp.a_LocalController, {gov}) && isequal(DebugScript.helper.stale(net), sv_log))
% 逆の順でも
[~, comp] = DebugScript.helper.build_3bus("gen-park");
evalc("comp.add_local_controller(""local-LQR"", parameter=struct(Input=""Pmech""))");
ME = caught(@() comp.add_local_controller("gov-LPT3"));
assert(ME.identifier == s_id && numel(comp.a_LocalController) == 1)
% 入力を分ければ両方付き、平衡点に留まる
[net, comp] = DebugScript.helper.build_3bus("gen-park");
comp.add_local_controller("gov-LPT1");
lqr = comp.add_local_controller("local-LQR", parameter=struct(Input="Vfield"));
assert(numel(comp.a_LocalController) == 2 && comp.a_LocalController{1} == lqr && comp.a_LocalController{2}.s_role == "governor")
DebugScript.helper.quiet(@() net.initialize);
sol = DebugScript.helper.quiet(@() net.simulate(DebugScript.helper.no_disturbance(net), Time=[0,2]));
assert(sol.flag == 1 && DebugScript.helper.max_state_drift(sol) < 1e-9)


%% A governor on a component without Pmech is rejected
[~, comp] = DebugScript.helper.build_3bus("load-power");
ME = caught(@() comp.add_local_controller("gov-LPT1"));
assert(ME.identifier == "GUILDA:Component:ControllerOutput" && isempty(comp.a_LocalController))


%% replace_component with Controllers="keep" moves both slots
[net, comp, avr, pss, gov] = build_full("after");
bus = comp.a_Bus;
new = bus.replace_component(comp.s_tag, "gen-1axis", Controllers="keep");
assert(same_list(new.a_LocalController, {avr; gov}) && avr.a_LocalController{1} == pss)
assert(avr.a_Component == new && gov.a_Component == new && ~isvalid(comp))
DebugScript.helper.quiet(@() net.initialize);
sol = DebugScript.helper.quiet(@() net.simulate(DebugScript.helper.no_disturbance(net), Time=[0,2]));
assert(sol.flag == 1 && DebugScript.helper.max_state_drift(sol) < 1e-9)


%% export_csv names the governor it does not write
[net, comp, ~, ~, gov] = build_full("after");
s_dir = tempname;  mkdir(s_dir);  c = onCleanup(@() rmdir(s_dir, "s"));
lastwarn("", "");
DebugScript.helper.quiet(@() net.export_csv(fullfile(s_dir, "Net3")));
[str, id] = lastwarn();
assert(string(DebugScript.helper.msg_id(str, id)) == "GUILDA:PowerNetwork:ControllersNotSaved")
assert(contains(str, comp.s_tag + "/" + gov.s_tag), str)


%% A trip of the generator restarts its governor from the equilibrium
% 3母線系統では負荷が発電機1台では賄えないので、I50 と同じ IEEE14 の B003SG1 を解列する
net = DebugScript.helper.build_ieee14();
gen = net.a_Bus{3}.a_Component{1};
gen.add_local_controller("avr-ST1");
gen.add_local_controller("pss-PSS1");
gov = gen.add_local_controller("gov-LPT1", parameter=struct(Prate=2, PLM=5));
DebugScript.helper.quiet(@() net.initialize);
rv_eq = net.rv_Xequilibrium;
ev  = DebugScript.helper.scenario("trip", net, "TimeSpan", [1,1.2], "TripUnit", gen.s_tag);
sol = net.simulate(ev.s_tag, Time=[0,2], Progress="none", TimeLimit=120);
assert(sol.flag == 1, sol.output.message)
assert(isequal(net.rv_Xequilibrium, rv_eq))
tab = gen.get_variable_map();
tab = tab(ismember(tab.Kind, ["x","Vre","Vim","u"]), :);   % the variables in the result
val = sol.get_point(1.2, tab, Side="after");
for c_lc = {gen.a_LocalController{1}, gen.a_LocalController{1}.a_LocalController{1}, gov}
    lc = c_lc{1};
    rv = val(tab.Kind == "x" & tab.Owner == lc.s_tag);
    lv = diag(lc.f_Mass([],[],[],[])) ~= 0;
    assert(max(abs(rv(lv) - lc.rv_Xequilibrium(lv))) < 1e-9, lc.s_tag + " does not restart from its equilibrium")
end


%% An AGC on Pmech adds to the governor output
[net, comp, ~, ~, gov] = build_full("after");
agc = net.add_global_controller("agc-PI", comp.s_tag);
DebugScript.helper.quiet(@() net.initialize);
flag = comp.validate(false);
s_src = flag.inputs{"Pmech","source"};
assert(contains(s_src, gov.s_tag) && contains(s_src, agc.s_tag), s_src)
sol = DebugScript.helper.quiet(@() net.simulate(DebugScript.helper.no_disturbance(net), Time=[0,2]));
assert(sol.flag == 1 && DebugScript.helper.max_state_drift(sol) < 1e-9)
[r_err, r_max] = error_to_linear(net, "B001SG1", comp, 1e-3);
assert(r_max > 1e-6 && r_err < 0.01, "relative error %g", r_err)


function [net, comp, avr, pss, gov] = build_full(s_order)
% 3母線系統の B002SG1 に AVR_DC1 + PSS1 と調速機 IEEJ_LPT1 を付けて initialize する
% s_order: "before" 調速機を先に / "after" 後に / "none" 調速機なし
    [net, comp] = DebugScript.helper.build_3bus("gen-park");
    gov = [];
    if s_order == "before"
        gov = comp.add_local_controller("gov-LPT1", parameter=struct(PLM=5));
    end
    avr = comp.add_local_controller("avr-DC1", parameter=struct(kap=20));
    pss = comp.add_local_controller("pss-PSS1");
    if s_order == "after"
        gov = comp.add_local_controller("gov-LPT1", parameter=struct(PLM=5));
    end
    DebugScript.helper.quiet(@() net.initialize);
end

function [net, comp, gov] = build_gov(s_key, sct_para)
% 3母線系統の B002SG1 に調速機 (モデルキー s_key、パラメータ sct_para) だけを付けて initialize する
    if nargin < 2
        sct_para = struct();
    end
    [net, comp] = DebugScript.helper.build_3bus("gen-park");
    gov = comp.add_local_controller(s_key, parameter=sct_para);
    DebugScript.helper.quiet(@() net.initialize);
end

function [sol, comp, gov] = simulate_step(s_key, sct_para, r_step, rv_span, t_end)
% 調速機 (モデルキー s_key、パラメータ sct_para) を付けた B002SG1 の系統で、B001SG1 の Pmech に r_step を加える
    [net, comp, gov] = build_gov(s_key, sct_para);
    ev  = DebugScript.helper.scenario("step", net, "TimeSpan", rv_span, "InputUnit", "B001SG1", "InputName", "Pmech", "InputValue", r_step);
    sol = DebugScript.helper.quiet(@() net.simulate(ev.s_tag, Time=[0,t_end]));
end

function rv = trajectory(sol, s_owner, s_name)
% 結果から変数の軌道を取り出す
    tab = sol.tab_variable;
    lv  = tab.Owner == s_owner & tab.Name == s_name;
    assert(nnz(lv) == 1, "%s.%s not found", s_owner, s_name)
    rv = sol.rm_variable(:, lv);
end

function rv = unique_time(rv_t)
    rv = unique(rv_t);
end

function iv = unique_index(rv_t)
    [~, iv] = unique(rv_t);
end

function [x, u] = branch_point(gov, rv_p)
% (Pgov, Psv, Pref, Plimit) から各モデルの状態と入力を作る (LVG の入力 e = Pref - Pgov)
    r_gov = rv_p(1);  r_sv = rv_p(2);
    switch numel(gov.sv_x)
        case 2      % LPT3: [Pgov; Psv]
            x = [r_gov; r_sv];
        otherwise
            if gov.sv_x(2) == "Pdr"    % LPT4: [Pgov; Pdr; Psv; Pw], e = Pref + Pgov
                x = [-r_gov; -0.5*r_gov; r_sv; 0.9*r_sv];
            else                        % LPT1: [Pgov; Psv; Pch; Prh]
                x = [r_gov; r_sv; 0.9*r_sv; 0.8*r_sv];
            end
    end
    u = [2e-4; rv_p(3); rv_p(4)];
end

function l = same_list(c1, c2)
% 2つの制御器のセル配列が同じオブジェクトを同じ順に持つか
    l = numel(c1) == numel(c2) && all(cellfun(@(a, b) a == b, reshape(c1,[],1), reshape(c2,[],1)));
end

function [r_dx, r_y] = jacobian_error(s_cls, x, u, param)
% Jacobi_dx, Jacobi_Y と fcn_dx, fcn_y の中心差分の最大差
    f_dx = str2func(s_cls + ".fcn_dx");
    f_y  = str2func(s_cls + ".fcn_y");
    f_Jx = str2func(s_cls + ".Jacobi_dx");
    f_Jy = str2func(s_cls + ".Jacobi_Y");
    V = [1; 0.1];
    [Axx, Bxv, Bxu] = f_Jx(0, x, V, u, param, 60);
    [Cyx, Dyv, Dyu] = f_Jy(0, x, V, u, param, 60);
    z = [x; V; u];
    nx = numel(x);  nu = numel(u);
    split = @(z) {z(1:nx), z(nx+(1:2)), z(nx+2+(1:nu))};
    fd = @(f) fd_jacobian(@(z) call(f, split(z), param), z);
    J_dx = fd(f_dx);
    J_y  = fd(f_y);
    r_dx = max(abs(J_dx - [Axx, Bxv, Bxu]), [], "all");
    r_y  = max(abs(J_y  - [Cyx, Dyv, Dyu]), [], "all");
end

function v = call(f, c_z, param)
    v = f(0, c_z{1}, c_z{2}, c_z{3}, param, 60);
end

function J = fd_jacobian(f, z)
    h = 1e-6;
    f0 = f(z);
    J = zeros(numel(f0), numel(z));
    for k = 1:numel(z)
        e = zeros(size(z));  e(k) = h;
        J(:,k) = (f(z+e) - f(z-e)) / (2*h);
    end
end

function [r_err, r_max] = error_to_linear(net, s_unit, comp, r_step)
% s_unit の Pmech の小さなステップへの comp の omega の応答と Kron モデルの応答の相対誤差
    rv_time = [0,10];
    ev  = DebugScript.helper.scenario("step", net, "TimeSpan", rv_time, "InputUnit", s_unit, "InputName", "Pmech", "InputValue", r_step);
    sol = DebugScript.helper.quiet(@() net.simulate(ev.s_tag, Time=rv_time, Tolerance=1e-8, AbsoluteTolerance=1e-10));

    unit = [];
    for i = 1:numel(net.a_Bus)
        for j = 1:numel(net.a_Bus{i}.a_Component)
            if string(net.a_Bus{i}.a_Component{j}.s_tag) == s_unit
                unit = net.a_Bus{i}.a_Component{j};
            end
        end
    end
    sys = net.get_sys("Method", "Kron");
    i_u = string(sys.InputName) == unit.attach_tag("Pmech");
    i_x = string(sys.StateName) == comp.attach_tag("omega");
    assert(nnz(i_u) == 1 && nnz(i_x) == 1)

    % 台形則 (E は特異でもよい)
    r_dt = 1e-3;
    rv_t = (rv_time(1):r_dt:rv_time(2)).';
    L = sparse(sys.E)/r_dt - sparse(sys.A)/2;
    R = sparse(sys.E)/r_dt + sparse(sys.A)/2;
    b = sys.B(:,i_u)*r_step;
    x = zeros(size(sys.A,1),1);
    rv_lin = zeros(size(rv_t));
    dL = decomposition(L);
    for k = 2:numel(rv_t)
        x = dL\(R*x + b);
        rv_lin(k) = x(i_x);
    end

    [rv_tu, iv_u] = unique(sol.rv_t);
    rv_w = trajectory(sol, comp.s_tag, "omega");
    rv_non = interp1(rv_tu, rv_w(iv_u), rv_t) - comp.rv_Xequilibrium(comp.sv_x == "omega");
    r_err = norm(rv_non - rv_lin)/norm(rv_lin);
    r_max = max(abs(rv_non));
end

function ME = caught(fcn)
% fcn を実行してエラーを返す (エラーにならなければ失敗)
    ME = [];
    try
        fcn();
    catch ME
    end
    assert(~isempty(ME), "No error was raised.")
    ME = struct("identifier", string(DebugScript.helper.msg_id(ME)), "message", string(ME.message));
end
