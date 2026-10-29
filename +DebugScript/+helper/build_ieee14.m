function net = build_ieee14()
% IEEE 14 母線系統 (network.IEEE14bus) をバッチ実行向けの設定で作成する
%
%   net = DebugScript.helper.build_ieee14()
%
% network.IEEE14bus はコンストラクタ内で CSV を読み込むだけで、平衡点は未設定。
% 時間応答シミュレーションの進捗ダイアログを出さないよう Progress を "none" にする。
    net = network.IEEE14bus;
    net.solver_ODE.Progress = "none";
end
