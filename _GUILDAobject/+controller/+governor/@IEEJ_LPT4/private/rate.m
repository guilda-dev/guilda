function [r_rate, r_slope, l_ref] = rate(x, u, param)
% Servo speed after the low value gate and the limits, its slope and the gate branch
    arguments (Input)
        x      double  % [pu] State of the governor.
        u      double  % [pu] Input `[omega; Pref; Plimit]`.
        param  double  % Parameter vector in the order of `sv_para`.
    end
    arguments (Output)
        r_rate   % Speed of the servo position.
        r_slope  % Derivative of r_rate with respect to the error of the servo position.
        l_ref    % True when the load setting passes the low value gate.
    end
    [r_gate, l_ref] = controller.governor.abstract.lvg(u(2) + x(1), u(3));
    [r_rate, r_slope] = controller.governor.abstract.servo_rate(r_gate - x(3), x(3), 1/param(7), ...
                                                                param(9), param(8), param(11), param(10));
end
