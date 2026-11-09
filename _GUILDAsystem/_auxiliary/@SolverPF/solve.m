function [result,flag,output] = solve(obj, net, sct_options)
% Solve the power flow with the given settings.
%
% Runs the power flow calculation of net with the effective settings sct_options and
% returns the computed values as a ResultPF. The solver keeps only the warm start
% solution (a converged one) and the cache of net (see SolverPF). The calculation itself
% is done by the Method class of sct_options.Method (see SolverPF), created from the
% settings. Called by net.calculate_powerflow; calling it directly is for advanced use.
    arguments (Input)
        obj % Solver (net.solver_PF).
        net % Network with a slack bus.
        sct_options (1,1) struct = obj.get_options() % Effective settings (output of get_options).
    end
    arguments (Output)
        result % Bus and branch values of the solution.
        flag % 1 converged, 0 MaxIteration reached, -2 diverged or no solution (see SolverPF).
        output % Solver details; output.message describes the outcome.
    end
    t0 = tic;

    sv_bus = reshape(string(net.a_Bus), [], 1);
    sct_eq = equations(obj, net, sv_bus);
    cm_Y   = obj.cm_Y;
    cv_V0  = initial_voltage(obj, sct_eq.tab, sct_options.WarmStart);

    [cv_Vbus,flag,output,cm_Vhistory,rv_step] = run_method(cm_Y, sct_eq, cv_V0, sct_options);
    if flag == 1
        obj.cv_Vwarm = cv_Vbus;
    end

    % Vbus -> Ibus -> Pbus,Qbus
    cv_Ibus = cm_Y*cv_Vbus;
    cv_Sbus = cv_Vbus .* conj(cv_Ibus);

    % convert double->table
    tab_bus = array2table(...
        [angle(cv_Vbus),abs(cv_Vbus),real(cv_Sbus),imag(cv_Sbus),cv_Vbus,cv_Ibus], ...
        "VariableNames",["Varg","V","P","Q","Vphasor","Iphasor"],"RowNames",sv_bus);
    tab_branch = branch_flow(net, sv_bus, cv_Vbus);

    tab_violation = violation_table(net, tab_bus, tab_branch, sct_options.Tolerance);
    if flag ~= 1
        tab_violation = tab_violation([], :);     % no solution: nothing to check
    end

    result = ResultPF(net, obj, sct_options, flag, output, t0, ...
                             tab_bus, tab_branch, cm_Vhistory, rv_step, tab_violation);

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


function sct_eq = equations(obj, net, sv_bus)
% Power flow conditions and equations of net, from the cache when the revisions of net
% match (the cache and the warm start are reset when the buses differ or the topology
% was edited)
    a_Bus = net.a_Bus;
    l_same = obj.n_revTopology == net.n_revTopology && numel(obj.a_Bus) == numel(a_Bus) ...
             && all(cellfun(@(b1, b2) b1 == b2, obj.a_Bus, a_Bus));
    if ~l_same
        obj.a_Bus         = a_Bus;
        obj.n_revTopology = net.n_revTopology;
        obj.cv_Vwarm      = zeros(0,1);
        obj.n_revY        = NaN;
        obj.n_revPF       = NaN;
    end
    if obj.n_revY ~= net.n_revY
        tab_Ymat   = net.get_admittance_matrix;
        obj.cm_Y   = tab_Ymat{sv_bus, sv_bus};
        obj.n_revY = net.n_revY;
        obj.n_revPF = NaN;
    end
    if obj.n_revPF ~= net.n_revPF
        tab = tools.vcellfun(@(b) b.get_pf_condition, a_Bus);
        [f_res, f_jac, f_grad] = power_equation(obj.cm_Y, tab);
        obj.sct_equation = struct("tab", tab, "f_res", f_res, "f_jac", f_jac, "f_grad", f_grad);
        obj.n_revPF = net.n_revPF;
    end
    sct_eq = obj.sct_equation;
    sct_eq.tab.Properties.RowNames = sv_bus;     % a tag edit does not change the revisions
