% 近似線形化の正規デモ
%
% 初期化から線形モデルの取り出し、任意の点での線形化、編集後のエラーまでの標準の手順を示す。
% 実行: DebugScript.Task_linearization  (test_F7_linearization の Canonical linearization demo runs からも呼ばれる)

% 1. 系統を作り、平衡点を求める
net = network.IEEE14bus();
net.initialize();

% 2. 線形モデルを 1 回で求める。sys は記述子形式の状態空間モデル (E dx = A x + B u)
sys = net.get_sys();
[sys_kron, flag, output] = net.get_sys("Algorithm", "Kron");
disp(output.message)
assert(flag && isa(sys, "ss"))

% 3. 結果を残して、方式ごとにモデルを取り出す (線形化は 1 回で済む)
res = net.linearize();
s_feedback = res.get_ss("Feedback");
s_dae      = res.get_ss("DAE");
tab = net.get_variable_map();             % 変数の順 (res.rm_Axx などの行と列)
disp(head(tab))
e_kron = DebugScript.helper.finite_eigs(sys_kron);
assert(DebugScript.helper.same_eigs(e_kron, DebugScript.helper.finite_eigs(s_feedback), 1e-6))
assert(DebugScript.helper.same_eigs(e_kron, DebugScript.helper.finite_eigs(s_dae), 1e-6))

% 4. 入出力を選ぶ。種類 ("x", "V", "I", "y") と名前を指定できる。Input は tab の Label から選ぶ
sv_u = tab.Label(tab.Kind == "u");
s_io = net.get_sys("Output", ["V", "I"], "Input", sv_u(1:2));
assert(numel(s_io.InputName) == 2 && numel(s_io.OutputName) == 4*numel(net.a_Bus))

% 5. シミュレーションの途中の点で線形化する。平衡点でない点は output.message と result.rv_residual に現れる
ev  = odeEventSet("fault", net, "TimeSpan", [0.5,0.55], "FaultBus", "B008");
sim = net.simulate([0,1.5], ev, Progress="none");
[res_t, flag, output] = net.linearize("Point", {sim, 1});
disp(output.message)
assert(flag && output.r_residual == max(abs(res_t.rv_residual)))

% 6. パラメータを編集すると平衡点が古くなり、initialize し直すまで線形化はエラーになる
gen = net.a_Bus{1}.a_Component{1};
gen.tab_parameter.dynamics.D = 2 * gen.tab_parameter.dynamics.D;
try
    net.get_sys();
    error("DebugScript:NoError", "編集後の get_sys がエラーにならない")
catch ME
    assert(DebugScript.helper.msg_id(ME) == "GUILDA:PowerNetwork:EquilibriumStale", DebugScript.helper.msg_id(ME))
    disp(ME.message)
end
net.initialize();
assert(isa(net.get_sys(), "ss"))
