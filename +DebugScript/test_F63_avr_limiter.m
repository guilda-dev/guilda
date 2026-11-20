% F63 AVR のリミッタの ON/OFF (dynamics の列 Limiter)
%
% AVR_ST1 と AVR_DC1 の dynamics に論理値の列 Limiter (既定 true) がある。
% false にすると、その AVR の上下限 (平衡点の範囲の検査を含む) をすべて無視し、
% 上下限を ±Inf にした場合と同じ軌道になる。
%
% 実行: runtests("DebugScript.test_F63_avr_limiter")  または  DebugScript.run_all("Features","F63")

% 共通設定 (各テストの前に毎回実行される)
c_quiet = DebugScript.helper.user_config("TimeSimulation", struct("Progress", "none"));   % 進捗表示なし (各テストの終わりに元へ戻す)

%% Limiter is the last parameter and is true by default
for s_key = ["avr-ST1", "avr-DC1"]
    [~, gen] = DebugScript.helper.build_3bus("gen-1axis");
    avr = gen.add_local_controller(s_key);
    % AVR_ST1 は Limiter の後に出力の上下限 (gamma_max, gamma_min, k0。test_F79) を持つ
    assert(avr.sv_para(end) == "Limiter" || (s_key == "avr-ST1" && isequal(avr.sv_para(end-3:end), ["Limiter"; "gamma_max"; "gamma_min"; "k0"])))
    tab = avr.tab_parameter.dynamics;
    assert(islogical(tab.Limiter) && tab.Limiter)
    [~, gen] = DebugScript.helper.build_3bus("gen-1axis");
    avr = gen.add_local_controller(s_key, parameter=struct(Limiter=false));
    assert(~avr.tab_parameter.dynamics.Limiter)
end


%% AVR_ST1 with Limiter false follows the trajectory without limits
sct_lim = struct(kap=20, Vap_max=3, Vap_min=1);
sol0 = simulate_fault("avr-ST1", struct(kap=20));
sol1 = simulate_fault("avr-ST1", setfield(sct_lim, "Limiter", false));
sol2 = simulate_fault("avr-ST1", sct_lim);
assert(sol0.flag == 1 && sol1.flag == 1 && sol2.flag == 1)
assert(isequaln(sol0.rv_t, sol1.rv_t) && isequaln(sol0.rm_variable, sol1.rm_variable))
assert(~isequal(size(sol0.rm_variable), size(sol2.rm_variable)) || ~isequal(sol0.rm_variable, sol2.rm_variable), "the limits have no effect")


%% AVR_DC1 with Limiter false follows the trajectory without limits
sct_lim = struct(kap=20, Vap_max=4, Vap_min=1, Vfld_max=2.3, Vfld_min=0);
sol0 = simulate_fault("avr-DC1", struct(kap=20));
sol1 = simulate_fault("avr-DC1", setfield(sct_lim, "Limiter", false));
[sol2, avr] = simulate_fault("avr-DC1", sct_lim);
assert(sol0.flag == 1 && sol1.flag == 1 && sol2.flag == 1)
assert(isequaln(sol0.rv_t, sol1.rv_t) && isequaln(sol0.rm_variable, sol1.rm_variable))
assert(max(trajectory(sol2, avr, "Vfld")) <= 2.3 + 1e-4)
assert(max(trajectory(sol0, avr, "Vfld")) > 2.3 + 0.1, "without the limits Vfld rises above 2.3")


%% Limiter false skips the range check at the equilibrium
for c = {{"avr-ST1", struct(Vap_max=0.1)}, {"avr-DC1", struct(Vap_max=0.1)}, {"avr-DC1", struct(Vfld_max=0.1)}}
    [net, comp] = DebugScript.helper.build_3bus("gen-park");
    comp.add_local_controller(c{1}{1}, parameter=setfield(c{1}{2}, "Limiter", false));
    [~, flag] = DebugScript.helper.quiet(@() net.initialize());
    assert(flag > 0 && ~DebugScript.helper.is_stale(net))
end


%% The range error suggests setting Limiter to false
for s_key = ["avr-ST1", "avr-DC1"]
    [net, comp] = DebugScript.helper.build_3bus("gen-park");
    comp.add_local_controller(s_key, parameter=struct(Vap_max=0.1));
    ME = [];
    try
        DebugScript.helper.quiet(@() net.initialize);
    catch ME
    end
    assert(~isempty(ME) && endsWith(DebugScript.helper.msg_id(ME), ":InvalidValueRange"), s_key)
    assert(contains(ME.message, "set Limiter to false"), ME.message)
end


%% Editing Limiter makes the equilibrium and odefcn stale
[net, comp] = DebugScript.helper.build_3bus("gen-park");
avr = comp.add_local_controller("avr-ST1", parameter=struct(kap=20));
DebugScript.helper.quiet(@() net.initialize);
assert(isempty(avr.sct_stale.equilibrium) && isempty(avr.sct_stale.odefcn))
avr.tab_parameter.dynamics.Limiter = false;
assert(~isempty(avr.sct_stale.equilibrium) && ~isempty(avr.sct_stale.odefcn))
DebugScript.helper.quiet(@() net.initialize);
assert(~DebugScript.helper.is_stale(net))


