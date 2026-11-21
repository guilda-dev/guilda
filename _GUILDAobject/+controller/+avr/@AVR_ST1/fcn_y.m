function y = fcn_y(t, x, V, u, param, omega0)
    % Return the output of the AVR_ST1 controller.
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
        y  % [pu] Field voltage `Vfield` applied to the generator: the amplifier output `Vap` within the output limits.
    end

    y = x(2);
    if param(8)
        % Output limits of textbook (5.32); the lower one wins when they cross
        Vabs = abs([1,1j]*V);
        if param(9) < Inf
            y = min(y, param(9)*Vabs - param(11)*u(3));
        end
        if param(10) > -Inf
            y = max(y, param(10)*Vabs);
        end
    end
end