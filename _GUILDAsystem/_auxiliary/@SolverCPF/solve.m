function [result,flag,output] = solve(obj, net, sct_options)
% Trace the PV curve with the given settings.
%
% Runs the continuation power flow of net with the effective settings sct_options and
% returns the traced path as a ResultCPF. The solver is only read: nothing is written
% back into it. The CPF working data of the models (bus.iv_CPFV, comp.iv_CPFX,
% comp.f_PQ2Bus) is rebuilt for this run. Called by net.calculate_continuation_powerflow;
% calling it directly is for advanced use.
% It stops with an error naming the remedy when the network has no equilibrium
% (run net.initialize), when the equilibrium is stale, or when LoadBus is empty or names
% a bus that is not in the network.
    arguments (Input)
        obj % Solver (net.solver_CPF).
        net % Network initialized by net.initialize.
        sct_options (1,1) struct = obj.get_options() % Effective settings (output of get_options).
    end
    arguments (Output)
        result % lambda and bus voltages along the path, and the nose point.
        flag % True when the path passed the nose (lambda reached its maximum and decreased).
        output % Details: message, iterations, correctorIterations.
    end
    t0 = tic;
    check_network(net, sct_options.LoadBus);

    useInt = sct_options.UseInternalState;
    w      = build_layout(net, useInt);
    Ymat   = net.get_admittance_matrix.Variables;
    f_PF   = @(x) pf_equation(net, w, sct_options.LoadBus, useInt, x, Ymat);

    % The corrector solves with this Newton-Raphson object; its numerical Jacobian of
    % f_PF is also used by the predictor.
    NRM = NewtonRaphsonMethod("NRMFcn", f_PF, "NRMJac", [], "NRMVal", 0);
    NRM.ConvTol = sct_options.Tolerance;
    f_Jac = NRM.NRMJac;

    x_past    = [];
    x_current = [w.InitVal; sct_options.InitialLambda];
    t_old     = [];

    sol      = x_current;
    sol_pred = nan(size(x_current));
    rv_N     = zeros(1,0);

    Iteration = 1;
    while Iteration <= sct_options.MaxIterations

        [x_pred,t_old] = predict(f_Jac, sct_options.StepSize, x_current, x_past, t_old);

        [x_current,x_past,N] = correct(NRM, f_PF, f_Jac, sct_options.ArcLength, x_current, x_pred);

        sol_pred = [sol_pred,x_pred]; %#ok
        sol      = [sol,x_current];   %#ok
        rv_N     = [rv_N,N];          %#ok

        if sct_options.Verbose
            fprintf("CPF step %4d: lambda = %.6g\n", Iteration, x_current(end));
        end

        if x_current(end) < 0
            break;
        end
        Iteration = Iteration + 1;
    end

    rm_x    = [w.rm_BusEM * sol(1:end-1,:)      + w.CONSTANT; sol(end,:)     ];
    rm_xPrd = [w.rm_BusEM * sol_pred(1:end-1,:) + w.CONSTANT; sol_pred(end,:)];
    rv_lambda = rm_x(end,:);
    cm_Vbus   = rm_x(w.rv_BusVi(1:2:end),:) .* exp(1j*rm_x(w.rv_BusVi(2:2:end),:));

    [r_lambdaMax, i_nose] = max(rv_lambda);
    flag = i_nose > 1 && i_nose < numel(rv_lambda);
    output = struct();
    output.iterations          = numel(rv_lambda) - 1;
    output.correctorIterations = rv_N;
    if flag
        output.message = sprintf("The path passed the nose at lambda = %.6g (step %d of %d).", ...
                                 r_lambdaMax, i_nose - 1, output.iterations);
    else
        output.message = sprintf("The path did not pass the nose within %d steps (largest lambda = %.6g). " + ...
                                 "Increase MaxIteration or StepSize.", output.iterations, r_lambdaMax);
    end

    result = ResultCPF(net, obj, sct_options, flag, output, t0, ...
                       string(net.a_Bus(:)), rv_lambda, cm_Vbus, rm_x, rm_xPrd);
end


function check_network(net, sv_load)
% Preconditions: an equilibrium, up-to-date stale tags (powerflow and odefcn of the
% network, equilibrium and odefcn of the components) and load buses of this network
    sv = [net.sct_stale.powerflow; net.sct_stale.odefcn];
    for i = 1:numel(net.a_Bus)
        a_Comp = net.a_Bus{i}.a_Component;
        for j = 1:numel(a_Comp)
            if isempty(a_Comp{j}.c_Iequilibrium)
                error(msg("GUILDA:SolverCPF:NoEquilibrium", char(string(a_Comp{j}))));
            end
            sv = [sv; a_Comp{j}.sct_stale.equilibrium; a_Comp{j}.sct_stale.odefcn]; %#ok<AGROW>
        end
    end
    if ~isempty(sv)
        sv = unique(sv, "stable");
        s_reason = join(sv(1:min(end,3)), "; ");
        if numel(sv) > 3
            s_reason = s_reason + "; ...";
        end
        error(msg("GUILDA:SolverCPF:Stale", char(net.s_tag), char(s_reason)))
    end
    if isempty(sv_load)
        error(msg("GUILDA:SolverCPF:EmptyLoadBus"));
    end
    sv_bus     = string(net.a_Bus(:));
    sv_unknown = sv_load(~ismember(sv_load, sv_bus));
    if ~isempty(sv_unknown)
        error(msg("GUILDA:SolverCPF:UnknownLoadBus", char(join(sv_unknown, ", "))));
    end
end
