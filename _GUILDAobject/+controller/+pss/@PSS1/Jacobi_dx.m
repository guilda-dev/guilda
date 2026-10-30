function [Axx,Bxv,Bxi,Bxu] = Jacobi_dx(t,x,V,I,u,param,omega0) %#ok
    % Return the Jacobians of the PSS1 state equation.
    % The derivatives of the right-hand side `f` of fcn_dx are taken with respect to
    % the state, the voltage, the current and the input.
    %
    % Inputs:
    % - `t` [s] Time (unused).
    % - `x` [pu] State `[xiWS; xi1; xi2]` of the washout filter and the two lead-lag blocks.
    % - `V` [pu] Terminal voltage as `[real; imag]` (unused).
    % - `I` [pu] Terminal current as `[real; imag]` (unused).
    % - `u` [pu] Frequency deviation `omega` of the generator.
    % - `param` Parameter vector in the order of `sv_para`.
    % - `omega0` [Hz] Nominal frequency (unused).
    %
    % Outputs:
    % - `Axx` Derivative of `f` with respect to `x`.
    % - `Bxv` Derivative of `f` with respect to `V` (`[real; imag]`).
    % - `Bxi` Derivative of `f` with respect to `I` (`[real; imag]`).
    % - `Bxu` Derivative of `f` with respect to `u`.
    %
    % See also controller.pss.PSS1.fcn_dx, controller.pss.PSS1.Jacobi_Y
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
    
    Bxi = zeros(nx,2);

    nu = numel(u);

    kpss = param(1);         

    Bxu = zeros(nx,nu);
    Bxu([1,2,3],1) = [kpss; ...
                      kpss*(1-td1/tn1);
                      kpss*tn1/td1*(1-td2/tn2)];
end