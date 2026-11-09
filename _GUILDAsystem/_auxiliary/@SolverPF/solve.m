function [result,flag,output] = solve(obj, net, sct_options)
% Solve the power flow with the given settings.
%
% Runs the power flow calculation of net with the effective settings sct_options and
% returns the computed values as a ResultPF. The solver is only read: nothing is
% written back into it. The calculation itself is done by the Method class of
% sct_options.Method (see SolverPF), created from the settings. Called by
% net.calculate_powerflow; calling it directly is for advanced use.
    arguments (Input)
        obj % Solver (net.solver_PF).
        net % Network with a slack bus.
        sct_options (1,1) struct = obj.get_options() % Effective settings (output of get_options).
    end
    arguments (Output)
        result % Bus and branch values of the solution.
        flag % 1/0/-2 (newton, gradient, levenberg-marquardt, fsolve; see MethodBase), or convergence (dynamic); positive or true = converged.
        output % Solver details; output.message describes the outcome.
    end
    t0 = tic;

    tab_Ymat  = net.get_admittance_matrix;
    tab_PFcondition = tools.vcellfun(@(b) b.get_pf_condition, net.a_Bus);
    sv_bus    = string(tab_PFcondition.Properties.RowNames);
    cm_Y      = tab_Ymat{sv_bus,sv_bus};

    [cv_Vbus,flag,output,cm_Vhistory,rv_step] = run_method(cm_Y, tab_PFcondition, sct_options);

    % Vbus -> Ibus -> Pbus,Qbus
    cv_Ibus = cm_Y*cv_Vbus;
    cv_Sbus = cv_Vbus .* conj(cv_Ibus);

    % convert double->table
    tab_bus = array2table(...
        [angle(cv_Vbus),abs(cv_Vbus),real(cv_Sbus),imag(cv_Sbus),cv_Vbus,cv_Ibus], ...
        "VariableNames",["Varg","V","P","Q","Vphasor","Iphasor"],"RowNames",sv_bus);
    tab_branch = branch_flow(net, sv_bus, cv_Vbus);

    result = ResultPF(net, obj, sct_options, flag, output, t0, ...
                             tab_bus, tab_branch, cm_Vhistory, rv_step);

    % Notify
    if flag<=0
        switch sct_options.WhenFailed
        case "WARN" ; show_msg("warning", "GUILDA:SolverPF:NotConverged", output.message)
        case "ERROR"; error(msg("GUILDA:SolverPF:NotConverged", output.message))
        case "DISP" ; disp(output.message)
        end
    end
end


function tab = branch_flow(net, sv_bus, cv_Vbus)
% Power and current at both ends of each branch (from = br.a_Bus{1}, to = br.a_Bus{2})
    n_br  = numel(net.a_Branch);
    cm_I  = zeros(n_br,2);
    cm_S  = zeros(n_br,2);
    for k = 1:n_br
        br = net.a_Branch{k};
        [~, idx] = ismember(string(br.a_Bus), sv_bus);
        cv_Vb = cv_Vbus(idx(:));
        cv_Ib = br.get_admittance_matrix() * cv_Vb;
        cm_I(k,:) = cv_Ib.';
        cm_S(k,:) = (cv_Vb .* conj(cv_Ib)).';
    end
    sv_branch = strings(n_br,1);
    for k = 1:n_br
        sv_branch(k) = string(net.a_Branch{k});
    end
    tab = table(real(cm_S(:,1)), imag(cm_S(:,1)), real(cm_S(:,2)), imag(cm_S(:,2)), ...
                cm_I(:,1), cm_I(:,2), real(sum(cm_S,2)), imag(sum(cm_S,2)), ...
                'VariableNames', ["Pfrom","Qfrom","Pto","Qto","Ifrom","Ito","Ploss","Qloss"], ...
                'RowNames', sv_branch);
end


