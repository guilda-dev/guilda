function JacobiDu = getJacobiDu(t,x,V,u,param,omega0) %#ok
    nu = numel(u);
    JacobiDu = zeros(1,nu);

    kpss = param(1);     
    
    tn1 = param(3);
    td1 = param(4);
    tn2 = param(5);
    td2 = param(6);

    Vpss_min = param(7);
    Vpss_max = param(8);
    
    omega = u;    

    xiWS = x(1);
    xi1  = x(2);
    xi2  = x(3);    

    vWS = kpss*omega - xiWS;
    v1  = tn1*(vWS-xi1)/td1;       

    Vpl  = tn2*(v1-xi2)/td2;

    JacobiDu(1,1) = tn1*tn2*kpss/td1/td2 * ( heaviside(Vpl - Vpss_min) - heaviside(Vpl - Vpss_max) );
end