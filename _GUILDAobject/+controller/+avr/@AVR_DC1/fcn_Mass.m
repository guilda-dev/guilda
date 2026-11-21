function Mass = fcn_Mass(t, x, V, u, param, omega0)
    % Return the mass matrix of the AVR_DC1 state equation.
    % The state equation is `M*dx/dt = f(t, x, V, u)`. The diagonal of `M` holds the time constants [s];
    % a zero time constant makes the corresponding equation algebraic.
    %
    % See also controller.avr.AVR_DC1.fcn_dx
    arguments (Input)
        t      double        % [s] Time (unused).
        x      double        % [pu] State `[Vtr; Vap; Vfld; Vst]`: transducer output, amplifier output, field voltage and stabilizer feedback.
        V      double        % [pu] Terminal voltage of the generator as `[real; imag]`.
        u      double        % [pu] Input `[Vref; Vpss]`: voltage reference and PSS output.
        param  double        % Parameter vector in the order of `sv_para`.
        omega0 (1,1) double  % [Hz] Nominal frequency (unused).
    end
    arguments (Output)
        Mass  % Mass matrix `M`, one row and column per state.
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