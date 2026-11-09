function [cv_Vbus,flag,output,cm_Vhistory,rv_step] = solve(obj)
% Integrate the virtual bus dynamics until they settle at the power flow solution (see the
% class help). cm_Vhistory holds the bus voltages at each ODE step (n_bus x n_step),
% rv_step the virtual times.
    arguments (Input)
        obj
    end
    arguments (Output)
        cv_Vbus     (:,1) double  % [pu] Complex bus voltages at the end of the integration.
        flag                      % 1 converged, 0 virtual time limit reached, -2 voltage collapse, angle instability or integration failure.
        output                    % Details: iterations, algorithm, residual, message.
        cm_Vhistory               % [pu] Complex bus voltages at each ODE step (n_bus x n_step).
        rv_step                   % Virtual times of the ODE steps.
    end

    cm_Y = obj.Y;
    tab_PFcondition = obj.PFcondition;
    N   = size(tab_PFcondition,1);
    M   = obj.Mass;
    D   = obj.Damper;
    foh = obj.foh_PQ;
    tol = obj.Tolerance;
    r_tEnd = 1e4;      % safety limit of the virtual time
    
    idx_slack = (tab_PFcondition.Type == "slack");
    idx_PV    = (tab_PFcondition.Type == "PV");
    
    % Initial State: the columns Varg0, V0 when given, the flat start otherwise
    if all(ismember(["Varg0","V0"], tab_PFcondition.Properties.VariableNames))
        Tinit = tab_PFcondition.Varg0;
        Vinit = tab_PFcondition.V0;
    else
        Tinit = zeros(N, 1);
        Vinit = ones(N, 1);
    end
    Tinit(idx_slack) = tab_PFcondition.Varg(idx_slack);
    Vinit(idx_slack | idx_PV) = tab_PFcondition.V(idx_slack | idx_PV); % fixed at the specified values

    if M == 0
        Vc_0  = Vinit .* exp(1j * Tinit);
        S_0   = Vc_0  .* conj(cm_Y * Vc_0);
        dP0   = tab_PFcondition.P - real(S_0);
        dQ0   = tab_PFcondition.Q - imag(S_0);

        Winit = dP0  ./ D;
        Uinit = (dQ0 ./ max(Vinit, 1e-6)) ./ D;
    else
        Winit = zeros(N, 1);
        Uinit = zeros(N, 1);
    end

    Winit(idx_slack) = 0;
    Uinit(idx_slack | idx_PV) = 0;

    Y0 = [Tinit; Winit; Vinit; Uinit];


    % Mass Matrix
    M_theta = ones(N, 1);
    M_omega = M * ones(N, 1); M_omega(idx_slack) = 1; % 固定変数の質量は1
    M_V     = ones(N, 1);
    M_u     = M * ones(N, 1); M_u(idx_slack | idx_PV) = 1;
    MassMat = spdiags([M_theta; M_omega; M_V; M_u], 0, 4*N, 4*N);
    
    % Jacobian Pattern
    S_Y = spones(cm_Y); 
    I_N = speye(N);
    O_N = sparse(N, N);
    J_pattern = [
        O_N, I_N, O_N, O_N;
        S_Y, I_N, S_Y, O_N;
        O_N, O_N, O_N, I_N;
        S_Y, O_N, S_Y, I_N
    ];

    % solve ODE
    ode_func   = @(t, Y) bus_dynamics(t, Y, cm_Y, tab_PFcondition, D, N, foh);
    event_func = @(t, Y) convergence_events(t, Y, cm_Y, tab_PFcondition, N, tol);
    options = odeset('RelTol', max(min(100*tol, 1e-4), 100*eps), 'AbsTol', min(tol, 1e-5), ...
                     'Mass', MassMat, ...
                     'Events', event_func, ...
                     'JPattern', J_pattern);
    s_warn = lastwarn();
    w = warning("off", "MATLAB:ode15s:IntegrationTolNotMet");
    [t_out, Y_out, ~, ~, ie] = ode15s(ode_func, [0, r_tEnd], Y0, options);
    warning(w);
    lastwarn(s_warn);

    % Convergence Test
    r_res = max_mismatch(Y_out(end,:).', cm_Y, tab_PFcondition, N);
    if any(ie == 1)
        flag = 1;
        s_msg = sprintf('✔ The virtual bus dynamics have converged within the tolerance limit (virtual time %.4g).', t_out(end));
    elseif any(ie == 2)
        flag = -2;
        s_msg = '✘ The process was terminated: Voltage collapse detected.';
    elseif any(ie == 3)
        flag = -2;
        s_msg = '✘ The process was terminated: Phase angle instability detected.';
    elseif t_out(end) >= r_tEnd
        flag = 0;
        s_msg = sprintf('✘ The virtual bus dynamics did not converge within the virtual time %g (largest mismatch %.3e).', r_tEnd, r_res);
    else
        flag = -2;
        s_msg = sprintf('✘ The integration of the virtual bus dynamics stopped at the virtual time %.4g (largest mismatch %.3e).', t_out(end), r_res);
    end
    output = struct("iterations", numel(t_out)-1, "algorithm", "dynamic", "residual", r_res, "message", s_msg);

    % step data
    cm_Vhistory = Y_out(:,(1:N)+2*N).' .* exp(1j*Y_out(:,1:N).');
    rv_step     = t_out(:).';

    % Let the final value be the solution
    rv_Vsol = Y_out(end, (1:N)+2*N).';
    rv_Tsol = Y_out(end, (1:N)    ).';
    cv_Vbus = rv_Vsol .* exp(1j*rv_Tsol);
