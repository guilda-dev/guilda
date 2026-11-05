function [Cyx,Dyv,Dyi,Dyu] = Jacobi_Y(t,x,V,I,u,param,omega0)
    % Return the Jacobians of the AVR_DC1 output.
    % The derivatives of the output `y` of fcn_y are taken with respect to
    % the state, the voltage, the current and the input.
    %
    % See also controller.avr.AVR_DC1.fcn_y, controller.avr.AVR_DC1.Jacobi_dx
    arguments (Input)
        t      double        % [s] Time (unused).
        x      double        % [pu] State `[Vtr; Vap; Vfld; Vst]`: transducer output, amplifier output, field voltage and stabilizer feedback.
        V      double        % [pu] Terminal voltage of the generator as `[real; imag]`.
        I      double        % [pu] Terminal current of the generator as `[real; imag]` (unused).
        u      double        % [pu] Input `[Vref; Vpss]`: voltage reference and PSS output.
        param  double        % Parameter vector in the order of `sv_para`.
        omega0 (1,1) double  % [Hz] Nominal frequency (unused).
    end
    arguments (Output)
        Cyx  % Derivative of `y` with respect to `x`.
        Dyv  % Derivative of `y` with respect to `V` (`[real; imag]`).
        Dyi  % Derivative of `y` with respect to `I` (`[real; imag]`).
        Dyu  % Derivative of `y` with respect to `u`.
    end
    Cyx = zeros(1, 4);    
    
    Cyx(1,3) = 1; 

    Dyv = zeros(1,2);

    Dyi = zeros(1,2);

    nu = numel(u);
    Dyu = zeros(1,nu);
end