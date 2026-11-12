% F36 全モデル入りのチュートリアル網 (network.Tutorial10bus)
%
%   net = network.Tutorial10bus();
%
% GUILDA.keymap に登録されたすべての機器、ローカル制御器、グローバル制御器、ブランチを 1 つの網に含み、
% 空の母線 (B006) も持つ。キーを追加したのにこの網へ入れていなければ最初のテストが失敗する。
% initialize、線形化 (Kron / DAE の固有値の一致と安定性)、変数表の AGC の接続、
% B008 の三相地絡のシミュレーションを確かめる。
%
% 実行: runtests("DebugScript.test_F36_tutorial_all_models")  または  DebugScript.run_all("Features","F36")

% 共通設定 (各テストの前に毎回実行される)
c_quiet = DebugScript.helper.user_config("TimeSimulation", struct("Progress", "none"));   % 進捗表示なし (各テストの終わりに元へ戻す)
net = DebugScript.helper.quiet(@() network.Tutorial10bus());


%% The network has every registered model key and an empty bus
% 網にある機器、ローカル制御器 (入れ子の PSS を含む)、グローバル制御器、ブランチのクラス
a_comp = [net.a_Bus{:}];
a_comp = vertcat(a_comp.a_Component);
a_lc = {};
for k = 1:numel(a_comp)
    a_lc = [a_lc; nested_controllers(a_comp{k})]; %#ok<AGROW>
end
sct_used = struct( ...
    "Component",        {cellfun(@class, a_comp, "UniformOutput", false)}, ...
    "LocalController",  {cellfun(@class, a_lc, "UniformOutput", false)}, ...
    "GlobalController", {cellfun(@class, net.a_GlobalController, "UniformOutput", false)}, ...
    "Branch",           {cellfun(@class, net.a_Branch, "UniformOutput", false)});
for s_cat = ["Component", "LocalController", "GlobalController", "Branch"]
    dic = GUILDA.keymap(s_cat);
    sv_key = keys(dic);
    lv = ismember(values(dic), string(sct_used.(s_cat)));
    assert(all(lv), "%s のキーが網にない: %s", s_cat, join(sv_key(~lv), ", "))
end
% 空の母線 (機器のない母線) がある
assert(isempty(net.a_Bus{6}.a_Component), "B006 は空の母線")
assert(numel(net.a_Bus) == 10)


%% initialize gives the equilibrium of every component
DebugScript.helper.quiet(@() net.initialize);
assert(net.a_Bus{1}.s_bustype == "slack")
for i = 1:numel(net.a_Bus)
    for k = 1:numel(net.a_Bus{i}.a_Component)
        comp = net.a_Bus{i}.a_Component{k};
        [r_dx, r_I] = DebugScript.helper.equilibrium_residual(comp);
        assert(r_dx < 1e-8 && r_I < 1e-8, "%s: dx %g, I %g", comp.s_tag, r_dx, r_I)
    end
end


%% Kron and DAE give the same stable eigenvalues
res = net.get_sys();
eK = DebugScript.helper.finite_eigs(DebugScript.helper.quiet(@() res.get_ss("Kron")));
eD = DebugScript.helper.finite_eigs(DebugScript.helper.quiet(@() res.get_ss("DAE")));
assert(DebugScript.helper.same_eigs(eK, eD, 1e-6), "Kron と DAE の固有値が違う")
% 回転子の共通の角度のモードだけが 0、ほかは実部が負
lv_zero = abs(eK) < 1e-8;
assert(nnz(lv_zero) == 1, "0 の固有値が %d 個", nnz(lv_zero))
assert(max(real(eK(~lv_zero))) < -1e-3, "最大の実部 %g", max(real(eK(~lv_zero))))


%% The variable map routes the AGC between the omega outputs and the Pmech inputs
[tab, ~, ~, tab_c] = net.get_variable_map();
gc = net.a_GlobalController{1};
sv_unit = string(cellfun(@(c) c.s_tag, gc.controlledUnits, "UniformOutput", false));
assert(isequal(sort(sv_unit(:)), ["B001SG1"; "B002SG1"; "B003SG1"; "B004SG1"]), join(sv_unit, ", "))
for s_unit = reshape(sv_unit, 1, [])
    unit = gc.controlledUnits{sv_unit == s_unit};
    % AGC の出力 Pmech は機器の入力 Pmech へ (調速機は Pmech の入力を持たない)
    lv = tab_c.Kind == "global" & tab.Owner(max(tab_c.SourceIndex,1)) == string(gc.s_tag) & tab_c.Target == unit.attach_tag("Pmech");
    assert(nnz(lv) == 1, "%s: Pmech への接続が %d 本", s_unit, nnz(lv))
    % AGC の入力 omega は機器の出力 omega から
    lv = tab_c.Kind == "observe" & tab.Owner(max(tab_c.TargetIndex,1)) == string(gc.s_tag) & tab.Owner(max(tab_c.SourceIndex,1)) == s_unit;
    assert(nnz(lv) == 1 && tab.Name(tab_c.SourceIndex(lv)) == "omega", "%s: omega の観測", s_unit)
end
assert(nnz(tab_c.Kind == "global") == numel(sv_unit))


%% A three-phase fault on bus 8 settles
sc = net.add_scenario("fault", Time=[0,10]);
sc.add_fault("B008", [1,1.05]);
[sol, flag] = DebugScript.helper.quiet(@() net.simulate(sc.s_tag));
assert(flag == 1 && isa(sol, "ResultODE"))
r = sol.odeResults;
assert(r.t(end) == 10)
for i = 1:4
    omega = r.Bus(i).Component(1).X.omega;
    assert(max(abs(omega)) > 1e-5, "B%03d: 地絡で動く", i)
    assert(abs(omega(end)) < 1e-3, "B%03d: omega(end) = %g", i, omega(end))
end


function a_lc = nested_controllers(obj)
% obj のローカル制御器と、その下の入れ子の制御器 (深さ優先)
    arguments (Input)
        obj  % 機器またはローカル制御器
    end
    arguments (Output)
        a_lc (:,1) cell  % ローカル制御器
    end
    a_lc = cell(0,1);
    for k = 1:numel(obj.a_LocalController)
        lc = obj.a_LocalController{k};
        a_lc = [a_lc; {lc}; nested_controllers(lc)]; %#ok<AGROW>
    end
end
