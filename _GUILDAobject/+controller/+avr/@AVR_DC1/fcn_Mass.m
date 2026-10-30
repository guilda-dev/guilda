function Mass = fcn_Mass(t, x, V, I, u, param, omega0) %#ok      
    % Return the mass matrix of the AVR_DC1 state equation.
    % The state equation is `M*dx/dt = f(t, x, V, I, u)`. The diagonal of `M` holds the time constants [s];
    % a zero time constant makes the corresponding equation algebraic.
    %
    % Inputs:
    % - `t` [s] Time (unused).
    % - `x` [pu] State `[Vtr; Vap; Vfld; Vst]`: transducer output, amplifier output, field voltage and stabilizer feedback.
    % - `V` [pu] Terminal voltage of the generator as `[real; imag]`.
    % - `I` [pu] Terminal current of the generator as `[real; imag]` (unused).
    % - `u` [pu] Input `[Vref; Vpss]`: voltage reference and PSS output.
    % - `param` Parameter vector in the order of `sv_para`.
    % - `omega0` [Hz] Nominal frequency (unused).
    %
    % See also controller.avr.AVR_DC1.fcn_dx
    arguments (Output)
        Mass % Mass matrix `M`, one row and column per state.
    end
        
    ttr = param(1);    
    tap = param(5);
    tex = param(8);
    kst = param(10);
    tst = param(11);

    Mass = [ttr,   0,    0,   0;
              0, tap,    0,   0;
              0,   0,  tex,   0;
              0,   0, -kst, tst];
    
end