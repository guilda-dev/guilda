function dx = fcn_dx(t, x, V, I, u, param, omega0) %#ok
    % Return the right-hand side of the AVR_ST1 state equation.
    % The state equation is `M*dx/dt = f(t, x, V, I, u)`, where `M` is given by fcn_Mass.
    %
    % Inputs:
    % - `t` [s] Time (unused).
    % - `x` [pu] State `[Vtr; Vap; Vst]`: transducer output, amplifier output and stabilizer feedback.
    % - `V` [pu] Terminal voltage of the generator as `[real; imag]`.
    % - `I` [pu] Terminal current of the generator as `[real; imag]` (unused).
    % - `u` [pu] Input `[Vref; Vpss]`: voltage reference and PSS output.
    % - `param` Parameter vector in the order of `sv_para`.
    % - `omega0` [Hz] Nominal frequency (unused).
    %
    % See also controller.avr.AVR_ST1.fcn_Mass, controller.avr.AVR_ST1.fcn_y, controller.avr.AVR_ST1.Jacobi_dx
    arguments (Output)
        dx % Right-hand side `f`, one row per state.
    end
                
    % リファレンス値
    Vref = u(1);    
    
    kap  = param(4);    

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
    
    % 安定化回路
    % dx3 = -Vst + kst * Vap;    
    dx3 = -Vst;    

    dx = [dx1;dx2;dx3];
    
end