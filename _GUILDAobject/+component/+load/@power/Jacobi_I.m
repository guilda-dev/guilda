function [Cix,Div,Dii,Diu] = Jacobi_I(t,x,V,I,u,param,omega0) %#ok
    Cix = zeros(2,0);
    P = u(1);
    Q = u(2);

    Vre  = V(1);
    Vim  = V(2);
    Vabs = abs([1,1j]*V);

    Div = [-P, Q; Q, P]*(Vre^2-Vim^2)/Vabs^4 - 2*[Q, P; P, -Q]*Vre*Vim/Vabs^4;
    Dii = zeros(2,2);
    
    % Vsq = Vre^2 + Vim^2;
    Vsq = Vabs^2;

    Diu = [ Vre/Vsq,  Vim/Vsq; Vim/Vsq, -Vre/Vsq];
end