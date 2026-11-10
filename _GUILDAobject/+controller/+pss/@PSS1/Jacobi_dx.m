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
    tn1 = param(3);
    td1 = param(4);
    tn2 = param(5);
    td2 = param(6);                                            

    Axx = zeros(3, 3);
    
    Axx(1,1) = -1;
        
    Axx(2,[1,2]) = [-(1 - td1/tn1), -1];    
        
    Axx(3,[1,2,3]) = [(1 - td2/tn2) * (-tn1/td1), ...
                      (1 - td2/tn2) * (-tn1/td1), ...
                                             -1];    

    nx  = numel(x);
    Bxv = zeros(nx,2);
    

    nu = numel(u);

    kpss = param(1);         

    Bxu = zeros(nx,nu);
    Bxu([1,2,3],1) = [kpss; ...
                      kpss*(1-td1/tn1);
                      kpss*tn1/td1*(1-td2/tn2)];
end