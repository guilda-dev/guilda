function net = build_9bus(opt)
% 9母線テスト系統 (旧 Task1_NetBuild + Task2_CalculatePowerFlow の設定) を作成する
%
%   net = DebugScript.helper.build_9bus()
%   net = DebugScript.helper.build_9bus("Feasible", false)
%
% 母線・送電線・機器の構成と潮流設定は Task1/Task2 と同じ。
% ただし Task1 の送電線は既定値 (R=0, X=1) のままで潮流解が存在しないため、
% 既定では IEEE 9 母線 (Anderson & Fouad) の線路定数を与える。
% "Feasible", false にすると Task1 と同じ既定定数のまま (非収束ケース) で作成する。
    arguments
        opt.Feasible (1,1) logical = true
    end

% ネットワーククラスの定義
    net = PowerNetwork("TestSystem");

% Busクラスの定義
    for i = 1:9
        net.add_bus();
    end

% Branchクラスの定義  [from, to, R, X, C(=B/2)]
    if opt.Feasible
        tr = [1,4, 0,     0.0576, 0
              2,7, 0,     0.0625, 0
              3,9, 0,     0.0586, 0];
        ln = [4,5, 0.010, 0.085,  0.0880
              4,6, 0.017, 0.092,  0.0790
              5,7, 0.032, 0.161,  0.1530
              6,9, 0.039, 0.170,  0.1790
              7,8, 0.0085,0.072,  0.0745
              8,9, 0.0119,0.1008, 0.1045];
    else
        tr = [1,4, 0,1,0; 2,7, 0,1,0; 3,9, 0,1,0];
        ln = [4,5, 0,1,0; 4,6, 0,1,0; 5,7, 0,1,0; 6,9, 0,1,0; 7,8, 0,1,0; 8,9, 0,1,0];
    end
    for k = 1:size(tr,1)
        net.add_branch("pi_transformer", tr(k,1:2), "R",tr(k,3), "X",tr(k,4), "C",tr(k,5));
    end
    for k = 1:size(ln,1)
        net.add_branch("pi", ln(k,1:2), "R",ln(k,3), "X",ln(k,4), "C",ln(k,5));
    end

% Componentクラスの定義
    net.a_Bus{1}.add_component("gen-park"  );
    net.a_Bus{2}.add_component("gen-1axis" );
    net.a_Bus{3}.add_component("gen-park"  );
    net.a_Bus{5}.add_component("load-power");
    net.a_Bus{6}.add_component("load-power");
    net.a_Bus{8}.add_component("load-power");

% 母線ごとの潮流設定
    net.a_Bus{1}.tab_parameter.powerflow{:,["V","Varg"]} = [1.05, 0.00];
    net.a_Bus{2}.tab_parameter.powerflow{:,["V","Varg"]} = [1.00,  nan];
    net.a_Bus{3}.tab_parameter.powerflow{:,["V","Varg"]} = [1.02,  nan];

% 機器ごとの潮流設定
    net.a_Bus{1}.a_Component{1}.tab_parameter.powerflow{:,["P","Q"]} = [ nan,  nan];
    net.a_Bus{2}.a_Component{1}.tab_parameter.powerflow{:,["P","Q"]} = [ 1.0,  nan];
    net.a_Bus{3}.a_Component{1}.tab_parameter.powerflow{:,["P","Q"]} = [ 1.3,  nan];
    net.a_Bus{5}.a_Component{1}.tab_parameter.powerflow{:,["P","Q"]} = [-1.0, -0.1];
    net.a_Bus{6}.a_Component{1}.tab_parameter.powerflow{:,["P","Q"]} = [-0.8, -0.2];
    net.a_Bus{8}.a_Component{1}.tab_parameter.powerflow{:,["P","Q"]} = [-1.2, -0.4];

% バッチ実行用のソルバー設定 (進捗ダイアログを出さない)
    net.solver_ODE.Progress = "none";
end
