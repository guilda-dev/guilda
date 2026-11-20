function Vpss = fcn_y(t, x, V, u, param, omega0)
    % Return the output of the PSS1 controller.
    %
    % See also controller.pss.PSS1.fcn_dx, controller.pss.PSS1.Jacobi_Y
    % 一番最初についてるゲイン
    arguments (Input)
        t      double        % [s] Time (unused).
        x      double        % [pu] State `[xiWS; xi1; xi2]` of the washout filter and the two lead-lag blocks.
        V      double        % [pu] Terminal voltage as `[real; imag]` (unused).
        u      double        % [pu] Frequency deviation `omega` of the generator.
        param  double        % Parameter vector in the order of `sv_para`.
        omega0 (1,1) double  % [Hz] Nominal frequency (unused).
    end
    arguments (Output)
        Vpss  % [pu] Stabilizing signal `Vpss` to the AVR, limited to `[Vpss_min, Vpss_max]`.
    end
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
    
    % 位相進み補償器 (5.35b)。tn = td = 0 のブロックは恒等、tn = 0 のブロックは出力が状態 (1 次遅れ)
    if tn1 == 0 && td1 == 0
        tn1 = 1; td1 = 1;
    end
    if tn2 == 0 && td2 == 0
        tn2 = 1; td2 = 1;
    end
    if tn1 == 0
        v1 = xi1;
    else
        v1 = tn1*(kpss*omega - xiWS - xi1)/td1;
    end
    if tn2 == 0
        vpl = xi2;
    else
        vpl = tn2*(v1 - xi2)/td2;
    end

    Vpss = max(min(vpl, Vpss_max), Vpss_min);
end