%% validate passes and the Jacobians agree with the limiter on and off
for s_key = ["avr-ST1", "avr-DC1"]
    for l_limiter = [true, false]
        [net, comp] = DebugScript.helper.build_3bus("gen-park");
        comp.add_local_controller(s_key, parameter=struct(kap=20, Vap_max=10, Vap_min=-10, Limiter=l_limiter));
        DebugScript.helper.quiet(@() net.initialize);
        flag = comp.a_LocalController{1}.validate(false);
        lv = flag.contract.status == "FAIL";
        assert(~any(lv), "%s", join(flag.contract.Properties.RowNames(lv), ", "))
        for fn = ["Axx","Bxv","Bxu","Cyx","Dyv","Dyu"]
            if isfield(flag, fn) && ~isempty(flag.(fn)) && width(flag.(fn)) > 0
                r = max(flag.(fn){:,:}, [], "all");
                assert(r < 1e-5, "%s %s %g", s_key, fn, r);
            end
        end
    end
end


%% AVR_ST1 non-windup limit keeps Vap within the limits
% 平衡点は Vap = 2.206。上限を越える量はソルバーの刻みの分 (1e-3 以下) だけ
[sol, avr] = simulate_fault("avr-ST1", struct(kap=20, Vap_max=3, Vap_min=2.15));
assert(sol.flag == 1)
rv_ap = trajectory(sol, avr, "Vap");
assert(max(rv_ap) <= 3 + 1e-3 && min(rv_ap) >= 2.15 - 1e-3, "Vap %g to %g", min(rv_ap), max(rv_ap))
assert(max(rv_ap) > 3 - 1e-3 && min(rv_ap) < 2.15 + 1e-3, "the limits are not reached: %g to %g", min(rv_ap), max(rv_ap))


%% AVR_ST1 Jacobi_dx matches finite differences inside and at the limits
[~, gen] = DebugScript.helper.build_3bus("gen-1axis");
avr = gen.add_local_controller("avr-ST1", parameter=struct(kap=20, Vap_max=3, Vap_min=1));
param = avr.tab_parameter.dynamics{:, cellstr(avr.sv_para)}';
V = [1.0; 0.1];
% 内側では有限差分と一致し、上限と下限で外へ向かう点では Vap の行が 0 (Vcom = Vref - Vtr)
for c = {{[1.0; 2.0; 0.0], [1.1; 0], true}, {[1.0; 3.0; 0.0], [1.3; 0], false}, {[1.0; 1.0; 0.0], [0.9; 0], false}}
    [x, u] = c{1}{1:2};
    dx  = controller.avr.AVR_ST1.fcn_dx(0, x, V, u, param, 60);
    [Axx, ~, Bxu] = controller.avr.AVR_ST1.Jacobi_dx(0, x, V, u, param, 60);
    if c{1}{3}
        A = zeros(3);
        for k = 1:3
            e = zeros(3,1);  e(k) = 1e-6;
            A(:,k) = (controller.avr.AVR_ST1.fcn_dx(0, x+e, V, u, param, 60) ...
                    - controller.avr.AVR_ST1.fcn_dx(0, x-e, V, u, param, 60)) / 2e-6;
        end
        assert(norm(Axx - A, "inf") < 1e-5)
    else
        assert(dx(2) == 0 && all(Axx(2,:) == 0) && all(Bxu(2,:) == 0), "x = %s", mat2str(x'))
    end
end
% Limiter = false では上限でも止まらない
param(avr.sv_para == "Limiter") = 0;
dx = controller.avr.AVR_ST1.fcn_dx(0, [1.0; 3.0; 0.0], V, [1.3; 0], param, 60);
assert(dx(2) > 0)


%% IEEE68bus AVRs have the limiter on with +-5 pu
net = DebugScript.helper.quiet(@() network.IEEE68bus);
for i = 1:16
    avr = net.a_Bus{i}.a_Component{1}.a_LocalController{1};
    tab = avr.tab_parameter.dynamics;
    assert(isa(avr, "controller.avr.AVR_ST1") && tab.Limiter && tab.Vap_max == 5 && tab.Vap_min == -5, avr.s_tag)
end


function [sol, avr] = simulate_fault(s_key, sct_para)
% AVR (s_key, パラメータ sct_para) を付けた3母線系統で B003 の地絡を simulate する
    [net, comp] = DebugScript.helper.build_3bus("gen-park");
    avr = comp.add_local_controller(s_key, parameter=sct_para);
    DebugScript.helper.quiet(@() net.initialize);
    ev  = DebugScript.helper.scenario("fault", net, "TimeSpan", [1,1.05], "FaultBus", "B003");
    sol = DebugScript.helper.quiet(@() net.simulate(ev.s_tag, Time=[0,5]));
end

function rv = trajectory(sol, avr, s_name)
% 結果から AVR の状態 s_name の軌道を取り出す
    tab = sol.tab_variable;
    rv  = sol.rm_variable(:, tab.Owner == avr.s_tag & tab.Name == s_name);
end
