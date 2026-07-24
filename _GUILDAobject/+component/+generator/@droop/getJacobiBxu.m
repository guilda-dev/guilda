function Bxu = getJacobiBxu(t,x,V,I,u,param,omega0) %#ok            
    
    delta = x(1);

    Xd = param(2);        
    
    Vre = V(1);
    Vim = V(2);
        
    Vd = Vre*sin(delta) - Vim*cos(delta);
    
    Bxu = [1,-Vd/Xd];    
end