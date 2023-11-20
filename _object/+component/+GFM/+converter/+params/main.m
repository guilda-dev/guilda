function params = main(omega0)
    if nargin==0
        omega0 = 2*pi*60;
    end

    % Sbase = 100 * 1e3;
    % Vbase = 230 * 1e3;
    % 
    % Ibase = Sbase/Vbase;
    % Zbase = Vbase / Ibase;
    % Lbase = Zbase / omega0;
    % Cbase = 1 / omega0 / Zbase;

    % R = 0.001    / Zbase;
    % L = 200*1e-6 / Lbase;
    % C = 300*1e-6 / Cbase;
    
    % R_g = 0;
    % L_g = 0.061 * 1e-2 / Lbase;

    Sr = 100 * 1e3;
    Vr = 480;
    
    Ir = Sr/Vr;
    Zr = Vr^2/Sr;
    Lr = Zr;
    Cr = 1/Zr;

    R = 0;
    L = 0.367 * 1e-3 / Lr;
    C = 191 * 1e-6 / Cr;
    
    R_g = 0;
    L_g = 0.061 * 1e-2 / Lr;

    n = 1; %100;

    params = table(R,L,C,L_g,R_g,n);
end