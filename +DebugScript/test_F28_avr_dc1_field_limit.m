% F28 AVR_DC1 の界磁電圧制限
%
% AVR_DC1 の励磁器 (一次遅れ) に non-windup の制限 Vfld_min <= Vfld <= Vfld_max を付けた。
% 既定 (±Inf) では従来と同じ応答になり、制限を付けると事故時に Vfld が制限で止まる。
% 平衡点の界磁電圧が制限の外にあるときは AVR_DC1 の ID のエラーになる。
%
% 実行: runtests("DebugScript.test_F28_avr_dc1_field_limit")  または  DebugScript.run_all("Features","F28")

% 共通設定 (各テストの前に毎回実行される)
r_tol = 1e-4;


c_quiet = DebugScript.helper.user_config("TimeSimulation", struct("Progress", "none"));   % 進捗表示なし (各テストの終わりに元へ戻す)

%% Parameters are appended after the existing ones
[~, gen] = DebugScript.helper.build_3bus("gen-1axis");
avr = gen.add_local_controller("avr-DC1", parameter=struct(Vfld_max=4, Vfld_min=0));
assert(isequal(avr.sv_para(end-1:end), ["Vfld_max"; "Vfld_min"]))
assert(isequal(avr.sv_para(1:11), ["ttr"; "Vap_max"; "Vap_min"; "kap"; "tap"; "aex1"; "aex2"; "tex"; "bex"; "kst"; "tst"]))
tab = avr.tab_parameter.dynamics;
assert(tab{:,"Vfld_max"} == 4 && tab{:,"Vfld_min"} == 0)
[~, gen] = DebugScript.helper.build_3bus("gen-1axis");
tab = gen.add_local_controller("avr-DC1").tab_parameter.dynamics;
assert(tab{:,"Vfld_max"} == Inf && tab{:,"Vfld_min"} == -Inf)


%% Default limits give the same trajectory as no limits
sol1 = simulate_fault(struct(kap=20));
sol2 = simulate_fault(struct(kap=20, Vfld_max=Inf, Vfld_min=-Inf));
assert(sol1.flag == 1)
assert(isequal(sol1.rv_t, sol2.rv_t) && isequal(sol1.rm_variable, sol2.rm_variable))


%% Upper limit clips the field voltage in a fault
r_eq = field_equilibrium(struct(kap=20));
r_max = r_eq + 0.05;
[sol, avr] = simulate_fault(struct(kap=20, Vfld_max=r_max));
assert(sol.flag == 1, "flag %d", sol.flag)
rv_fld = field_trajectory(sol, avr);
assert(max(rv_fld) <= r_max + r_tol, "max Vfld %g > %g", max(rv_fld), r_max)
assert(max(rv_fld) > r_max - r_tol, "the limit is not reached: %g", max(rv_fld))
sol0 = simulate_fault(struct(kap=20));
assert(max(field_trajectory(sol0, avr)) > r_max + 0.5, "without the limit Vfld rises above it")


%% Lower limit 0 clips the field voltage
% 発電機の Eq を 1 pu 上げて端子電圧を上げると、kap=200 の AVR は Vfld を負へ下げようとする
[sol, avr] = simulate_offset(struct(kap=200, Vfld_min=0));
assert(sol.flag == 1, "flag %d", sol.flag)
rv_fld = field_trajectory(sol, avr);
assert(min(rv_fld) >= -r_tol, "min Vfld %g", min(rv_fld))
assert(min(rv_fld) < r_tol, "the limit is not reached: %g", min(rv_fld))
[sol0, avr0] = simulate_offset(struct(kap=200));
assert(min(field_trajectory(sol0, avr0)) < -1, "without the limit Vfld goes below 0")


%% Equilibrium outside the field limits is an error
r_eq = field_equilibrium(struct(kap=20));
[ME, avr] = initialize_error(struct(kap=20, Vfld_max=r_eq - 0.1));
check_error(ME, avr.s_tag, "[-Inf, " + num2str(r_eq - 0.1) + "]")
[ME, avr] = initialize_error(struct(kap=20, Vfld_min=r_eq + 0.1));
check_error(ME, avr.s_tag, "[" + num2str(r_eq + 0.1) + ", Inf]")


%% validate passes and the Jacobian agrees inside the limits
[net, comp] = DebugScript.helper.build_3bus("gen-park");
comp.add_local_controller("avr-DC1", parameter=struct(kap=20, Vfld_max=4, Vfld_min=0));
DebugScript.helper.quiet(@() net.initialize);
flag = comp.a_LocalController{1}.validate(false);
lv = flag.contract.status == "FAIL";
assert(~any(lv), "%s", join(flag.contract.Properties.RowNames(lv), ", "))
for fn = ["Axx","Bxv","Bxu","Cyx","Dyv","Dyu"]
    if isfield(flag, fn) && ~isempty(flag.(fn)) && width(flag.(fn)) > 0
        r = max(flag.(fn){:,:}, [], "all");
        assert(r < 1e-5, "%s %g", fn, r);
    end
end


