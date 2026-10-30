function [net, gen] = build_smib()
% 1機無限大母線系統 (近似) を作成する
%
%   [net, gen] = DebugScript.helper.build_smib()
%
%   B001: gen-1axis (P = 0.8)  --  X = 0.3  --  B002: 無限大母線 (slack, |V| = 1)
% 無限大母線は慣性 M = 1e8、リアクタンス 1e-4 の gen-classical で近似する。
% controller.local_LQR の設計モデル (V0 = 1 の無限大母線) と同じ系統になる。
    net = PowerNetwork("SMIB");
    net.add_bus("V",1.00);
    net.add_bus("V",1.00);
    net.add_branch("pi",[1,2], "R",0, "X",0.3);
    gen = net.a_Bus{1}.add_component("gen-1axis", "P", 0.8, "Q", nan);
    inf = net.a_Bus{2}.add_component("gen-classical");
    inf.para_dynamics.M  = 1e8;
    inf.para_dynamics.D  = 0;
    inf.para_dynamics.Xd = 1e-4;
    inf.para_dynamics.Xq = 1e-4;
    evalc("net.a_Bus{2}.l_isSlack = true;");     % 表示 (INFO) は抑制
    net.solver_ODE.Progress = "none";
end
