function Bxu = getJacobiBxu(t,x,V,I,u,param,omega0) %#ok               
    Bxu = zeros(4, 2);
        
    Bxu(2, 7) = 1;            
    Bxu(3, 8) = 1;            
end