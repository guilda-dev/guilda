% 1-3 階層構造の形成 ( https://www.notion.so/dev-GUILDA-ver-3-12f6b8dd2f7980ef9a17f3dbebd7f30f?source=copy_link )

net = PowerNetwork;

shunt = [0, 0];  % 母線のシャント値

bus1 = Bus(shunt);
bus2 = Bus(shunt);
bus3 = Bus(shunt);


cij = 0;    % 対地静電容量
branch1 = branch.pi( [0, 1/2], cij);
branch2 = branch.pi( [0, 1/4], cij);
branch3 = branch.pi( [0, 1/3], cij);


net.add_bus(bus1)
net.add_bus(bus2)
net.add_bus(bus3)

% add_branchの際に際に接続母線を指定
net.add_branch(branch1, 1, 2)
net.add_branch(branch2, 1, 3)
net.add_branch(branch3, 2, 3)

% componentのセット
comp1 = component.generator.one_axis();
comp2 = component.generator.one_axis();
comp3 = component.generator.one_axis();

net.Buses{1}.add_component(comp1)
net.Buses{2}.add_component(comp2)
net.Buses{3}.add_component(comp3)

net.Buses{1}.Components{1}.parameter.powerflow{:,["theta","V","P","Q"]} = [   0, 1.00,  nan,  nan]; % slack
net.Buses{2}.Components{1}.parameter.powerflow{:,["theta","V","P","Q"]} = [ nan, 1.02,  0.3,  nan]; % PV
net.Buses{3}.Components{1}.parameter.powerflow{:,["theta","V","P","Q"]} = [ nan, 1.05,  0.2,  nan]; % PV

net.initialize
sys = net.get_sys("SortVariables","VariableNames","DescriptorForm",true,"ConvertODEs",false);

% net.Buses{1}.Components{1}.get_sys()