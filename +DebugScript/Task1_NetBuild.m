
% ネットワーククラスの定義
    net = PowerNetwork("TestSystem");

% Busクラスの定
    net.add_bus();
    net.add_bus();
    net.add_bus();
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
    net.a_Bus{1}.add_component("gen-park"      )
    net.a_Bus{2}.add_component("gen-1axis"     )
    net.a_Bus{3}.add_component("gen-park"      )
    net.a_Bus{4}.add_component("gen-classical" )
    net.a_Bus{5}.add_component("gen-park"      )
    
    