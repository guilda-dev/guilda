function [Axx,Bxv,Bxi,Bxu] = Jacobi_dx(t,x,V,I,u,param,omega0)
    % Return the Jacobians of the AVR_ST1 state equation.
    % The derivatives of the right-hand side `f` of fcn_dx are taken with respect to
    % the state, the voltage, the current and the input.
    %
    % See also controller.avr.AVR_ST1.fcn_dx, controller.avr.AVR_ST1.Jacobi_Y
    arguments (Input)
        t      double        % [s] Time (unused).
        x      double        % [pu] State `[Vtr; Vap; Vst]`: transducer output, amplifier output and stabilizer feedback.
        V      double        % [pu] Terminal voltage of the generator as `[real; imag]`.
        I      double        % [pu] Terminal current of the generator as `[real; imag]` (unused).
        u      double        % [pu] Input `[Vref; Vpss]`: voltage reference and PSS output.
        param  double        % Parameter vector in the order of `sv_para`.
        omega0 (1,1) double  % [Hz] Nominal frequency (unused).
    end
    arguments (Output)
        Axx  % Derivative of `f` with respect to `x`.
        Bxv  % Derivative of `f` with respect to `V` (`[real; imag]`).
        Bxi  % Derivative of `f` with respect to `I` (`[real; imag]`).
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
    
    Bxi = zeros(nx,2);
    
    Bxu = [zeros(1,2); kap*ones(1,2); zeros(1,2)];
end