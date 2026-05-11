function Axx = getJacobiAxx(t, x, V, I, u, param, omega0) %#ok
    delta = x(1);      
    Eq    = x(3);    
    Ed    = x(4);
    psiq  = x(5);  
    psid  = x(6);  

    Vre   = V(1);   
    Vim   = V(2);
    
    D    = param(2); 
    Xd   = param(3); 
    Xdp  = param(4); 
    Xdpp = param(5); 
    Xq   = param(6); 
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

    Axx = zeros(6, 6);

    Axx(1,2) = 2 * pi * omega0;

    dP_ddel = dVd_ddel*Id + Vd*(dId_dVq*dVq_ddel) + dVq_ddel*Iq + Vq*(dIq_dVd*dVd_ddel);
    Axx(2,:) = [          -dP_ddel, ...
                                -D, ...
                     -Vd * dId_dEq, ...
                     -Vq * dIq_dEd, ...
                   -Vq * dIq_dpsiq, ...
                   -Vd * dId_dpsid];    

    df5_dEd   = -1 - (Xqp-Xls)*dIq_dEd;
    df5_dpsiq = -1 - (Xqp-Xls)*dIq_dpsiq;
    df5_ddel  = -(Xqp-Xls)*dIq_dVd*dVd_ddel;    
    
    df6_dEq   = 1 - (Xdp-Xls)*dId_dEq;
    df6_dpsid = -1 - (Xdp-Xls)*dId_dpsid;
    df6_ddel  = -(Xdp-Xls)*dId_dVq*dVq_ddel;    

    alpha_d = (Xdp-Xdpp)/(Xdp-Xls)^2;
    coeff_d = (Xd-Xdp);
    Axx(3,[1,3,6]) = [-coeff_d * (dId_dVq*dVq_ddel + alpha_d*df6_ddel), ...
                            -1 - coeff_d * (dId_dEq + alpha_d*df6_dEq), ...
                            -coeff_d * (dId_dpsid + alpha_d*df6_dpsid)];    

    alpha_q = (Xqp-Xqpp)/(Xqp-Xls)^2;
    coeff_q = (Xq-Xqp);
    Axx(4,[1,4,5]) = [coeff_q * (dIq_dVd*dVd_ddel + alpha_q*df5_ddel), ...
                           -1 + coeff_q * (dIq_dEd + alpha_q*df5_dEd), ...
                            coeff_q * (dIq_dpsiq + alpha_q*df5_dpsiq)];    

    Axx(5,[1,4,5]) = [df5_ddel, df5_dEd, df5_dpsiq];     
    Axx(6,[1,3,6]) = [df6_ddel, df6_dEq, df6_dpsid];     

end
