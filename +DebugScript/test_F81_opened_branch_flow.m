% F81 開放・故障したブランチの潮流 (ResultODE.plot_diagram)
%
%   res = net.simulate(...);  G = res.plot_diagram(...);
%   G.sct_state.cm_Ibranch    % 各ブランチの両端からブランチへ流れ込む電流 (2 n_branch x n_t)
%
% ResultODE.sct_branchY は各出力時刻にシミュレーションが使ったブランチの状態のアドミタンス行列
% (iv_Y: 時刻ごとの組の位置、c_Ybranch: 組ごとの 2x2xn_branch) を持ち、plot_diagram の
% ブランチ潮流はそれで計算する。"6open" は 0、"3open" は残りの回線、ブランチ内の地絡中は
% 地絡した模型の両端電流。各時刻で、ブランチ電流の和と母線シャントの電流がソルバーの母線電流
% rm_I に一致する。
%
% 実行: runtests("DebugScript.test_F81_opened_branch_flow")  または  DebugScript.run_all("Features","F81")

% 各テストは見えない figure で始め、終わりに閉じる
fig = figure("Visible", "off");
c_fig = onCleanup(@() close(fig));
c_quiet = DebugScript.helper.user_config("TimeSimulation", struct("Progress", "none"));   % 進捗表示なし (各テストの終わりに元へ戻す)
net = network.IEEE9bus();
DebugScript.helper.quiet(@() net.initialize);
s_br = "EL005";                                  % B004-B006, 2 回線
k  = find(string(net.a_Branch) == s_br);
br = net.a_Branch{k};
iv_end = [find(string(net.a_Bus) == br.a_Bus{1}.s_tag); find(string(net.a_Bus) == br.a_Bus{2}.s_tag)];


%% A 6open branch carries no flow after the opening and a flow before
sc = net.add_scenario("open6");
sc.add_open_branch(s_br, 1);                     % t = 1 から終わりまで開放
[res, flag] = net.simulate("open6", Time=[0, 5]);
assert(flag == 1)
G = res.plot_diagram(Parent=axes(fig), ColorMode="I");
rm_I = abs(G.sct_state.cm_Ibranch(2*k-1:2*k, :));
t = res.rv_t.';
assert(min(rm_I(:, t < 1), [], "all") > 0.1, "開放前は流れる")
i_open = find(t == 1, 1, "last");                % 境界の 2 点目 (開放区間の始め)
assert(t(i_open - 1) == 1 && all(rm_I(:, i_open - 1) > 0.1), "境界の 1 点目は開放前の状態")
assert(all(rm_I(:, i_open:end) == 0, "all"), "開放後は 0")
G.set_time(0.5);
assert(G.BranchColorData(k) > 0.1)
G.set_time(3);
assert(G.BranchColorData(k) == 0, "開放後の色の値は 0")
assert(all(G.BranchColorData([1:k-1, k+1:end]) > 0), "他のブランチは流れる")
lv_open = t > 1;
lv_open(i_open) = true;
assert_kcl(net, res, G, lv_open, table(s_br, "6open", NaN, VariableNames=["Target","Status","Point"]))
assert(isequal(res.sct_branchY.iv_Y(t < 1), ones(nnz(t < 1), 1)) && all(res.sct_branchY.iv_Y(i_open:end) == 2))
assert(isequal(res.sct_branchY.c_Ybranch{2}(:, :, k), zeros(2)))


%% A 3open branch carries the current of the other circuit and settles at the power flow with one circuit
sc = net.add_scenario("open3");
sc.add_open_branch(s_br, 1, Status="3open");
[res, flag] = net.simulate("open3", Time=[0, 40]);
assert(flag == 1)
G = res.plot_diagram(Parent=axes(fig));
cm_I = G.sct_state.cm_Ibranch(2*k-1:2*k, :);
cm_V = G.sct_state.cm_Vbus;
t = res.rv_t.';
Y_3open = br.get_admittance_matrix(Status="3open");
Y_close = br.get_admittance_matrix();
lv_open = t > 1;
lv_open(find(t == 1, 1, "last")) = true;
err = max(abs(cm_I(:, lv_open) - Y_3open*cm_V(iv_end, lv_open)), [], "all");
assert(err < 1e-12, "開放区間は 1 回線の行列: " + err)
err = max(abs(cm_I(:, ~lv_open) - Y_close*cm_V(iv_end, ~lv_open)), [], "all");
assert(err < 1e-12, "開放前は閉じた行列: " + err)
assert_kcl(net, res, G, lv_open, table(s_br, "3open", NaN, VariableNames=["Target","Status","Point"]))
% 長く開放した後の潮流は、1 回線にした系統の潮流計算の解に近い (模型の定常状態は周波数の
% ずれと一定の界磁電圧を持ち、潮流計算は PV 母線の電圧を保つので、許容差は 10 %)
rv_S = cm_V(iv_end, end) .* conj(cm_I(:, end));
net1 = network.IEEE9bus();
p = net1.a_Branch{k}.tab_parameter.dynamics;
n = p.circuit;
net1.a_Branch{k}.tab_parameter.dynamics(:, ["R","X","C","circuit"]) = {p.R*n/(n-1), p.X*n/(n-1), p.C*(n-1)/n, n-1};
assert(max(abs(net1.a_Branch{k}.get_admittance_matrix() - Y_3open), [], "all") < 1e-12, "前提: 1 回線の系統の行列は 3open")
cv_V1 = DebugScript.helper.quiet(@() net1.calculate_powerflow(Format="V"));
rv_S1 = cv_V1(iv_end) .* conj(Y_3open*cv_V1(iv_end));
err = max(abs(real(rv_S - rv_S1)))/abs(real(rv_S1(1)));
assert(err < 0.1, "P の相対差 " + err)
% 閉じた行列で計算した値 (以前の表示) とは区別できる
rv_Sclose = cm_V(iv_end, end) .* conj(Y_close*cm_V(iv_end, end));
assert(max(abs(rv_Sclose - rv_S)) > 0.1)


