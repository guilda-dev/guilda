function C = getJacobiC(t, x, V, u, param, omega0) %#ok

    delta = x(1);      
    Eq    = x(3);    
    Ed    = x(4);
    psiq  = x(5);  
    psid  = x(6);  

    Vre   = V(1);   
    Vim   = V(2);
        
    Xdp  = param(4);
    Xdpp = param(5);    
    Xqp  = param(7);    
    Xqpp = param(8);
    Xls  = param(13);    

    Vd = Vre*sin(delta) - Vim*cos(delta);
    Vq = Vre*cos(delta) + Vim*sin(delta);
        
    term_q = ((Xdpp-Xls)*Eq + (Xdp-Xdpp)*psid)/(Xdp-Xls);
    term_d = ((Xqpp-Xls)*Ed - (Xqp-Xqpp)*psiq)/(Xqp-Xls);
    Id = (term_q - Vq) / Xdpp;
    Iq = (Vd - term_d) / Xqpp;

    dVd_ddel = Vq;  
    dVq_ddel = -Vd; 

    dId_dEq    = (Xdpp-Xls)/(Xdpp*(Xdp-Xls));
    dId_dpsid  = (Xdp-Xdpp)/(Xdpp*(Xdp-Xls));
    dId_dVq    = -1/Xdpp;
    
    dIq_dEd    = -(Xqpp-Xls)/(Xqpp*(Xqp-Xls));
    dIq_dpsiq  = (Xqp-Xqpp)/(Xqpp*(Xqp-Xls));
    dIq_dVd    = 1/Xqpp;

    C = zeros(2, 6);    
    
    C(1,1) = -Iq*sin(delta) + Id*cos(delta) + cos(delta)*(dIq_dVd*dVd_ddel) + sin(delta)*(dId_dVq*dVq_ddel);
    C(2,1) =  Iq*cos(delta) + Id*sin(delta) + sin(delta)*(dIq_dVd*dVd_ddel) - cos(delta)*(dId_dVq*dVq_ddel);
    
    C(1,3:6) = [  sin(delta)*dId_dEq, ...
                  cos(delta)*dIq_dEd, ...
                cos(delta)*dIq_dpsiq, ...
                sin(delta)*dId_dpsid];         

    C(2,3:6) = [   -cos(delta)*dId_dEq, ...
                    sin(delta)*dIq_dEd, ...
                  sin(delta)*dIq_dpsiq, ...
                 -cos(delta)*dId_dpsid];    
end