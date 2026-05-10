function Mass = fcn_Mass(obj, t, x, V, u, param, omega0) %#ok   
    
    tWS = param(2);
    % 位相進み補償器    
    td1 = param(4);    
    td2 = param(6);

    Mass = [tWS,   0,   0;
              0, td1,   0;
              0,   0, td2];                   
    
end