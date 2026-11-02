function [x0, xp0, l_failed, l_relaxed, str_why, me_why] = CalculateInitialCondition(o, options)
% Consistent initial condition of a phase, for the ode object o.
% l_failed: none was found (x0, xp0 are empty). l_relaxed: the differential states had to
% move too. str_why: the reason of either. me_why: the error when l_failed.

    Mass = @(t,y) o.MassMatrix.MassMatrix;
    Func = o.ODEFcn;
        
    options.Mass = Mass;

    x0_est  = o.InitialValue;
    xp0_est = x0_est;
    
    x0  = zeros(0,1);
    xp0 = zeros(0,1);
    l_failed  = false;
    l_relaxed = false;
    str_why   = "";
    me_why    = [];
    dae = @(t,y,yp) Mass(t,y)*yp-Func(t,y);                        
    % Keep the differential states (e.g. offsets of events) and solve only the algebraic ones;
    % if that fails, let decic change all of them.
    fixed_x0 = double(any(o.MassMatrix.MassMatrix ~= 0, 2));
    try
        [x0,xp0] = decic(dae, 0, x0_est, fixed_x0, xp0_est, [], options);
    catch me_fixed
        str_why = explain_failure(me_fixed);
        try
            [x0,xp0] = decic(dae, 0, x0_est, [], xp0_est, [], options);
            l_relaxed = true;
        catch me
            l_failed = true;
            str_why  = explain_failure(me);
            me_why   = me;
        end
    end
end

function str_why = explain_failure(me)
% The message of decic, with the usual reason and remedy when it did not converge.
    str_why = string(me.message);
    if me.identifier == "MATLAB:decic:ConvergenceFail"
        str_why = "The algebraic equations could not be satisfied at the start of the phase (" + str_why + "). " ...
                + "A common reason is a constant-power load (""load-power"") that the network cannot supply " ...
                + "at the voltages of the phase, e.g. during a fault on or next to the bus that feeds it. " ...
                + "Use ""load-impedance"" for such a load or fault another bus.";
    end
end
