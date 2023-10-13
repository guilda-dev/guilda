classdef IEEE9bus_ < power_network
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
        function obj = IEEE9bus_(gen_model)
        
        if nargin<1
            gen_model = 'component.generator.two_axis';
        end
        netname = 'IEEE9bus_Vitor';

        omega0 = 60*2*pi;
        tbus        = readtable(['+network/+',netname,'/bus.csv']);
        tbranch     = readtable(['+network/+',netname,'/branch.csv']);
        machinery   = readtable(['+network/+',netname,'/machinery.csv']);
        excitation  = readtable(['+network/+',netname,'/excitation.csv']);
        pss_data    = readtable(['+network/+',netname,'/pss.csv']);
        
%         mX = mean(machinery{:,{'Xd','Xq'}},2);
%         machinery{:,'Xq'} = mX;
%         machinery{:,'Xd'} = mX;
%         mXp = mean(machinery{:,{'Xd_prime','Xq_prime'}},2);
%         machinery{:,'Xq_prime'} = mXp;
%         machinery{:,'Xd_prime'} = mXp;
        
        for i = 1:size(tbus, 1)
            shunt = tbus{i, {'G_shunt', 'B_shunt'}};
            switch tbus{i, 'type'}
                case 1
                    V_abs = tbus{i, 'V_abs'};
                    V_angle = tbus{i, 'V_angle'};
                    obj.add_bus(bus.slack(V_abs, V_angle, shunt));
                    obj.set_generator(i, machinery, excitation, pss_data, omega0, gen_model);
                    
                case 2
                    V_abs = tbus{i, 'V_abs'};
                    P = tbus{i, 'P_gen'};
                    obj.add_bus(bus.PV(P, V_abs, shunt));
                    obj.set_generator(i, machinery, excitation, pss_data, omega0,gen_model);
                    
                case 3
                    P = tbus{i, 'P_load'};
                    Q = tbus{i, 'Q_load'};
                    obj.add_bus(bus.PQ(-P, -Q, shunt));
                    if P~=0 || Q~=0
                        load = component.load.impedance();
                        %load = component.load.power();
                        obj.a_bus{end}.set_component(load);
                    end
            end
        end
        
        for i = 1:size(tbranch, 1)
            if tbranch{i, 'tap'} == 0
                br = branch.pi(tbranch{i, 'bus_from'}, tbranch{i, 'bus_to'},...
                    tbranch{i, {'x_real', 'x_imag'}}, tbranch{i, 'y'});
            else
                br = branch.pi_transformer(tbranch{i, 'bus_from'}, tbranch{i, 'bus_to'},...
                    tbranch{i, {'x_real', 'x_imag'}}, tbranch{i, 'y'},...
                    tbranch{i, 'tap'}, tbranch{i, 'phase'});
            end
            obj.add_branch(br);
        end
        
        obj.initialize();
        
        end
        
        function set_generator(obj, i, machinery, excitation, pss_data, omega0, gen_model)
            generator = str2func(gen_model);
            idx = machinery{:, 'No_bus'} == i;
            if sum(idx) ~= 0
                g = generator(machinery(idx, :));
                ex = excitation(excitation{:, 'No_bus'}==i, :);
                g.set_avr(component.generator.avr.sadamoto2019(ex));
                % p = pss_data(pss_data{:, 'No_bus'}==i, :);
                % % g.set_pss(pss(p));
                % g.set_pss(pss_IEEE_PSS1(p));
            end
            obj.a_bus{end}.set_component(g)
        end

    end
end