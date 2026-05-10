function Axx = getJacobiAxx(t, x, V, u, param, omega0) %#ok
             
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
        
end