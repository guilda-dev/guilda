function [result,flag,output] = solve(obj, net, s_options)
% Trace the PV curve with the given settings.
%
% Runs the continuation power flow of net with the effective settings s_options and
% returns the traced path as a CPFResult. The solver is only read: nothing is written
% back into it. The CPF working data of the models (bus.iv_CPFV, comp.iv_CPFX,
% comp.f_PQ2Bus) is rebuilt for this run. Called by net.calculate_continuation_powerflow;
% calling it directly is for advanced use.
% It stops with an error naming the remedy when the network has no equilibrium
% (run net.initialize), when the equilibrium is stale, or when LoadBus is empty or names
% a bus that is not in the network.
    arguments
        obj % Solver (net.solver_CPF).
        net % Network initialized by net.initialize.
        s_options (1,1) struct = obj.get_options() % Effective settings (output of get_options).
    end
    arguments (Output)
        result % lambda and bus voltages along the path, and the nose point.
        flag % True when the path passed the nose (lambda reached its maximum and decreased).
        output % Details: message, iterations, correctorIterations.
    end
    t0 = tic;
    check_network(net, s_options.LoadBus);

    useInt = s_options.UseInternalState;
    w      = build_layout(net, useInt);
    Ymat   = net.get_admittance_matrix.Variables;
    f_PF   = @(x) pf_equation(net, w, s_options.LoadBus, useInt, x, Ymat);

    % The corrector solves with this Newton-Raphson object; its numerical Jacobian of
    % f_PF is also used by the predictor.
    NRM = NewtonRaphsonMethod("NRMFcn", f_PF, "NRMJac", [], "NRMVal", 0);
    NRM.ConvTol = s_options.Tolerance;
    f_Jac = NRM.NRMJac;

    x_past    = [];
    x_current = [w.InitVal; s_options.InitialLambda];
    t_old     = [];

    sol      = x_current;
    sol_pred = nan(size(x_current));
    rv_N     = zeros(1,0);

    Iteration = 1;
    while Iteration <= s_options.MaxIterations

        [x_pred,t_old] = predict(f_Jac, s_options.StepSize, x_current, x_past, t_old);

        [x_current,x_past,N] = correct(NRM, f_PF, f_Jac, s_options.ArcLength, x_current, x_pred);

        sol_pred = [sol_pred,x_pred]; %#ok
        sol      = [sol,x_current];   %#ok
        rv_N     = [rv_N,N];          %#ok

        if s_options.Verbose
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

    result = CPFResult(net, obj, s_options, flag, output, t0, ...
                       string(net.a_Bus(:)), rv_lambda, cm_Vbus, rm_x, rm_xPrd);
end


function check_network(net, sv_load)
% Preconditions: an up-to-date equilibrium and load buses of this network
    for i = 1:numel(net.a_Bus)
        a_Comp = net.a_Bus{i}.a_Component;
        for j = 1:numel(a_Comp)
            if isempty(a_Comp{j}.c_Iequilibrium)
                error('GUILDA:ContinuationPowerFlow:NoEquilibrium', '%s', ...
                      msg('GUILDA:ContinuationPowerFlow:NoEquilibrium', char(string(a_Comp{j}))));
            end
        end
    end
    if net.l_staleEquilibrium
        error('GUILDA:ContinuationPowerFlow:StaleEquilibrium', '%s', ...
              msg('GUILDA:ContinuationPowerFlow:StaleEquilibrium'));
    end
    if isempty(sv_load)
        error('GUILDA:ContinuationPowerFlow:EmptyLoadBus', '%s', ...
              msg('GUILDA:ContinuationPowerFlow:EmptyLoadBus'));
    end
    sv_bus     = string(net.a_Bus(:));
    sv_unknown = sv_load(~ismember(sv_load, sv_bus));
    if ~isempty(sv_unknown)
        error('GUILDA:ContinuationPowerFlow:UnknownLoadBus', '%s', ...
              msg('GUILDA:ContinuationPowerFlow:UnknownLoadBus', char(join(sv_unknown, ", "))));
    end
end
