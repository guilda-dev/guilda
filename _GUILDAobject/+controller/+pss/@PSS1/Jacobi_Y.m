function [Cyx,Dyv,Dyi,Dyu] = Jacobi_Y(t,x,V,I,u,param,omega0) %#ok
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
    v1  = tn1 * (vWS - xi1) / td1;
    vpl = tn2 * (v1 - xi2) / td2;
    
    S = tools.heaviside(vpl - Vpss_min) - tools.heaviside(vpl - Vpss_max);
    
    Cyx = zeros(1, 3);    
        
    dv1_dxiWS = -tn1/td1;
    dv1_dxi1  = -tn1/td1;
    
    Cyx(1,[1,2,3]) = [S * (tn2/td2) * dv1_dxiWS, ...
                      S * (tn2/td2) * dv1_dxi1 , ...
                      S * (-tn2/td2)];

    Dyv = zeros(1,2);

    Dyi = zeros(1,2);

    nu = numel(u);
    Dyu = zeros(1,nu);   

    Vpl  = tn2*(v1-xi2)/td2;

    Dyu(1,1) = tn1*tn2*kpss/td1/td2 * ( tools.heaviside(Vpl - Vpss_min) - tools.heaviside(Vpl - Vpss_max) );
end