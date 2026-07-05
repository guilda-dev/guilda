function [Func, x0, exitFlag, options] = CalculateInitialCondition(o, options)

    Mass = @(t,y) o.MassMatrix.MassMatrix;
    Func = o.ODEFcn;
        
    options.Mass = Mass;

    x0_est  = o.InitialValue;
    xp0_est = x0_est;
    
    xp0 = zeros(0,1);
    dae = @(t,y,yp) Mass(t,y)*yp-Func(t,y);                        
    try
        exitFlag = false;
        [x0,xp0] = decic(dae, 0, x0_est, [], xp0_est, [], options);                 
    catch me
        exitFlag = true;
        msg = me.message;
        warning(msg)
    end               

    options.InitialSlope = xp0;                        
end