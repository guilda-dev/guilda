function M = fcn_Mass(obj, t, x, V, I, u, para, omega0) %#ok
% Return the mass matrix of the state equation.
%
% The state equation is `M*dx/dt = fcn_dx(...)`.
%
% See also fcn_dx
    arguments (Input)
        obj
        t      double        % [s] Time.
        x      double        % State vector in the order of `sv_x`.
        V      double        % [pu] Bus voltage as `[real; imag]`.
        I      double        % [pu] Bus current as `[real; imag]`.
        u      double        % Input vector in the order of `sv_u`.
        para   double        % Dynamic parameters in the order of `sv_para`.
        omega0 (1,1) double  % [Hz] Network frequency (`get_Hz`).
    end
    arguments (Output)
        M % Mass matrix of the state equation.
    end
    
    M    = para(1);
    Tdp  = para(9);
    Tdpp = para(10);
    Tqp  = para(11);    
    Tqpp = para(12);

    M = diag( [1,M,Tdp,Tqp,Tqpp,Tdpp] );
end