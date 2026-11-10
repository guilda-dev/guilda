function M = fcn_Mass(obj,t,x,V,u,param,omega0)
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
        u      double        % Input vector in the order of `sv_u`.
        param  double        % Dynamic parameters in the order of `sv_para`.
        omega0 (1,1) double  % [Hz] Network frequency (`get_Hz`).
    end
    arguments (Output)
        M % Mass matrix of the state equation.
    end
    
    M    = param(1);
    Tdp  = param(7);
    Tqp  = param(8);
    
    M = diag( [1,M,Tdp,Tqp] );
end