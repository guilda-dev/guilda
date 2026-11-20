function [Cyx,Dyv,Dyu] = Jacobi_Y(t,x,V,u,param,omega0)
    % Return the Jacobians of the PSS1 output.
    % The derivatives of the output `y` of fcn_y are taken with respect to
    % the state, the voltage, the current and the input.
    %
    % See also controller.pss.PSS1.fcn_y, controller.pss.PSS1.Jacobi_dx
    arguments (Input)
        t      double        % [s] Time (unused).
        x      double        % [pu] State `[xiWS; xi1; xi2]` of the washout filter and the two lead-lag blocks.
        V      double        % [pu] Terminal voltage as `[real; imag]` (unused).
        u      double        % [pu] Frequency deviation `omega` of the generator.
        param  double        % Parameter vector in the order of `sv_para`.
        omega0 (1,1) double  % [Hz] Nominal frequency (unused).
    end
    arguments (Output)
        Cyx  % Derivative of `y` with respect to `x`.
        Dyv  % Derivative of `y` with respect to `V` (`[real; imag]`).
        Dyu  % Derivative of `y` with respect to `u`.
    end
    kpss = param(1);     
    tn1 = param(3);
    td1 = param(4);
    tn2 = param(5);
    td2 = param(6);

    Vpss_min = param(7); 
    Vpss_max = param(8);
        
    xiWS = x(1);
    xi1  = x(2);
    xi2  = x(3);
        
    omega = u;
    vWS = kpss * omega - xiWS;

    % Lead-lag blocks as in fcn_y: tn = td = 0 is the identity, tn = 0 a first-order lag
    if tn1 == 0 && td1 == 0
        tn1 = 1; td1 = 1;
    end
    if tn2 == 0 && td2 == 0
        tn2 = 1; td2 = 1;
    end
    % dv1: derivative of the output v1 of the first block with respect to [xiWS, xi1, omega]
    if tn1 == 0
        v1  = xi1;
        dv1 = [0, 1, 0];
    else
        v1  = tn1 * (vWS - xi1) / td1;
        dv1 = [-tn1/td1, -tn1/td1, kpss*tn1/td1];
    end
    if tn2 == 0
        vpl = xi2;
        dvpl_dv1  = 0;
        dvpl_dxi2 = 1;
    else
        vpl = tn2 * (v1 - xi2) / td2;
        dvpl_dv1  = tn2/td2;
        dvpl_dxi2 = -tn2/td2;
    end
    
    S = tools.heaviside(vpl - Vpss_min) - tools.heaviside(vpl - Vpss_max);
    
    Cyx = [S * dvpl_dv1 * dv1(1), ...
           S * dvpl_dv1 * dv1(2), ...
           S * dvpl_dxi2];

    Dyv = zeros(1,2);

    nu = numel(u);
    Dyu = zeros(1,nu);   
    if tn1 ~= 0 && tn2 ~= 0
        Dyu(1,1) = tn1*tn2*kpss/td1/td2 * S;
    else
        Dyu(1,1) = S * dvpl_dv1 * dv1(3);
    end
end