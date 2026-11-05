function [con, jacobi_V, jacobi_I] = PFconst_PQ(rv_V,rv_I,PQstar)
% Power flow equation of a PQ bus and its Jacobians (residual of fsolve).
    arguments (Input)
        rv_V     (2,1) double  % [pu] Bus voltage [real; imag].
        rv_I     (2,1) double  % [pu] Bus current [real; imag].
        PQstar   (2,1) double  % [pu] Specified [P; Q].
    end
    arguments (Output)
        con      (2,1) double  % [pu] Mismatch [P; Q] - PQstar.
        jacobi_V (2,2) double  % Jacobian of con with respect to rv_V.
        jacobi_I (2,2) double  % Jacobian of con with respect to rv_I.
    end
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