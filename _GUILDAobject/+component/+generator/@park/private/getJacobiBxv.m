function Bxv = getJacobiBxv(t, x, V, I, u, param, omega0) %#ok   
    delta = x(1);      
    Eq    = x(3);    
    Ed    = x(4);
    psiq  = x(5);  
    psid  = x(6);  

    Vre   = V(1);   
    Vim   = V(2);
    
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
    
    dVd_dVre = sin(delta);  dVd_dVim = -cos(delta);
    dVq_dVre = cos(delta);  dVq_dVim = sin(delta);

    dId_dVq = -1/Xdpp;
    dIq_dVd = 1/Xqpp;

    Bxv = zeros(6, 2);
    
    Bxv(2,1) = -(dVd_dVre*Id + Vd*(dId_dVq*dVq_dVre) + dVq_dVre*Iq + Vq*(dIq_dVd*dVd_dVre));
    Bxv(2,2) = -(dVd_dVim*Id + Vd*(dId_dVq*dVq_dVim) + dVq_dVim*Iq + Vq*(dIq_dVd*dVd_dVim));
    
    df5_dVre  = -(Xqp-Xls)*dIq_dVd*dVd_dVre;
    df5_dVim  = -(Xqp-Xls)*dIq_dVd*dVd_dVim;
    
    df6_dVre  = -(Xdp-Xls)*dId_dVq*dVq_dVre;
    df6_dVim  = -(Xdp-Xls)*dId_dVq*dVq_dVim;

    alpha_d = (Xdp-Xdpp)/(Xdp-Xls)^2;
    coeff_d = (Xd-Xdp);    
    Bxv(3,1) = -coeff_d * (dId_dVq*dVq_dVre + alpha_d*df6_dVre);
    Bxv(3,2) = -coeff_d * (dId_dVq*dVq_dVim + alpha_d*df6_dVim);

    alpha_q = (Xqp-Xqpp)/(Xqp-Xls)^2;
    coeff_q = (Xq-Xqp);    
    Bxv(4,1) = coeff_q * (dIq_dVd*dVd_dVre + alpha_q*df5_dVre);
    Bxv(4,2) = coeff_q * (dIq_dVd*dVd_dVim + alpha_q*df5_dVim);

    Bxv(5,[1,2]) = [df5_dVre, df5_dVim];     
    Bxv(6,[1,2]) = [df6_dVre, df6_dVim];     
end