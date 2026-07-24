function [Axx,Bxv,Bxi,Bxu] = Jacobi_dx(t,x,V,I,u,param,omega0) %#ok
    tn1 = param(3);
    td1 = param(4);
    tn2 = param(5);
    td2 = param(6);                                            

    Axx = zeros(3, 3);
    
    Axx(1,1) = -1;
        
    Axx(2,[1,2]) = [-(1 - td1/tn1), -1];    
        
    Axx(3,[1,2,3]) = [(1 - td2/tn2) * (-tn1/td1), ...
                      (1 - td2/tn2) * (-tn1/td1), ...
                                             -1];    

    nx  = numel(x);
    Bxv = zeros(nx,2);
    
    Bxi = zeros(nx,2);

    nu = numel(u);

    kpss = param(1);         

    Bxu = zeros(nx,nu);
    Bxu([1,2,3],1) = [kpss; ...
                      kpss*(1-td1/tn1);
                      kpss*tn1/td1*(1-td2/tn2)];
end