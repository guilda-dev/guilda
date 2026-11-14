function [cv_V, flag, output, cm_Vhistory, rv_step] = solve(obj, cm_Y, tab_PFcondition, sct_options)
% Solve the power equations of the given admittance matrix and power flow conditions.
%
% Builds the power equations (private power_equation) from cm_Y and tab_PFcondition at
% every call and runs the Method class of sct_options.Solver (see SolverPF). It reads no
% network, bus, branch or component: net.calculate_powerflow assembles the inputs and
% builds the outputs it returns. The solver keeps only the last converged solution and the
% bus tags it belongs to, as the warm start of the next call with the same bus tags.
    arguments (Input)
        obj % Solver (net.solver_PF).
        cm_Y (:,:) double % [pu] Bus admittance matrix (rows and columns in tab_PFcondition order).
        tab_PFcondition table % Power flow conditions, one row per bus: Type, Varg, V, P, Q (Bus.get_pf_condition); row names = bus tags.
        sct_options (1,1) struct % Options of the call (PowerNetwork.calculate_powerflow): Solver, Tolerance, MaxIteration, Verbose, WarmStart, PlotFcn.
    end
    arguments (Output)
        cv_V (:,1) double % [pu] Complex bus voltages of the solution (tab_PFcondition order).
        flag % 1 converged, 0 MaxIteration reached, -1 stopped by PlotFcn, -2 diverged or no solution (see SolverPF).
        output % Solver details; output.message describes the outcome.
        cm_Vhistory double % [pu] Bus voltages at each iteration, or ODE step ("dynamic"), one column each.
        rv_step double % Iteration numbers, or virtual times ("dynamic"), of cm_Vhistory.
    end
    sv_bus = reshape(string(tab_PFcondition.Properties.RowNames), [], 1);
    [f_res, f_jac, f_grad] = power_equation(cm_Y, tab_PFcondition);
    sct_eq = struct("tab", tab_PFcondition, "f_res", f_res, "f_jac", f_jac, "f_grad", f_grad);
    cv_V0  = initial_voltage(obj, tab_PFcondition, sv_bus, sct_options.WarmStart);

    [cv_V, flag, output, cm_Vhistory, rv_step] = run_method(cm_Y, sct_eq, cv_V0, sct_options);
    if flag == 1
        obj.cv_Vwarm  = cv_V;
        obj.sv_warmBus = sv_bus;
    end
end


function cv_V0 = initial_voltage(obj, tab, sv_bus, l_warm)
% The kept solution (WarmStart, same bus tags), or the flat start: angle 0 and magnitude 1,
% with the set V at PV and slack buses and the set angle at the slack bus
    if l_warm && isequal(obj.sv_warmBus, sv_bus)
        cv_V0 = obj.cv_Vwarm;
        return
    end
    rv_V  = ones(height(tab), 1);
    rv_T  = zeros(height(tab), 1);
    lv_set = tab.Type ~= "PQ";
    rv_V(lv_set) = tab.V(lv_set);
    lv_slack = tab.Type == "slack";
    rv_T(lv_slack) = tab.Varg(lv_slack);
    cv_V0 = rv_V .* exp(1j*rv_T);
end


