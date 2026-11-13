function [sct_sol, flag, output, sct_dae, sct_event] = solve_direct(net, s_tag, time, sct_options)
% net.build_simulation_data と net.solver_ODE.solve を続けて呼ぶ (simulate を通さない)
%
%   [sct_sol, flag, output] = DebugScript.helper.solve_direct(net, sc.s_tag, [0,1], ...
%                                 DebugScript.helper.ode_options("Progress", "none"));
%
% simulate と違い、結果 (ResultODE) を作らず、警告 SimulationIncomplete も出さない。
% sct_options の PhaseProbe (区間ごとに ode を受け取る関数) を使うテストのため。
    arguments (Input)
        net                        % 電力系統
        s_tag (1,1) string         % シナリオのタグ
        time  (1,2) double         % [s] 時間 [t0, tend]
        sct_options (1,1) struct   % SolverODE.solve の設定 (DebugScript.helper.ode_options)
    end
    arguments (Output)
        sct_sol    % solve の第 1 出力 (rv_t, rm_variable, rm_I, rv_phase)
        flag       % solve の flag
        output     % solve の output (phases は build_simulation_data の tab_phase)
        sct_dae    % build_simulation_data の第 1 出力
        sct_event  % build_simulation_data の第 2 出力
    end
    [sct_dae, sct_event, rv_x0, tab_phase] = net.build_simulation_data(s_tag, time);
    [sct_sol, flag, output] = net.solver_ODE.solve(sct_dae, sct_event, rv_x0, sct_options);
    output.phases = tab_phase;
end
