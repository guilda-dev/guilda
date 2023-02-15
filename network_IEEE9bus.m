classdef network_IEEE9bus < power_network
% モデル  ：IEEE9母線モデル
%・母線1~3が発電機母線として"generator_1axis"が付加
%・母線[5,6,8]母線は負荷母線として"load_impedance"が付加
%・母線[4,7,9]はnon-unit母線として"component_empty"が付加
%親クラス：power_networkクラス
%実行方法：net = network_IEEE9bus();
%　引数　：なし
%　出力　：`power_network`クラスの変数
    properties
    end

    methods
        function obj = network_IEEE9bus(gen_model)
        
        if nargin<1
            gen_model = 'generator_1axis';
        end
        netname = 'IEEE9bus';

        omega0 = 60*2*pi;
        bus = readtable(['parameters/',netname,'/bus.csv']);
        branch = readtable(['parameters/',netname,'/branch.csv']);
        machinery = readtable(['parameters/',netname,'/machinery.csv']);
        excitation = readtable(['parameters/',netname,'/excitation.csv']);
        pss_data = readtable(['parameters/',netname,'/pss.csv']);
        
%         mX = mean(machinery{:,{'Xd','Xq'}},2);
%         machinery{:,'Xq'} = mX;
%         machinery{:,'Xd'} = mX;
%         mXp = mean(machinery{:,{'Xd_prime','Xq_prime'}},2);
%         machinery{:,'Xq_prime'} = mXp;
%         machinery{:,'Xd_prime'} = mXp;
        
        for i = 1:size(bus, 1)
            shunt = bus{i, {'G_shunt', 'B_shunt'}};
            switch bus{i, 'type'}
                case 1
                    V_abs = bus{i, 'V_abs'};
                    V_angle = bus{i, 'V_angle'};
                    obj.add_bus(bus_slack(V_abs, V_angle, shunt));
                    obj.set_generator(i, machinery, excitation, pss_data, omega0, gen_model);
                    
                case 2
                    V_abs = bus{i, 'V_abs'};
                    P = bus{i, 'P_gen'};
                    obj.add_bus(bus_PV(P, V_abs, shunt));
                    obj.set_generator(i, machinery, excitation, pss_data, omega0,gen_model);
                    
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
        
        function set_generator(obj, i, machinery, excitation, pss_data, omega0, gen_model)
            generator = str2func(gen_model);
            idx = machinery{:, 'No_bus'} == i;
            if sum(idx) ~= 0
                g = generator(omega0, machinery(idx, :));
                ex = excitation(excitation{:, 'No_bus'}==i, :);
                g.set_avr(avr_sadamoto2019(ex));
                p = pss_data(pss_data{:, 'No_bus'}==i, :);
                g.set_pss(pss(p));
            end
            obj.a_bus{end}.set_component(g)
        end
    end
end