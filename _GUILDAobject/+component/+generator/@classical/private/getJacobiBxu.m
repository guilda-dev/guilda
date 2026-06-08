function Bxu = getJacobiBxu(t,x,V,I,u,param,omega0) %#ok

    delta = x(1);

    Xd = param(3);        
    
    Vre = V(1);
    Vim = V(2);
        
    Vd = Vre*sin(delta) - Vim*cos(delta);
    
    Bxu = [zeros(1,2); [1,-Vd/Xd]];
end