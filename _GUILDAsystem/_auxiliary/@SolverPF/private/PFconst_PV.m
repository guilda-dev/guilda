function [con,jacobi_V,jacobi_I] = PFconst_PV(rv_V,rv_I,PVstar)
% Power flow equation of a PV bus and its Jacobians (residual of fsolve).
    arguments (Input)
        rv_V     (2,1) double  % [pu] Bus voltage [real; imag].
        rv_I     (2,1) double  % [pu] Bus current [real; imag].
        PVstar   (2,1) double  % [pu] Specified [P; |V|].
    end
    arguments (Output)
        con      (2,1) double  % [pu] Mismatch [P; |V|] - PVstar.
        jacobi_V (2,2) double  % Jacobian of con with respect to rv_V.
        jacobi_I (2,2) double  % Jacobian of con with respect to rv_I.
    end
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