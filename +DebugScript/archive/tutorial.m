%潮流計算を実行
%
% >> 検証コードもきれいにまとめて置いた方が良さそうな気がしたから
% >> +DebugScript/xxxxx.mlx
% >> に機能要件ごとに作成してもらえると助かります！！！🙏

% net = PowerNetwork;
% 
% 
% shunt = [0, 0];
% 
% bus1 = bus.slack(1.1, 0, shunt);
% bus2 = bus.PV(1, 1, shunt);
% bus3 = bus.PV(-1, 1.2, shunt);
% bus4 = bus.PQ(1, 1, shunt);
% 
% branch1 = branch.pi( [0, 1/2], shunt);
% branch2 = branch.pi( [0, 1/4], shunt);
% branch3 = branch.pi( [0, 1/3], shunt);
% branch4 = branch.pi( [0, 1/5], shunt);
% 
% Xd = 1; Xq = 1;M=1;D=1;
% mac = table(Xd, Xq, M, D);
% % component1 = component.generator.classical(mac);
% 
% net.add_bus(bus1)
% net.add_bus(bus2)
% net.add_bus(bus3)
% net.add_bus(bus4)
% 
% net.add_branch(branch1, 1, 2)
% net.add_branch(branch2, 1, 3)
% net.add_branch(branch3, 2, 3)
% net.add_branch(branch4, 1, 4)
% 
% 
% net.initialize
% 
% 
% %mac = table('Xd', 1, 'Xq', 1, 'M', 1, 'D', 1);
% component.generator.classical()
