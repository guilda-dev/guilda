function [net, comp] = build_3bus(key)
% 指定した種類の機器を1台含む3母線系統を作成する
%
%   [net, comp] = DebugScript.helper.build_3bus("gen-classical")
%
%   B001: gen-park (slack)  --  B002: 発電機 (key が gen-* のとき)  --  B003: 負荷
% key が load-* のときは B002 を gen-park、B003 を key の負荷にする。
% comp は key で追加した機器。全母線に機器があるので odeLinearizer の NonUnit も発生しない。
    arguments
        key (1,1) string
    end
    net = PowerNetwork("Test3Bus");
    net.add_bus("V",1.00);
    net.add_bus("V",1.02);
    net.add_bus();

    net.add_branch("pi",[1,2], "R",0.010, "X",0.085);
    net.add_branch("pi",[2,3], "R",0.017, "X",0.092);

    net.a_Bus{1}.add_component("gen-park");
    if startsWith(key,"gen")
        comp = net.a_Bus{2}.add_component(key, "P", 0.5, "Q", nan);
        net.a_Bus{3}.add_component("load-power", "P",-1.0, "Q",-0.2);
    else
        net.a_Bus{2}.add_component("gen-park", "P", 0.5, "Q", nan);
        comp = net.a_Bus{3}.add_component(key, "P",-1.0, "Q",-0.2);
    end
    net.solver_ODE.Progress = "none";
end
