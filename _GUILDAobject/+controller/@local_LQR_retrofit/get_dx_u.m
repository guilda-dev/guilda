function [dx, u] = get_dx_u(obj, t, x, X, Vcell, Icell, U, is_linear)
% Return the state derivative and the input to the generator.
    arguments (Input)
        obj
        t          % [s] Time (unused).
        x          % Controller state.
        X          % Cell array with the generator state.
        Vcell      % [pu] Cell array with the terminal voltage `[real; imag]`.
        Icell      % [pu] Cell array with the terminal current (unused).
        U          % Global input (unused).
        is_linear = false  % True to use the linearized polar transform.
    end
    arguments (Output)
        dx  % Controller state derivative.
        u   % Cell array with the input to the generator.
    end
    if nargin < 8
        is_linear = false;
    end
    x1 = x(1:numel(obj.X0));
    x2 = x(numel(obj.X0)+1:end);
    u = zeros(2, 1);
    u(1) = obj.K*[(X{1}-obj.X0-x1); x2];

    delta = X{1}(1); delta0 = obj.delta0;
    E = X{1}(3); E0 = obj.E0;

    V = cell2mat(Vcell);

    if is_linear
        R_V = tools.matrix_polar_transform(obj.V0(1)+1j*obj.V0(2));
        V_linear = R_V*V; V0_linear = R_V*obj.V0;
        angleV = V_linear(1); absV = V_linear(2);
        angleV0 = V0_linear(1); absV0 = V0_linear(2);
    else
        angleV = atan2(V(2), V(1)); absV = norm(V);
        angleV0 = atan2(obj.V0(2), obj.V0(1)); absV0 = norm(obj.V0);
    end

    dx = obj.A*x + obj.Bv*[angleV-angleV0; absV-absV0] - obj.Bw*[delta-delta0; E-E0];
    u = num2cell(u(:), 1);

end
