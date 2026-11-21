function [Axx,Bxv,Bxu] = Jacobi_dx(t,x,V,u,param,omega0)
    % Return the Jacobians of the AVR_ST1 state equation.
    % The derivatives of the right-hand side `f` of fcn_dx are taken with respect to
    % the state, the voltage, the current and the input.
    %
    % See also controller.avr.AVR_ST1.fcn_dx, controller.avr.AVR_ST1.Jacobi_Y
    arguments (Input)
        t      double        % [s] Time (unused).
        x      double        % [pu] State `[Vtr; Vap; Vst]`: transducer output, amplifier output and stabilizer feedback.
        V      double        % [pu] Terminal voltage of the generator as `[real; imag]`.
        u      double        % [pu] Input `[Vref; Vpss; Ifield]`: voltage reference, PSS output and field current.
        param  double        % Parameter vector in the order of `sv_para`.
        omega0 (1,1) double  % [Hz] Nominal frequency (unused).
    end
    arguments (Output)
        Axx  % Derivative of `f` with respect to `x`.
        Bxv  % Derivative of `f` with respect to `V` (`[real; imag]`).
        Bxu  % Derivative of `f` with respect to `u`.
    end
    kap = param(4);    
    nx  = numel(x);

    Axx = [  -1,   0,    0;
           -kap,  -1, -kap;
              0,   0,   -1];

    Vre = V(1);
    Vim = V(2);
    Vsq = abs([1,1j]*V);

    Bxv = [[Vre/Vsq, Vim/Vsq]; zeros(2,2)];
    
    
    Bxu = [zeros(1,3); kap, kap, 0; zeros(1,3)];

    % The limits change the Vap row (the same conditions as fcn_dx)
    Vap = x(2);
    if param(8)
        if param(5) == 0
            % Static amplifier: only -Vap remains while kap*Vcom is outside the limits
            Vap_set = kap*(u(1) + u(2) - x(1) - x(3));
            if Vap_set > param(2) || Vap_set < param(3)
                Axx(2,:) = [0, -1, 0];
                Bxu(2,:) = 0;
            end
        else
            % Non-windup: the row is zero while the limit holds Vap
            dx2 = -Vap + kap*(u(1) + u(2) - x(1) - x(3));
            if (Vap >= param(2) && dx2 >= 0) || (Vap <= param(3) && dx2 <= 0)
                Axx(2,:) = 0;
                Bxu(2,:) = 0;
            end
        end
    end
end