function [cv_Vbus,flag,output,cm_Vhistory,rv_step] = run_method(cm_Y, sct_eq, cv_V0, sct)
% Create the Method object of sct.Solver from the options of the call and the settings
% <Solver><option> of GUILDA.setting, and map its results to the bus voltages (cv_Vbus),
% flag, output, the voltage history and its steps.
    tab    = sct_eq.tab;
    r_tol  = sct.Tolerance;
    n_max  = sct.MaxIteration;
    l_plot = ~isequal(sct.PlotFcn, "none");
    s_display = "none";
    if sct.Verbose
        s_display = "iter";
    end

    % a bus without branches (not slack) has no determined voltage: no solution
    lv_isolated = ~any(cm_Y, 2) & tab.Type ~= "slack";
    if any(lv_isolated)
        cv_Vbus     = cv_V0;
        cm_Vhistory = cv_Vbus;
        rv_step     = 0;
        flag        = -2;
        output = struct("iterations", 0, "algorithm", sct.Solver, "residual", NaN, "message", ...
            sprintf('✘ No power flow solution: the bus %s has no branch, so its voltage is not determined.', ...
                    join(string(tab.Properties.RowNames(lv_isolated)), ", ")));
        return
    end

    if sct.Solver == "dynamic"
        tab.Varg0 = angle(cv_V0);     % initial voltages of MethodDynamic
        tab.V0    = abs(cv_V0);
        md = MethodDynamic(Y=cm_Y, PFcondition=tab, Tolerance=r_tol);
        if l_plot
            md.f_iter = live_residual(sct.PlotFcn, sct.Solver, sct_eq.f_res, sct_eq.tab, r_tol);
        end
        [cv_Vbus,flag,output,cm_Vhistory,rv_step] = md.solve();
        return
    end

    f_res  = sct_eq.f_res;
    f_jac  = sct_eq.f_jac;
    f_grad = sct_eq.f_grad;
    rv_x0  = reshape([real(cv_V0), imag(cv_V0)].', [], 1);
    lv_PQ  = tab.Type == "PQ";
    rv_T0  = angle(cv_V0);
    rv_V0  = abs(cv_V0);
    rv_T0(tab.Type == "slack") = tab.Varg(tab.Type == "slack");
    rv_V0(~lv_PQ) = tab.V(~lv_PQ);
    rv_xp0 = [rv_T0; rv_V0];      % "gradient": the fixed values at their settings
    switch sct.Solver
        case "newton"
            mt = MethodNewtonRaphson(Fcn=f_res, Jac=f_jac, InitVal=rv_x0, ...
                ConvTol=r_tol, MaxIter=auto(n_max, 50), StepSize=GUILDA.config("PowerFlowCalculation", "NewtonStepSize"), Display=s_display);
        case "gradient"
            r_alpha = GUILDA.config("PowerFlowCalculation", "GradientStepSize");
            if isnan(r_alpha)
                r_alpha = 0.5/(max(abs(diag(cm_Y))) * max([tab.V; 1], [], "omitnan")^2);
            end
            mt = MethodGradient(Fcn=f_grad, InitVal=rv_xp0, ...
                StepSize=r_alpha, ConvTol=r_tol, MaxIter=auto(n_max, 1e6), Display=s_display);
        case "levenberg-marquardt"
            mt = MethodLevenbergMarquardt(Fcn=f_res, Jac=f_jac, InitVal=rv_x0, ...
                ConvTol=r_tol, MaxIter=auto(n_max, 100), Display=s_display);
        case "fsolve"
            mt = MethodFsolve(Fcn=f_res, Jac=f_jac, InitVal=rv_x0, ...
                ConvTol=r_tol, MaxIter=auto(n_max, 400), MaxFunEvals=auto(GUILDA.config("PowerFlowCalculation", "FsolveMaxFunctionEvaluations"), 0), Display=s_display, ...
                UseParallel=GUILDA.config("PowerFlowCalculation", "FsolveUseParallel"), Feature='Solver="fsolve" of the power flow');
    end
    if l_plot
        mt.f_iter = live_residual(sct.PlotFcn, sct.Solver, f_res, tab, r_tol);
    end
    if sct.Solver == "gradient"
        [rm_xp, flag, output, rm_hist, rv_step] = mt.solve();
        n_bus       = height(tab);            % [theta; V] -> complex voltages
        cv_Vbus     = rm_xp(n_bus+1:end) .* exp(1j*rm_xp(1:n_bus));
        cm_Vhistory = rm_hist(n_bus+1:end,:) .* exp(1j*rm_hist(1:n_bus,:));
        return
    end
    [rm_x, flag, output, rm_hist, rv_step] = mt.solve();
    cv_Vbus     = rm_x(1:2:end) + 1j*rm_x(2:2:end);
    cm_Vhistory = rm_hist(1:2:end,:) + 1j*rm_hist(2:2:end,:);
end


function n = auto(n, n_auto)
% NaN is the automatic value of the setting (n_auto: the value given to the method)
    if isnan(n)
        n = n_auto;
    end
end