end


function cv_V0 = initial_voltage(obj, tab, l_warm)
% The kept solution (WarmStart), or the flat start: angle 0 and magnitude 1, with the set
% V at PV and slack buses and the set angle at the slack bus
    if l_warm && numel(obj.cv_Vwarm) == height(tab)
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
% Create the Method object of sct.Method from the settings and map its results to the bus
% voltages (cv_Vbus), flag, output, the voltage history and its steps.
    tab   = sct_eq.tab;
    r_tol = sct.Tolerance;
    n_max = sct.MaxIteration;

    % a bus without branches (not slack) has no determined voltage: no solution
    lv_isolated = ~any(cm_Y, 2) & tab.Type ~= "slack";
    if any(lv_isolated)
        cv_Vbus     = cv_V0;
        cm_Vhistory = cv_Vbus;
        rv_step     = 0;
        flag        = -2;
        output = struct("iterations", 0, "algorithm", sct.Method, "residual", NaN, "message", ...
            sprintf('✘ No power flow solution: the bus %s has no branch, so its voltage is not determined.', ...
                    join(string(tab.Properties.RowNames(lv_isolated)), ", ")));
        return
    end

    if sct.Method == "dynamic"
        tab.Varg0 = angle(cv_V0);     % initial voltages of MethodDynamic
        tab.V0    = abs(cv_V0);
        [cv_Vbus,flag,output,cm_Vhistory,rv_step] = MethodDynamic(Y=cm_Y, PFcondition=tab, Tolerance=r_tol).solve();
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
    switch sct.Method
        case "newton"
            [rm_x, flag, output, rm_hist, rv_step] = MethodNewtonRaphson(Fcn=f_res, Jac=f_jac, InitVal=rv_x0, ...
                ConvTol=r_tol, MaxIter=auto(n_max, 50), StepSize=sct.NewtonStepSize, Display=sct.Display).solve();
        case "gradient"
            r_alpha = sct.GradientStepSize;
            if r_alpha == 0
                r_alpha = 0.5/(max(abs(diag(cm_Y))) * max([tab.V; 1], [], "omitnan")^2);
            end
            [rm_xp, flag, output, rm_hist, rv_step] = MethodGradient(Fcn=f_grad, InitVal=rv_xp0, ...
                StepSize=r_alpha, ConvTol=r_tol, MaxIter=auto(n_max, 1e6), Display=sct.Display).solve();
            n_bus       = height(tab);            % [theta; V] -> complex voltages
            cv_Vbus     = rm_xp(n_bus+1:end) .* exp(1j*rm_xp(1:n_bus));
            cm_Vhistory = rm_hist(n_bus+1:end,:) .* exp(1j*rm_hist(1:n_bus,:));
            return
        case "levenberg-marquardt"
            [rm_x, flag, output, rm_hist, rv_step] = MethodLevenbergMarquardt(Fcn=f_res, Jac=f_jac, InitVal=rv_x0, ...
                ConvTol=r_tol, MaxIter=auto(n_max, 100), Display=sct.Display).solve();
        case "fsolve"
            [rm_x, flag, output, rm_hist, rv_step] = MethodFsolve(Fcn=f_res, Jac=f_jac, InitVal=rv_x0, ...
                ConvTol=r_tol, MaxIter=auto(n_max, 400), MaxFunEvals=sct.FsolveMaxFunEvals, Display=sct.Display, ...
                UseParallel=sct.FsolveUseParallel, Feature='Method="fsolve" of the power flow').solve();
    end
    cv_Vbus     = rm_x(1:2:end) + 1j*rm_x(2:2:end);
    cm_Vhistory = rm_hist(1:2:end,:) + 1j*rm_hist(2:2:end,:);
end


function n = auto(n, n_auto)
% MaxIteration 0 is the automatic value of the method
    if n == 0
        n = n_auto;
    end
end