%% During a fault inside a branch its ends carry the currents of the faulted branch
sc = net.add_scenario("fault");
sc.add_fault(s_br, [1, 1.05], Status="3LG", Point=0.3);
[res, flag] = net.simulate("fault", Time=[0, 1.5]);
assert(flag == 1)
G = res.plot_diagram(Parent=axes(fig));
cm_I = G.sct_state.cm_Ibranch(2*k-1:2*k, :);
cm_V = G.sct_state.cm_Vbus;
t = res.rv_t.';
i_on  = find(t == 1, 1, "last");
i_off = find(t == 1.05, 1, "first");
lv_fault = false(size(t));
lv_fault(i_on:i_off) = true;
Y_fault = br.get_admittance_matrix(Status="3LG", Point=0.3);
err = max(abs(cm_I(:, lv_fault) - Y_fault*cm_V(iv_end, lv_fault)), [], "all");
assert(err < 1e-12, "地絡中は地絡した模型: " + err)
assert(all(abs(cm_I(:, lv_fault)) > 1, "all"), "両端から地絡点へ流れる")
rm_S = cm_V(iv_end, lv_fault) .* conj(cm_I(:, lv_fault));
assert(all(real(rm_S) > 0, "all"), "両端ともブランチへ有効電力を送る")
err = max(abs(cm_I(:, ~lv_fault) - br.get_admittance_matrix()*cm_V(iv_end, ~lv_fault)), [], "all");
assert(err < 1e-12, "地絡の前後は閉じた行列: " + err)
assert_kcl(net, res, G, lv_fault, table(s_br, "3LG", 0.3, VariableNames=["Target","Status","Point"]))


%% A diagram state without branch matrices uses the matrices of the snapshot
sct = struct(net, false);
cv_V = cellfun(@(b) b.c_Vequilibrium, net.a_Bus(:));
c_I  = cellfun(@(b) reshape(cellfun(@(c) c.c_Iequilibrium, b.a_Component), [], 1), net.a_Bus(:), "UniformOutput", false);
cv_I = vertcat(c_I{:});
G = GraphNetDiagram(sct, struct("rv_t", 0, "cm_Vbus", cv_V, "cm_Icomp", cv_I), Parent=axes(fig));
assert(max(abs(G.sct_state.cm_Ibranch(2*k-1:2*k) - br.get_admittance_matrix()*cv_V(iv_end))) < 1e-12)
% 行列の組の位置が範囲外なら止まる
sct_state = struct("rv_t", 0, "cm_Vbus", cv_V, "cm_Icomp", cv_I, "c_Ybranch", {{zeros(2, 2, numel(net.a_Branch))}}, "iv_Ybranch", 2);
assert(error_id(@() GraphNetDiagram(sct, sct_state, Parent=axes(fig))) == "GUILDA:GraphNetDiagram:StateSize")
sct_state.iv_Ybranch = 1;
G = GraphNetDiagram(sct, sct_state, Parent=axes(fig));
assert(all(G.sct_state.cm_Ibranch == 0))


function assert_kcl(net, res, G, lv_t, tab_state)
% At the times lv_t the branch currents of the diagram plus the bus shunts give the bus
% currents of the solver (rm_I), and the network matrix of tab_state gives them too
    arguments (Input)
        net               % Network of the run.
        res               % ResultODE.
        G                 % GraphNetDiagram of res.plot_diagram.
        lv_t (1,:) logical  % Times to check.
        tab_state table   % Branch states of those times.
    end
    n_bus = numel(net.a_Bus);
    a_br  = net.a_Branch;
    cm_V  = G.sct_state.cm_Vbus(:, lv_t);
    cm_Ib = G.sct_state.cm_Ibranch(:, lv_t);
    cm_Ibus = zeros(n_bus, nnz(lv_t));
    for m = 1:numel(a_br)
        iv_e = [find(string(net.a_Bus) == a_br{m}.a_Bus{1}.s_tag); find(string(net.a_Bus) == a_br{m}.a_Bus{2}.s_tag)];
        cm_Ibus(iv_e, :) = cm_Ibus(iv_e, :) + cm_Ib(2*m-1:2*m, :);
    end
    cv_shunt = cellfun(@(b) b.tab_parameter.dynamics.Gshunt + 1j*b.tab_parameter.dynamics.Bshunt, net.a_Bus(:));
    cm_Ibus = cm_Ibus + cv_shunt .* cm_V;
    cm_Isim = res.rm_I(lv_t, 1:2:end).' + 1j*res.rm_I(lv_t, 2:2:end).';
    err = max(abs(cm_Ibus - cm_Isim), [], "all");
    assert(err < 1e-9, "ブランチ電流の和とソルバーの母線電流: " + err)
    Y = net.get_admittance_matrix(BranchStatus=tab_state).Variables;
    err = max(abs(Y*cm_V - cm_Isim), [], "all");
    assert(err < 1e-9, "状態の網の行列: " + err)
end


function id = error_id(f)
% Identifier of the error that f throws ("" when none)
    arguments (Input)
        f function_handle  % Function to call.
    end
    arguments (Output)
        id (1,1) string  % Error identifier.
    end
    id = "";
    try
        f();
    catch me
        id = string(DebugScript.helper.msg_id(me));
    end
end
