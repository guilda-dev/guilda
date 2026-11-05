function [con,jacobi_V,jacobi_I] = PFconst_slack(rv_V,~,tVstar)
% Power flow equation of the slack bus and its Jacobians (residual of fsolve).
    arguments (Input)
        rv_V     (2,1) double  % [pu] Bus voltage [real; imag].
        ~
        tVstar   (2,1) double  % Specified [angle [rad]; |V| [pu]].
    end
    arguments (Output)
        con      (2,1) double  % Mismatch [angle; |V|] - tVstar.
        jacobi_V (2,2) double  % Jacobian of con with respect to rv_V.
        jacobi_I (2,2) double  % Jacobian of con with respect to the bus current (zero).
    end
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