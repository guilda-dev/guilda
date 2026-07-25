function [R,Hxx,Hxv,Hvv] = hesse(t,x,V,I,u,param,omega0) %#ok
    delta = x(1);

    M  = param(1);
    D  = param(2);
    Xd = param(3);
    Xq = param(4);
    
    % Vfd = u(2);
    
    Vre = V(1);
    Vim = V(2);

    Ire = I(1);
    Iim = I(1);
    
    Vd = Vre*sin(delta) - Vim*cos(delta);
    Vq = Vre*cos(delta) + Vim*sin(delta);

    % P + j*Q = (Vre + j*Vim)(Ire - j*Iim)
    % P =   Vre*Ire + Vim*Iim;
    Q = - Vre*Iim + Vim*Ire;

    Hdd = [Vd -Vq]*[1/Xd 0; 0 1/Xq]*[Vd; -Vq] + Q;
    R_del = [cos(delta) sin(delta); sin(delta) -cos(delta)];
    Hdv = - [Vd -Vq]*[1/Xd 0; 0 1/Xq]*R_del + [Ire Iim];
    Hvv = R_del*[1/Xd 0; 0 1/Xq]*R_del;
          
    R = [D/omega0 M; -M 0];
    Hxx = [Hdd 0; 0 omega0*M];
    Hxv = [Hdv;0 0];
    
end
