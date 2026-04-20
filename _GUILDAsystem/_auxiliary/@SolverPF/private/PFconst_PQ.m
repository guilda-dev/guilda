function [con, jacobi_V, jacobi_I] = PFconst_PQ(rv_V,rv_I,PQstar)
    Vre = rv_V(1);
    Vim = rv_V(2);
    Ire = rv_I(1);
    Iim = rv_I(2);

    PQ = [ Ire,Iim;...
          -Iim,Ire] * rv_V;
    con = PQ - PQstar;


    jacobi_V = [ Ire, Iim ; ... % P
                -Iim, Ire ];    % Q
    jacobi_I = [ Vre, Vim ; ... % P
                 Vim,-Vre ];    % Q
end