function [Axx,Bxv,Bxu] = Jacobi_dx(t,x,V,u,param,omega0)
    % Return the Jacobians of the PSS1 state equation.
    % The derivatives of the right-hand side `f` of fcn_dx are taken with respect to
    % the state, the voltage, the current and the input.
    %
    % See also controller.pss.PSS1.fcn_dx, controller.pss.PSS1.Jacobi_Y
    arguments (Input)
        t      double        % [s] Time (unused).
        x      double        % [pu] State `[xiWS; xi1; xi2]` of the washout filter and the two lead-lag blocks.
        V      double        % [pu] Terminal voltage as `[real; imag]` (unused).
        u      double        % [pu] Frequency deviation `omega` of the generator.
        param  double        % Parameter vector in the order of `sv_para`.
        omega0 (1,1) double  % [Hz] Nominal frequency (unused).
    end
    arguments (Output)
        Axx  % Derivative of `f` with respect to `x`.
        Bxv  % Derivative of `f` with respect to `V` (`[real; imag]`).
        Bxu  % Derivative of `f` with respect to `u`.
    end
    kpss = param(1);
    tn1 = param(3);
    td1 = param(4);
    tn2 = param(5);
    td2 = param(6);

    % Lead-lag blocks as in fcn_dx: tn = td = 0 is the identity, tn = 0 a first-order lag
    if tn1 == 0 && td1 == 0
        tn1 = 1; td1 = 1;
    end
    if tn2 == 0 && td2 == 0
        tn2 = 1; td2 = 1;
    end
    % a: coefficient of the block input in the state equation; dv1: derivative of the
    % output v1 of the first block with respect to [xiWS, xi1, omega]
    if tn1 == 0
        a1  = 1;
        dv1 = [0, 1, 0];
    else
        a1  = 1 - td1/tn1;
        dv1 = [-tn1/td1, -tn1/td1, kpss*tn1/td1];
    end
    if tn2 == 0
        a2 = 1;
    else
        a2 = 1 - td2/tn2;
    end

    Axx = zeros(3, 3);
    
    Axx(1,1) = -1;
        
    Axx(2,[1,2]) = [-a1, -1];    
        
    Axx(3,[1,2,3]) = [a2 * dv1(1), ...
                      a2 * dv1(2), ...
                               -1];    

    nx  = numel(x);
    Bxv = zeros(nx,2);
    

    nu = numel(u);

    Bxu = zeros(nx,nu);
    Bxu([1,2,3],1) = [kpss; ...
                      kpss*a1;
                      dv1(3)*a2];
end