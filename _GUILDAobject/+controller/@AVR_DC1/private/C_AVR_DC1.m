function C = C_AVR_DC1(t, x, V, u, param, omega0) %#ok

    C = zeros(1, 4);    
    
    C(1,3) = 1; 
    
end