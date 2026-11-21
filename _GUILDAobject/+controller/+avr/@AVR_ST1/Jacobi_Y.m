function [Cyx,Dyv,Dyu] = Jacobi_Y(t,x,V,u,param,omega0)
    % Return the Jacobians of the AVR_ST1 output.
    % The derivatives of the output `y` of fcn_y are taken with respect to
    % the state, the voltage, the current and the input.
    %
    % See also controller.avr.AVR_ST1.fcn_y, controller.avr.AVR_ST1.Jacobi_dx
    arguments (Input)
        t      double        % [s] Time (unused).
        x      double        % [pu] State `[Vtr; Vap; Vst]`: transducer output, amplifier output and stabilizer feedback.
        V      double        % [pu] Terminal voltage of the generator as `[real; imag]`.
        u      double        % [pu] Input `[Vref; Vpss; Ifield]`: voltage reference, PSS output and field current.
        param  double        % Parameter vector in the order of `sv_para`.
        omega0 (1,1) double  % [Hz] Nominal frequency (unused).
    end
    arguments (Output)
        Cyx  % Derivative of `y` with respect to `x`.
        Dyv  % Derivative of `y` with respect to `V` (`[real; imag]`).
        Dyu  % Derivative of `y` with respect to `u`.
    end
    Cyx = [0,1,0];

    Dyv = zeros(1,2);
    Dyu = zeros(1,3);

    % The output follows the active output limit (the same order as fcn_y)
    if param(8) && (param(9) < Inf || param(10) > -Inf)
        Vabs  = abs([1,1j]*V);
        dVabs = V(:).'/Vabs;                % derivative of |V| by [real, imag]
        if Vabs == 0
            dVabs = [0, 0];
        end
        y = x(2);
        if param(9) < Inf && param(9)*Vabs - param(11)*u(3) < y
            y   = param(9)*Vabs - param(11)*u(3);
            Cyx = [0,0,0];
            Dyv = param(9)*dVabs;
            Dyu = [0, 0, -param(11)];
        end
        if param(10) > -Inf && param(10)*Vabs > y
            Cyx = [0,0,0];
            Dyv = param(10)*dVabs;
            Dyu = zeros(1,3);
        end
    end
end