% 2-1 潮流計算 

% netを作成
DebugScript.Task1_NetBuild;


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

% 潮流計算
net.calculate_powerflow;

