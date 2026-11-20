function [Axx,Bxv,Bxu] = Jacobi_dx(t,x,V,u,param,omega0)
    % Return the Jacobians of the state equation of the Static governor: empty (no state).
    %
    % See also controller.governor.Static.Jacobi_Y
    arguments (Input)
        t      double        % [s] Time (unused).
        x      double        % State (none, 0x1).
        V      double        % [pu] Terminal voltage of the generator as `[real; imag]` (unused).
        u      double        % [pu] Input `Pmech_ref`.
        param  double        % Parameter vector (empty).
        omega0 (1,1) double  % [Hz] Nominal frequency (unused).
    end
    arguments (Output)
        Axx  % Derivative with respect to `x`, 0x0.
        Bxv  % Derivative with respect to `V`, 0x2.
        Bxu  % Derivative with respect to `u`, 0x1.
    end
    Axx = zeros(0,0);
    Bxv = zeros(0,2);
    Bxu = zeros(0,1);
end
