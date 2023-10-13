%% Definition of the power network
net = network_IEEE9bus();

%% Simulation of power system
time = [0, 1, 2, 60];
u_idx = 8;
u = [   0.01,         0.01,         0.01,           0.01;...
        0,            0,            0,              0];
% option = struct();
% option.x0_sys = net.x_equilibrium;
% option.x0_sys(1) = option.x0_sys(1) + pi/6;
% option.x0_sys(3) = option.x0_sys(3) + 0.1;
% option.fault = {{[0 0.05], 1}};
out1 = net.simulate(time, u, u_idx);
sampling_time = out1.t;

%% Plot of frequency deviation of the three machines
figure;
omega1 = out1.X{1}(:,2);
plot(sampling_time, omega1, 'LineWidth', 2)
hold on

omega2 = out1.X{2}(:,2);
plot(sampling_time, omega2, 'LineWidth', 2)
hold on

omega3 = out1.X{3}(:,2);
plot(sampling_time, omega3, 'LineWidth', 2)
hold on


%% Replace synchronous generator by GFMI
load_vsm_params;
comp = gfmi_vsm(vsc_params,controller_params,ref_model_params);
net.a_bus{2}.set_component(comp);

%% Simulation of power system
time = [0, 1, 2, 60];
u_idx = 8;
u = [   0.01,         0.01,         0.01,           0.01;...
        0,            0,            0,              0];
% option = struct();
% option.x0_sys = net.x_equilibrium;
% option.x0_sys(1) = option.x0_sys(1) + pi/6;
% option.x0_sys(3) = option.x0_sys(3) + 0.1;
% option.fault = {{[0 0.05], 1}};
out1 = net.simulate(time, u, u_idx);
sampling_time = out1.t;

%% Plot of frequency deviation of the three machines
omega1 = out1.X{1}(:,2);
plot(sampling_time, omega1, '--','LineWidth', 2)
hold on

omega2 = out1.X{2}(:,13) - 1;
plot(sampling_time, omega2, '--','LineWidth', 2)
hold on

omega3 = out1.X{3}(:,2);
plot(sampling_time, omega3, '--','LineWidth', 2)
hold on

title('1% Load Increase at Bus 8')
legend('Scenario 1: SM1', 'Scenario 1: SM2', 'Scenario 1: SM3',...
       'Scenario 2: SM1', 'Scenario 2: VSG-GFMI', 'Scenario 2: SM3')
xlabel('Time (s)', 'FontSize', 15)
ylabel('Frequency (pu)', 'FontSize', 15)
grid on