%% Jacobi_dx matches finite differences inside and at the limits
[~, gen] = DebugScript.helper.build_3bus("gen-1axis");
avr = gen.add_local_controller("avr-DC1", parameter=struct(kap=20, Vfld_max=4, Vfld_min=0));
param = avr.tab_parameter.dynamics{:, cellstr(avr.sv_para)}';
V = [1.0; 0.1];  u = [1.1; 0];
% 制限の内側: 有限差分と一致する
x = [1.0; 2.0; 2.0; 0.0];
Axx = controller.avr.AVR_DC1.Jacobi_dx(0, x, V, u, param, 60);
assert(norm(Axx - fd_jacobian(x, V, u, param), "inf") < 1e-5)
% 上限で外へ向かう (制限なしの dVfld/dt > 0): dVfld/dt = 0 で行は 0
x = [1.0; 20.0; 4.0; 0.0];
assert(-(param(6) + param(7)*exp(param(9)*x(3)))*x(3) + x(2) > 0)
dx = controller.avr.AVR_DC1.fcn_dx(0, x, V, u, param, 60);
Axx = controller.avr.AVR_DC1.Jacobi_dx(0, x, V, u, param, 60);
assert(dx(3) == 0 && all(Axx(3,:) == 0))
% 下限で外へ向かう
x = [1.0; -1.0; 0.0; 0.0];
dx = controller.avr.AVR_DC1.fcn_dx(0, x, V, u, param, 60);
Axx = controller.avr.AVR_DC1.Jacobi_dx(0, x, V, u, param, 60);
assert(dx(3) == 0 && all(Axx(3,:) == 0))
% 上限で内へ戻る: 制限は効かない
x = [1.0; 1.0; 4.0; 0.0];
dx = controller.avr.AVR_DC1.fcn_dx(0, x, V, u, param, 60);
assert(dx(3) < 0)
% 止まっている間は安定化回路にも dVfld/dt = 0 が入る (質量行列の -kst の項)
M = controller.avr.AVR_DC1.fcn_Mass(0, x, V, u, param, 60);
x = [1.0; 20.0; 4.0; 0.3];
dx = controller.avr.AVR_DC1.fcn_dx(0, x, V, u, param, 60);
r_dx = M \ dx;
assert(r_dx(3) == 0 && abs(r_dx(4) - (-x(4)/param(11))) < 1e-12)


function [sol, avr] = simulate_fault(sct_para)
% AVR_DC1 (パラメータ sct_para) を付けた3母線系統で B003 の地絡を simulate する
    [net, comp] = DebugScript.helper.build_3bus("gen-park");
    avr = comp.add_local_controller("avr-DC1", parameter=sct_para);
    DebugScript.helper.quiet(@() net.initialize);
    ev  = DebugScript.helper.scenario("fault", net, "TimeSpan", [1,1.05], "FaultBus", "B003");
    sol = DebugScript.helper.quiet(@() net.simulate([0,5], ev));
end

function [sol, avr] = simulate_offset(sct_para)
% AVR_DC1 (パラメータ sct_para) を付けた発電機の Eq を 1 pu 上げて simulate する
    [net, comp] = DebugScript.helper.build_3bus("gen-park");
    avr = comp.add_local_controller("avr-DC1", parameter=sct_para);
    DebugScript.helper.quiet(@() net.initialize);
    ev  = DebugScript.helper.scenario("offset", net, "TimeSpan", 0, "OffsetUnit", comp.s_tag, "OffsetState", "Eq", "OffsetValue", 1);
    sol = DebugScript.helper.quiet(@() net.simulate([0,5], ev));
end

function r_eq = field_equilibrium(sct_para)
% AVR_DC1 (パラメータ sct_para) を付けた3母線系統を initialize し、平衡点の界磁電圧を返す
    [net, comp] = DebugScript.helper.build_3bus("gen-park");
    avr = comp.add_local_controller("avr-DC1", parameter=sct_para);
    DebugScript.helper.quiet(@() net.initialize);
    r_eq = avr.rv_Xequilibrium(3);
end

function rv_fld = field_trajectory(sol, avr)
% 結果から AVR の Vfld の軌道を取り出す
    tab = sol.tab_variable;
    rv_fld = sol.rm_variable(:, tab.Owner == avr.s_tag & tab.Name == "Vfld");
end

function [ME, avr] = initialize_error(sct_para)
% AVR_DC1 (パラメータ sct_para) を付けた系統を initialize し、発生したエラーと AVR を返す
    [net, comp] = DebugScript.helper.build_3bus("gen-park");
    avr = comp.add_local_controller("avr-DC1", parameter=sct_para);
    ME = [];
    try
        DebugScript.helper.quiet(@() net.initialize);
    catch ME
    end
    assert(~isempty(ME), "範囲エラーが発生しなかった")
end

function check_error(ME, s_tag, s_limits)
% エラーの ID と、文言の機器名・上下限・対処を確認する
    assert(DebugScript.helper.msg_id(ME) == "GUILDA:AVR_DC1:FieldOutOfRange", "ID が " + DebugScript.helper.msg_id(ME))
    str = string(ME.message);
    assert(~contains(str, "ID specification"), str)
    assert(contains(str, "AVR_DC1 '" + s_tag + "'"), str)
    assert(contains(str, s_limits), str)
    assert(contains(str, "Widen Vfld_min and Vfld_max"), str)
end

function A = fd_jacobian(x, V, u, param)
% fcn_dx の x についての中心差分
    h = 1e-6;
    A = zeros(numel(x));
    for k = 1:numel(x)
        e = zeros(size(x));  e(k) = h;
        A(:,k) = (controller.avr.AVR_DC1.fcn_dx(0, x+e, V, u, param, 60) ...
                - controller.avr.AVR_DC1.fcn_dx(0, x-e, V, u, param, 60)) / (2*h);
    end
end
