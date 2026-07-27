function Mass = fcn_Mass(t, x, V, I, u, param, omega0) %#ok      
        
    ttr = param(1);    
    tap = param(5);
    kst = param(6);
    tst = param(7);    

    Mass = [ttr,    0,   0;
              0,  tap,   0;   
              0, -kst, tst];
    
end