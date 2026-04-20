% 2-1 潮流計算 

% netを作成
DebugScript.Task1_3_LayerStructure;

% 機器ごとの潮流設定を指定
net.a_Bus{1}.a_Component{1}.tab_parameter.para_powerflow{:,["theta","V","P","Q"]} = [   0, 1.00,  nan,  nan]; % slack
net.a_Bus{1}.a_Component{2}.tab_parameter.para_powerflow{:,["theta","V","P","Q"]} = [ nan, 1.02,  1.0,  nan]; % PV
net.a_Bus{2}.a_Component{1}.tab_parameter.para_powerflow{:,["theta","V","P","Q"]} = [ nan,  nan, -1.3, -0.5]; % PQ
net.a_Bus{3}.a_Component{1}.tab_parameter.para_powerflow{:,["theta","V","P","Q"]} = [ nan, 1.05, 1.02,  nan]; % PV
net.a_Bus{3}.a_Component{2}.tab_parameter.para_powerflow{:,["theta","V","P","Q"]} = [ nan,  nan, -1.0, -0.2]; % PQ
net.a_Bus{3}.a_Component{3}.tab_parameter.para_powerflow{:,["theta","V","P","Q"]} = [ nan,  nan,  0.7,  0.2]; % PQ

% 潮流計算
net.calculate_power_flow


% ネットワーククラスの定義
    net = PowerNetwork("TestSystem");

% Busクラスの定
    net.add_bus("V",1.00,"Varg",0.00);
    net.add_bus("V",1.02);
    net.add_bus("V",1.05);
    net.add_bus();
    net.add_bus();
    net.add_bus();
    net.add_bus();
    net.add_bus();
    net.add_bus();

% Branchクラスの定義
    net.add_branch("pi_transfer",[1,4])
    net.add_branch("pi_transfer",[2,7])
    net.add_branch("pi_transfer",[3,9])
    net.add_branch("pi",[4,5])
    net.add_branch("pi",[4,6])
    net.add_branch("pi",[5,7])
    net.add_branch("pi",[6,9])
    net.add_branch("pi",[7,8])
    net.add_branch("pi",[8,9])

% Componentクラスの定義
    net.a_Bus{1}.add_component("gen-park" )
    net.a_Bus{2}.add_component("gen-1axis", "P", 1.5)
    net.a_Bus{3}.add_component("gen-park" , "P", 1.0)
    net.a_Bus{5}.add_component("load-power","P",-0.7, "Q",-0.2)
    net.a_Bus{6}.add_component("load-power","P",-0.5, "Q",-0.1)
    net.a_Bus{8}.add_component("load-power","P",-1.0, "Q",-0.2)

% 潮流計算
    net.calculate_power_flow