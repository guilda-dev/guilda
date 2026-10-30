function Vpss = fcn_y(t, x, V, I, u, param, omega0) %#ok
    % Return the output of the PSS1 controller.
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
    % - `Vpss` [pu] Stabilizing signal `Vpss` to the AVR, limited to `[Vpss_min, Vpss_max]`.
    %
    % See also controller.pss.PSS1.fcn_dx, controller.pss.PSS1.Jacobi_Y
    % 一番最初についてるゲイン
    kpss = param(1);     
    % 位相進み補償器
    tn1 = param(3);
    td1 = param(4);
    tn2 = param(5);
    td2 = param(6);

    Vpss_min = param(7); 
    Vpss_max = param(8);

    % 周波数
    omega = u;

    % 状態変数
    xiWS = x(1);
    xi1  = x(2);
    xi2  = x(3);        
    
    Vpss = max( min(tn2*(tn1*(kpss*omega - xiWS - xi1)/td1 - xi2)/td2 , Vpss_max), Vpss_min); 
end