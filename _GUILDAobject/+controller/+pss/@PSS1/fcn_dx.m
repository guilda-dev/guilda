function dx = fcn_dx(t, x, V, I, u, param, omega0) %#ok   
    % Return the right-hand side of the PSS1 state equation.
    % The state equation is `M*dx/dt = f(t, x, V, I, u)`, where `M` is given by fcn_Mass.
    %
    % Inputs:
    % - `t` [s] Time (unused).
    % - `x` [pu] State `[xiWS; xi1; xi2]` of the washout filter and the two lead-lag blocks.
    % - `V` [pu] Terminal voltage as `[real; imag]` (unused).
    % - `I` [pu] Terminal current as `[real; imag]` (unused).
    % - `u` [pu] Frequency deviation `omega` of the generator.
    % - `param` Parameter vector in the order of `sv_para`.
    % - `omega0` [Hz] Nominal frequency (unused).
    %
    % Outputs:
    % - `dx` Right-hand side `f`, one row per state.
    %
    % See also controller.pss.PSS1.fcn_Mass, controller.pss.PSS1.fcn_y, controller.pss.PSS1.Jacobi_dx
        
    % 一番最初についてるゲイン
    kpss = param(1);     
    % 位相進み補償器
    tn1 = param(3);
    td1 = param(4);
    tn2 = param(5);
    td2 = param(6);

    % 周波数
    omega = u;

    % 状態変数
    xiWS = x(1);
    xi1  = x(2);
    xi2  = x(3);
    
    % ウォッシュアウトフィルタ    
    vWS = kpss*omega - xiWS;
    % 位相進み補償器    
    v1  = tn1*(vWS-xi1)/td1;    

    dx = [-xiWS + kpss*omega; -xi1 + (1-td1/tn1) * vWS; -xi2 + (1-td2/tn2) * v1];
    
end