function Mass = fcn_Mass(obj, t, x, V, I, u, param, omega0) %#ok      
        
    ttr = param(1);    
    tap = param(5);
    tex = param(8);
    kst = param(10);
    tst = param(11);

    Mass = [ttr,   0,    0,   0;
              0, tap,    0,   0;
              0,   0,  tex,   0;
              0,   0, -kst, tst];
    
end