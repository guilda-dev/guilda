function net = network_IEEE68bus()
omega0 = 60*2*pi;
net = power_network();

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
            b = bus_slack(V_abs, V_angle, shunt);
            b.set_component(get_generator(i, machinery, excitation, pss_data, omega0));
            
        case 2
            V_abs = bus{i, 'V_abs'};
            P = bus{i, 'P_gen'};
            b = bus_PV(P, V_abs, shunt);
            b.set_component(get_generator(i, machinery, excitation, pss_data, omega0));
            
        case 3
            P = bus{i, 'P_load'};
            Q = bus{i, 'Q_load'};
            b = bus_PQ(-P, -Q, shunt);
            if P~=0 || Q~=0
                load = load_impedance();
                b.set_component(load);
            end
            
    end
    net.add_bus(b);
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
    net.add_branch(br);
end

net.initialize();

end

function g = get_generator(i, machinery, excitation, pss_data, omega0)
idx = machinery{:, 'No_bus'} == i;
if sum(idx) ~= 0
    g = generator_1axis(omega0, machinery(idx, :));
    ex = excitation(excitation{:, 'No_bus'}==i, :);
    g.set_avr(avr_sadamoto2019(ex));
    p = pss_data(pss_data{:, 'No_bus'}==i, :);
    g.set_pss(pss(p));
end
end