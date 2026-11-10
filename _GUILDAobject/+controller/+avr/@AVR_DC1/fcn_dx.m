function dx = fcn_dx(t, x, V, u, param, omega0)
    % Return the right-hand side of the AVR_DC1 state equation.
    % The state equation is `M*dx/dt = f(t, x, V, u)`, where `M` is given by fcn_Mass.
    %
    % See also controller.avr.AVR_DC1.fcn_Mass, controller.avr.AVR_DC1.fcn_y, controller.avr.AVR_DC1.Jacobi_dx
    arguments (Input)
        t      double        % [s] Time (unused).
        x      double        % [pu] State `[Vtr; Vap; Vfld; Vst]`: transducer output, amplifier output, field voltage and stabilizer feedback.
        V      double        % [pu] Terminal voltage of the generator as `[real; imag]`.
        u      double        % [pu] Input `[Vref; Vpss]`: voltage reference and PSS output.
        param  double        % Parameter vector in the order of `sv_para`.
        omega0 (1,1) double  % [Hz] Nominal frequency (unused).
    end
    arguments (Output)
        dx  % Right-hand side `f`, one row per state.
    end
                
    % リファレンス値
    Vref = u(1);
    % 増幅器
    Vap_max = param(2);
    Vap_min = param(3);
    kap     = param(4);    
    % 励磁器
    aex1 = param(6);
    aex2 = param(7);    
    bex  = param(9);    
    Vfld_max = param(12);
    Vfld_min = param(13);

    Vtr  = x(1);
    Vap  = x(2);
    Vfld = x(3);
    Vst  = x(4);

    % 入力
    Vabs = abs([1,1j]*V);        
    Vpss = u(2);
    % 計測用変圧器
    dx1 = -Vtr + Vabs;
    % コンパレータ
    Vcom = Vref + Vpss - Vtr - Vst;    
    % 増幅器

    dx2 = 0;
    if Vap*Vcom<=0 || (Vap_min < Vap && Vap_max > Vap)
        dx2 = -Vap + kap*Vcom;
    end 

    % 励磁器
    dx3 = -( aex1 + aex2 * exp(bex*Vfld) ) * Vfld + Vap;
    % 界磁電圧の制限 (non-windup): 制限に達し、さらに外へ向かう間は止める
    if (Vfld >= Vfld_max && dx3 >= 0) || (Vfld <= Vfld_min && dx3 <= 0)
        dx3 = 0;
    end
    % 安定化回路
    dx4 = -Vst;    

    dx = [dx1;dx2;dx3;dx4];
    
end