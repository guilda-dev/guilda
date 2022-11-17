classdef network_sample3bus < power_network
% モデル ：Tutorial【簡単なモデルを用いた一連の解析実行例】ページで作成した3busモデル
%親クラス：power_networkクラス
%実行方法：net =network_sample3bus
%　引数　：なし
%　出力　：power_networkクラスのインスタンス

    methods
        function obj = network_sample3bus()
        
        %ブランチ(branch)の定義
            
            %母線1と母線2を繋ぐ送電線の定義
            branch12 = branch_pi(1,2,[0.010,0.085],0);
            obj.add_branch(branch12);
            %母線2と母線3を繋ぐ送電線の定義
            branch23 = branch_pi(2,3,[0.017,0.092],0);
            obj.add_branch(branch23);
        
        
        
        %母線(bus)の定義
            shunt = [0,0];
            %母線1の定義
            bus_1 = bus_slack(2,0,shunt);
            obj.add_bus(bus_1);
            %母線2の定義
            bus_2 = bus_PV(0.5,2,shunt);
            obj.add_bus(bus_2);
            %母線3の定義
            bus_3 = bus_PQ(-3,0,shunt);
            obj.add_bus(bus_3);
        
            
        %機器(component)の定義
            
            %系統周波数の定義
            omega0 = 60*2*pi;
            
            %母線1に同期発電機の1軸モデルを付加
            Xd = 1.569; Xd_prime = 0.963; Xq = 0.963; T = 5.14; M = 100; D = 10;
            mac_data = table(Xd,Xd_prime,Xq,T,M,D);
            component1 = generator_1axis( omega0, mac_data);
            obj.a_bus{1}.set_component(component1);
            
            %母線2にも同期発電機の1軸モデルを付加
            Xd = 1.220; Xd_prime = 0.667; Xq = 0.667; T = 8.97; M = 12; D = 10;
            mac_data = table(Xd,Xd_prime,Xq,T,M,D);
            comp2 = generator_1axis( omega0, mac_data);
            obj.a_bus{2}.set_component(comp2);
            
            %母線3には定インピーダンスモデルを付加
            comp3 = load_impedance();
            obj.a_bus{3}.set_component(comp3);
        
        
        %潮流計算の実行
        obj.initialize
        end
    end
end