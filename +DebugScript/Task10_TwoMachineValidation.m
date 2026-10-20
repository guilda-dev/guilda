function result = Task10_TwoMachineValidation()
% 2機モデルの最小検証:
% 1) 系統作成 2) 潮流計算 3) 時間応答 4) 線形化
% 5) 制御器追加後に2)~4)を再実行

    net = build_two_machine_network();
    result.base_case = run_case(net);

    net_ctrl = build_two_machine_network();
    avr = controller.AVR_DC1();
    net_ctrl.a_Bus{1}.a_Component{1}.add_local_controller(avr);
    result.controller_case = run_case(net_ctrl);
end

function summary = run_case(net)
    [flag, tab_pf] = net.initialize();
    assert(flag, "Power flow did not converge.");

    time = table([0, 10], "steady state", 0, [0 0], ...
        'RowNames', {'Time Stage1'}, ...
        'VariableNames', {'Time','State','Bus','Dis connect(Bus / Component No.)'});

    [sim_t, sim_y] = net.simulate(time);
    sys = net.get_sys();

    summary = struct( ...
        'powerflow_converged', flag, ...
        'bus_count', size(tab_pf, 1), ...
        'sim_state_count', size(sim_y, 1), ...
        'sim_sample_count', numel(sim_t), ...
        'linear_state_count', size(sys.A, 1), ...
        'linear_input_count', size(sys.B, 2), ...
        'linear_output_count', size(sys.C, 1));
end

function net = build_two_machine_network()
    net = PowerNetwork("TwoMachineValidation");

    net.add_bus("Varg", 0, "V", 1.02);
    net.add_bus("Varg", 0, "V", 1.01);
    net.add_bus("Varg", 0, "V", 1.00);

    net.add_branch("pi", [1,3], "R", 0.010, "X", 0.080, "C", 0);
    net.add_branch("pi", [2,3], "R", 0.015, "X", 0.090, "C", 0);

    para1 = table(120, 10, 1.80, 1.70, 0.30, 6.00, ...
        'VariableNames', {'M','D','Xd','Xq','Xd_p','Td_p'});
    para2 = table(80, 8, 1.60, 1.55, 0.28, 5.00, ...
        'VariableNames', {'M','D','Xd','Xq','Xd_p','Td_p'});

    net.a_Bus{1}.add_component("gen-1axis", "P", 0.70, "parameter", para1);
    net.a_Bus{2}.add_component("gen-1axis", "P", 0.60, "parameter", para2);
    net.a_Bus{3}.add_component("load-power", "P", -1.30, "Q", -0.20);
end
