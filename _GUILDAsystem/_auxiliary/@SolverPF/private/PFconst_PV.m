function [con,jacobi_V,jacobi_I] = PFconst_PV(rv_V,rv_I,PVstar)
    PV = [ rv_I.'*rv_V;...
             norm(rv_V)];    
    con = PV - PVstar;

    Vre = rv_V(1);
    Vim = rv_V(2);
    Ire = rv_I(1);
    Iim = rv_I(2);

    Vnorm = sqrt(Vre^2 +Vim^2);
    
    jacobi_V = [      Ire,       Iim ; ...% P
                Vre/Vnorm, Vim/Vnorm ];   % V
    jacobi_I = [ Vre, Vim ;... %P
                   0,   0 ];   %V
end