classdef network_IEEE68bus < power_network
% モデル  ：IEEE68母線モデル
%・母線1~16が発電機母線として"generator_1axis"が付加
%・母線[17,18,20~29,33,36,39~42,44~53,55,56,59~61,64,67,68]母線は負荷母線として"load_impedance"が付加
%・母線[19,22,30~32,34,35,37,38,43,54,57,58,62,63,65,66]はnon-unit母線として"component_empty"が付加
%親クラス：power_networkクラス
%実行方法：net = network_IEEE68bus();
%　引数　：なし
%　出力　：`power_network`クラスの変数
    properties
    end

    methods
        function obj = network_IEEE68bus()
        omega0 = 60*2*pi;
        bus = readtable('parameters/IEEE68bus/bus.csv');
        branch = readtable('parameters/IEEE68bus/branch.csv');
        machinery = readtable('parameters/IEEE68bus/machinery.csv');
        excitation = readtable('parameters/IEEE68bus/excitation.csv');
        pss_data = readtable('parameters/IEEE68bus/pss.csv');
        
        for i = 1:size(bus, 1)
            shunt = bus{i, {'G_shunt', 'B_shunt'}};
            switch bus{i, 'type'}
                case 1
                    V_abs = bus{i, 'V_abs'};
                    V_angle = bus{i, 'V_angle'};
                    obj.add_bus(bus_slack(V_abs, V_angle, shunt));
                    obj.set_generator(i, machinery, excitation, pss_data, omega0);
                    
                case 2
                    V_abs = bus{i, 'V_abs'};
                    P = bus{i, 'P_gen'};
                    obj.add_bus(bus_PV(P, V_abs, shunt));
                    obj.set_generator(i, machinery, excitation, pss_data, omega0);
                    
                case 3
                    P = bus{i, 'P_load'};
                    Q = bus{i, 'Q_load'};
                    obj.add_bus(bus_PQ(-P, -Q, shunt));
                    if P~=0 || Q~=0
                        load = load_impedance();
                        obj.a_bus{end}.set_component(load);
                    end
                    
            end
        end
        
        for i = 1:size(branch, 1)
            if branch{i, 'tap'} == 0
                br = branch_pi(branch{i, 'bus_from'}, branch{i, 'bus_to'},...
                    branch{i, {'x_real', 'x_imag'}}, branch{i, 'y'});
            else
                br = branch_pi_transformer(branch{i, 'bus_from'}, branch{i, 'bus_to'},...
                    branch{i, {'x_real', 'x_imag'}}, branch{i, 'y'},...
                    branch{i, 'tap'}, branch{i, 'phase'});
            end
            obj.add_branch(br);
        end
        
        obj.initialize();
        
        end
        
        function set_generator(obj, i, machinery, excitation, pss_data, omega0)
            idx = machinery{:, 'No_bus'} == i;
            if sum(idx) ~= 0
                g = generator_1axis(omega0, machinery(idx, :));
                ex = excitation(excitation{:, 'No_bus'}==i, :);
                g.set_avr(avr_sadamoto2019(ex));
                p = pss_data(pss_data{:, 'No_bus'}==i, :);
                g.set_pss(pss(p));
            end
            obj.a_bus{end}.set_component(g)
        end
    end
end