function [cv_Vbus,flag,output,cm_Vhistory,rv_step] = run_method(cm_Y, tab, sct)
% Create the Method object of sct.Method from the settings and map its results to the bus
% voltages (cv_Vbus), flag, output, the voltage history and its steps.
    r_tol = sct.Tolerance;
    n_max = sct.MaxIterations;

    % a bus without branches (not slack) has no determined voltage: no solution
    lv_isolated = ~any(cm_Y, 2) & tab.Type ~= "slack";
    if any(lv_isolated)
        cv_Vbus     = tab.V0 .* exp(1j*tab.Varg0);
        cm_Vhistory = cv_Vbus;
        rv_step     = 0;
        flag        = -2;
        if sct.Method == "dynamic"
            flag = false;
        end
        output = struct("iterations", 0, "algorithm", sct.Method, "message", ...
            sprintf('✘ No power flow solution: the bus %s has no branch, so its voltage is not determined.', ...
                    join(string(tab.Properties.RowNames(lv_isolated)), ", ")));
        return
    end

    if sct.Method == "dynamic"
        sct_dyn = sct.dynamic;
        if r_tol == 0
            r_tol = 1e-5;
        end
        [cv_Vbus,flag,output,cm_Vhistory,rv_step] = MethodDynamic(Y=cm_Y, PFcondition=tab, ...
            Mass=sct_dyn.Mass, Damper=sct_dyn.Damper, foh_PQ=sct_dyn.foh_PQ, ...
            t_span=sct_dyn.t_span, Tolerance=r_tol).solve();
        return
    end

    [f_res, f_jac, rv_x0, f_grad, rv_xp0] = power_equation(cm_Y, tab);
    switch sct.Method
        case "newton"
            [rm_x, flag, output, rm_hist, rv_step] = MethodNewtonRaphson(Fcn=f_res, Jac=f_jac, InitVal=rv_x0, ...
                ConvTol=default(r_tol, 1e-8), MaxIter=default(n_max, 50), Display=sct.Display).solve();
        case "gradient"
            r_alpha = sct.gradient.StepSize;
            if r_alpha == 0
                r_alpha = 0.5/(max(abs(diag(cm_Y))) * max([tab.V; tab.V0], [], "omitnan")^2);
            end
            [rm_xp, flag, output, rm_hist, rv_step] = MethodGradient(Fcn=f_grad, InitVal=rv_xp0, ...
                StepSize=r_alpha, ConvTol=default(r_tol, 1e-8), MaxIter=default(n_max, 1e6), Display=sct.Display).solve();
            n_bus       = height(tab);            % [theta; V] -> complex voltages
            cv_Vbus     = rm_xp(n_bus+1:end) .* exp(1j*rm_xp(1:n_bus));
            cm_Vhistory = rm_hist(n_bus+1:end,:) .* exp(1j*rm_hist(1:n_bus,:));
            return
        case "levenberg-marquardt"
            [rm_x, flag, output, rm_hist, rv_step] = MethodLevenbergMarquardt(Fcn=f_res, Jac=f_jac, InitVal=rv_x0, ...
                ConvTol=default(r_tol, 1e-8), MaxIter=default(n_max, 100), Display=sct.Display).solve();
        case "fsolve"
            [rm_x, flag, output, rm_hist, rv_step] = MethodFsolve(Fcn=f_res, Jac=f_jac, InitVal=rv_x0, ...
                ConvTol=r_tol, MaxIter=n_max, MaxFunEvals=sct.MaxFunEvals, Display=sct.Display, ...
                UseParallel=sct.UseParallel, PlotFcn=sct.PlotFcn, Feature='Method="fsolve" of the power flow').solve();
    end
    cv_Vbus     = rm_x(1:2:end) + 1j*rm_x(2:2:end);
    cm_Vhistory = rm_hist(1:2:end,:) + 1j*rm_hist(2:2:end,:);
end


function r = default(r, r_default)
% 0 means the default of the method
    if r == 0
        r = r_default;
    end
end
