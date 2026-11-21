function [Cyx,Dyv,Dyu] = Jacobi_Y(t,x,V,u,param,omega0)
    % Return the Jacobians of the output of the Static AVR: the feedthrough `Dyu = [1, 1]`.
    % Dyu is returned explicitly: an empty Jacobian would be read as 0 by get_linear_matrix.
    %
    % See also controller.avr.Static.fcn_y
    arguments (Input)
        t      double        % [s] Time (unused).
        x      double        % State (none, 0x1).
        V      double        % [pu] Terminal voltage of the generator as `[real; imag]` (unused).
        u      double        % [pu] Input `[Vfd_ref; Vpss]`.
        param  double        % Parameter vector (empty).
        omega0 (1,1) double  % [Hz] Nominal frequency (unused).
    end
    arguments (Output)
        Cyx  % Derivative of `y` with respect to `x`, 1x0.
        Dyv  % Derivative of `y` with respect to `V` (`[real; imag]`), 1x2.
        Dyu  % Derivative of `y` with respect to `u`, [1, 1].
    end
    Cyx = zeros(1,0);
    Dyv = zeros(1,2);
    Dyu = [1, 1];
end
