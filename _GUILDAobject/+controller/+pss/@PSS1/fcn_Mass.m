function Mass = fcn_Mass(t, x, V, I, u, param, omega0) %#ok   
    % Return the mass matrix of the PSS1 state equation.
    % The state equation is `M*dx/dt = f(t, x, V, I, u)`. The diagonal of `M` holds the time constants [s];
    % a zero time constant makes the corresponding equation algebraic.
    %
    % See also controller.pss.PSS1.fcn_dx
    arguments (Input)
        t      double        % [s] Time (unused).
        x      double        % [pu] State `[xiWS; xi1; xi2]` of the washout filter and the two lead-lag blocks.
        V      double        % [pu] Terminal voltage as `[real; imag]` (unused).
        I      double        % [pu] Terminal current as `[real; imag]` (unused).
        u      double        % [pu] Frequency deviation `omega` of the generator.
        param  double        % Parameter vector in the order of `sv_para`.
        omega0 (1,1) double  % [Hz] Nominal frequency (unused).
    end
    arguments (Output)
        Mass  % Mass matrix `M`, one row and column per state.
    end
    
    tWS = param(2);
    % 位相進み補償器    
    td1 = param(4);    
    td2 = param(6);

    Mass = [tWS,   0,   0;
              0, td1,   0;
              0,   0, td2];                   
    
end