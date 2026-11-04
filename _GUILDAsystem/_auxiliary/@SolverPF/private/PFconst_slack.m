function [con,jacobi_V,jacobi_I] = PFconst_slack(rv_V,~,tVstar)
    Vre = rv_V(1);
    Vim = rv_V(2);

    tV = [ atan(Vim/Vre) ;...
                      norm(rv_V) ];    
    con = tV - tVstar;

    Vdist = Vre^2 +Vim^2;
    Vnorm = sqrt(Vdist);

    jacobi_V = [-Vim/Vdist, Vre/Vdist ; ...% theta
                 Vre/Vnorm, Vim/Vnorm ];   % V
    jacobi_I = zeros(2,2);
end