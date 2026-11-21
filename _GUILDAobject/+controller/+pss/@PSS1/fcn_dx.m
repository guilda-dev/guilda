function dx = fcn_dx(t, x, V, u, param, omega0)
    % Return the right-hand side of the PSS1 state equation.
    % The state equation is `M*dx/dt = f(t, x, V, u)`, where `M` is given by fcn_Mass.
    %
    % See also controller.pss.PSS1.fcn_Mass, controller.pss.PSS1.fcn_y, controller.pss.PSS1.Jacobi_dx
    arguments (Input)
        t      double        % [s] Time (unused).
        x      double        % [pu] State `[xiWS; xi1; xi2]` of the washout filter and the two lead-lag blocks.
        V      double        % [pu] Terminal voltage as `[real; imag]` (unused).
        u      double        % [pu] Frequency deviation `omega` of the generator.
        param  double        % Parameter vector in the order of `sv_para`.
        omega0 (1,1) double  % [Hz] Nominal frequency (unused).
    end
    arguments (Output)
        dx  % Right-hand side `f`, one row per state.
    end
        
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
    % 位相進み補償器 (5.35b)。tn = td = 0 のブロックは恒等 (状態は 0 のまま)、
    % tn = 0 のブロックは 1 次遅れ td*dxi = -xi + v, 出力 xi (td = 0, tn ~= 0 は get_equilibrium がエラーにする)
    if tn1 == 0 && td1 == 0
        tn1 = 1; td1 = 1;
    end
    if tn2 == 0 && td2 == 0
        tn2 = 1; td2 = 1;
    end
    if tn1 == 0
        a1 = 1;
        v1 = xi1;
    else
        a1 = 1 - td1/tn1;
        v1 = tn1*(vWS-xi1)/td1;
    end
    if tn2 == 0
        a2 = 1;
    else
        a2 = 1 - td2/tn2;
    end

    dx = [-xiWS + kpss*omega; -xi1 + a1 * vWS; -xi2 + a2 * v1];
    
end