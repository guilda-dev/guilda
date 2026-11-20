function dx = fcn_dx(t, x, V, u, param, omega0)
    % Return the right-hand side of the AVR_ST1 state equation.
    % The state equation is `M*dx/dt = f(t, x, V, u)`, where `M` is given by fcn_Mass.
    %
    % See also controller.avr.AVR_ST1.fcn_Mass, controller.avr.AVR_ST1.fcn_y, controller.avr.AVR_ST1.Jacobi_dx
    arguments (Input)
        t      double        % [s] Time (unused).
        x      double        % [pu] State `[Vtr; Vap; Vst]`: transducer output, amplifier output and stabilizer feedback.
        V      double        % [pu] Terminal voltage of the generator as `[real; imag]`.
        u      double        % [pu] Input `[Vref; Vpss; Ifield]`: voltage reference, PSS output and field current.
        param  double        % Parameter vector in the order of `sv_para`.
        omega0 (1,1) double  % [Hz] Nominal frequency (unused).
    end
    arguments (Output)
        dx  % Right-hand side `f`, one row per state.
    end
                
    % リファレンス値
    Vref = u(1);    
    
    Vap_max = param(2);
    Vap_min = param(3);
    kap     = param(4);

    Vtr  = x(1);
    Vap  = x(2);    
    Vst  = x(3);

    % 入力
    Vabs = abs([1,1j]*V);        
    Vpss = u(2);
    % 計測用変圧器
    dx1 = -Vtr + Vabs;
    % コンパレータ
    Vcom = Vref + Vpss - Vtr - Vst;    
    % 増幅器    
    dx2 = -Vap + kap*Vcom;
    if param(8)
        if param(5) == 0
            % Static amplifier (tap = 0): Vap is kap*Vcom clipped to the limits
            dx2 = -Vap + max(min(kap*Vcom, Vap_max), Vap_min);
        elseif (Vap >= Vap_max && dx2 >= 0) || (Vap <= Vap_min && dx2 <= 0)
            % Non-windup limit: hold Vap while it is at a limit and driven further out
            dx2 = 0;
        end
    end
    
    % 安定化回路
    % dx3 = -Vst + kst * Vap;    
    dx3 = -Vst;    

    dx = [dx1;dx2;dx3];
    
end