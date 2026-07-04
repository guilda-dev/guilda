function [ODEfcn, x0, options] = CalculateInitialCondition(o, options)

    Mass = @(t,y) o.MassMatrix.MassMatrix;
    Func = o.ODEFcn;

    x0_est  = o.InitialValue;
    xp0_est = x0_est;
    
    dae = @(t,y,yp) Mass(t,y)*yp-Func(t,y);                        
    [x0,xp0] = decic(dae, 0, x0_est, [], xp0_est, [], options); 

    options.Mass = Mass;
    options.InitialSlope = xp0;                        

    ODEfcn = Func;
end