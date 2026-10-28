function [Func, x0, exitFlag, options] = CalculateInitialCondition(o, options)

    Mass = @(t,y) o.MassMatrix.MassMatrix;
    Func = o.ODEFcn;
        
    options.Mass = Mass;

    x0_est  = o.InitialValue;
    xp0_est = x0_est;
    
    x0  = zeros(0,1);
    xp0 = zeros(0,1);
    dae = @(t,y,yp) Mass(t,y)*yp-Func(t,y);                        
    % Keep the differential states (e.g. offsets of events) and solve only the algebraic ones;
    % if that fails, let decic change all of them.
    fixed_x0 = double(any(o.MassMatrix.MassMatrix ~= 0, 2));
    try
        exitFlag = false;
        try
            [x0,xp0] = decic(dae, 0, x0_est, fixed_x0, xp0_est, [], options);
        catch
            [x0,xp0] = decic(dae, 0, x0_est, [], xp0_est, [], options);
        end
    catch me
        exitFlag = true;
        msg = me.message;
        warning(msg)
    end               

    options.InitialSlope = xp0;                        
end