end

% =========================================================
% 母線ダイナミクスを計算するローカル関数
% =========================================================
function dY = bus_dynamics(t, Y, cm_Y, tab, D, N, foh_PQ)
    % 状態ベクトルの展開
    theta = Y(1:N);
    omega = Y(N+1:2*N);
    V     = Y(2*N+1:3*N);
    u     = Y(3*N+1:4*N); % 電圧の変化率 (dV/dt)

    % 複素電圧ベクトルと電流・電力の計算 (ベクトル演算)
    Vc = V .* exp(1j * theta);
    I = cm_Y * Vc;
    S = Vc .* conj(I);
    
    P_net = real(S);
    Q_net = imag(S);

    % 設定値の抽出
    P_spec = tab.P * min(t/foh_PQ, 1);
    Q_spec = tab.Q * min(t/foh_PQ, 1);

    % 不平衡量の計算 (ベクトル)
    delta_P = P_spec - P_net;
    delta_Q = Q_spec - Q_net;

    % 駆動力の計算 (Qは電流次元に変換)
    force_theta = delta_P;
    force_V     = delta_Q ./ max(V, 1e-6); % ゼロ除算防止

    % 運動方程式 (M * accel + D * vel = force) に基づく各変数の微分
    dtheta = omega;
    domega = force_theta - D .* omega;
    
    dV = u;
    du = force_V - D .* u;

    % ---------------------------------------------------------
    % 母線タイプによるダイナミクスのマスク処理 (ここがポイント)
    % ---------------------------------------------------------
    idx_slack = (tab.Type == "slack");
    idx_PV    = (tab.Type == "PV");
    
    % Slack母線: θとVは固定 (変化率を強制的に0にする)
    dtheta(idx_slack) = 0;
    domega(idx_slack) = 0;
    dV(idx_slack)     = 0;
    du(idx_slack)     = 0;
    
    % PV母線: Vは固定 (Vの変化率のみ0にする。θは自由に動く)
    dV(idx_PV) = 0;
    du(idx_PV) = 0;

    % PQ母線: マスクなし (θもVも変動する)

    % 状態微分の列ベクトル化
    dY = [dtheta; domega; dV; du];
end


function r = max_mismatch(Y, cm_Y, tab, N)
% Largest |dP| (non-slack) and |dQ| (PQ) at the state Y
    Vc = Y(2*N+1:3*N) .* exp(1j * Y(1:N));
    S  = Vc .* conj(cm_Y * Vc);
    r  = max([abs(tab.P(tab.Type ~= "slack") - real(S(tab.Type ~= "slack")));
              abs(tab.Q(tab.Type == "PQ") - imag(S(tab.Type == "PQ"))); 0]);
end


% =========================================================
% イベント関数 (収束判定 & 異常停止)
% =========================================================
function [value, isterminal, direction] = convergence_events(~, Y, cm_Y, tab, N, tol)
    theta = Y(1:N); V = Y(2*N+1:3*N);
    Vc = V .* exp(1j * theta);
    S = Vc .* conj(cm_Y * Vc);
    
    delta_P = abs(tab.P - real(S));
    delta_Q = abs(tab.Q - imag(S));

    idx_non_slack = (tab.Type ~= "slack");
    idx_PQ        = (tab.Type == "PQ");

    % ① 収束判定: 有効・無効電力のミスマッチの最大値が閾値以下か
    max_mismatch  = max([delta_P(idx_non_slack); delta_Q(idx_PQ); 0]);
    value(1)      = max_mismatch - tol; 
    isterminal(1) = 1; 
    direction(1)  = 0; % 減少・増加どちらからでも判定

    % ② 電圧崩壊判定: 電圧が極端に低くなった場合 (例: 0.01 pu以下)
    v_min = 1e-2;
    value(2)      = min(V(idx_PQ)) - v_min;
    isterminal(2) = 1;
    direction(2)  = -1; % 電圧が下がって閾値を超えた時のみ

    % ③ 角度が不安定化した場合： 
    rot_max = 5;
    value(3)      = all( theta>-(rot_max*2*pi) & theta<(rot_max*2*pi) );
    isterminal(3) = 1; 
    direction(3)  = 0; % 減少・増加どちらからでも判定
end