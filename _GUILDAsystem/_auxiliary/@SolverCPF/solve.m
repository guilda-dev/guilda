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
% a bus that is not in the network. With options.Limits, the PV buses switched to PQ and
% the limit that ended the path are in result.tab_switch and result.tab_stop.
    arguments (Input)
        obj % Solver (net.solver_CPF).
        net % Network initialized by net.initialize.
        sct_options (1,1) struct = obj.get_options() % Effective settings (output of get_options).
    end
    arguments (Output)
        result % lambda and bus voltages along the path, and the nose point.
        flag % True when the path passed the nose (lambda reached its maximum and decreased) or stopped at a "V" or "S" limit after at least one step.
        output % Details: message, iterations, correctorIterations.
    end
    t0 = tic;
    check_network(net, sct_options.LoadBus);

    useInt = sct_options.UseInternalState;
    sv_lim = limit_kinds(sct_options.Limits);
    if useInt && ismember("Q", sv_lim)
        error(msg("GUILDA:SolverCPF:LimitsInternalState"));
    end
    w      = build_layout(net, useInt);
    Ymat   = net.get_admittance_matrix.Variables;
    f_PF   = @(x) pf_equation(net, w, sct_options.LoadBus, useInt, x, Ymat);

    % The corrector solves with this Newton-Raphson object (Tolerance: largest residual;
    % CorrectorMaxIteration, CorrectorStepSize and Increment of GUILDA.setting); the
    % numerical Jacobian of f_PF with its Increment is also used by the predictor.
    NRM = MethodNewtonRaphson(Fcn=f_PF, ConvTol=sct_options.Tolerance, ...
        MaxIter=GUILDA.config("ContinuationPowerFlow","CorrectorMaxIteration"), ...
        StepSize=GUILDA.config("ContinuationPowerFlow","CorrectorStepSize"), ...
        Increment=GUILDA.config("ContinuationPowerFlow","Increment"));
    r_inc = NRM.Increment;
    f_Jac = @(x) tools.fd_jacobian(f_PF, x, Step=r_inc);

    % Operating limits of Limits (see limit_set). A crossing found after a step is moved
    % back to the interpolated point where the limit is met: "Q" switches the bus to PQ
    % there, "V" and "S" end the path there.
    lim = limit_set(net, sv_lim, w, sct_options.LoadBus);
    st  = struct("w", w, "f_PF", f_PF, "f_Jac", f_Jac, ...
                 "lv_active", true(numel(lim.rv_bound),1), "c_switch", {cell(0,5)}, "c_stop", {cell(0,6)});
    f_eq = @(st) equations(st, net, useInt, sct_options.LoadBus, Ymat, r_inc);
    r_tol = sct_options.Tolerance;

    x_past    = [];
    x_current = [w.InitVal; sct_options.InitialLambda];
    t_old     = [];
    r_h       = sct_options.StepSize;

    if ~isempty(lim.rv_bound)
        % Limits violated at the starting point: "Q" switches there, "V" and "S" stop there
        [st, x_current] = settle(st, f_eq, NRM, lim, x_current, Ymat, r_tol, 1);
    end
    sol      = to_full(st.w, x_current);
    sol_pred = nan(size(sol));
    rv_N     = zeros(1,0);
    g_current = limit_values(lim, st.w, sol, Ymat);

    Iteration = 1;
    while Iteration <= sct_options.MaxIterations && isempty(st.c_stop)

        [x_pred,t_old] = predict(st.f_Jac, r_h, x_current, x_past, t_old);
        r_h = sct_options.StepSize;

        [x_next,x_last,N] = correct(NRM, st.f_PF, st.f_Jac, sct_options.ArcLength, x_current, x_pred);
        xf_pred = to_full(st.w, x_pred);

        [i_row, r_t] = find_limit(lim, st.lv_active, g_current, ...
                                  limit_values(lim, st.w, to_full(st.w, x_next), Ymat), r_tol);
        if i_row == 0
            x_past = x_last;
        else
            x_star = x_last + r_t * (x_next - x_last);
            if lim.sv_kind(i_row) == "Q"
                % Restart the predictor at the switch: tangent of the new equations, oriented
                % along the last step and as long as the arc length
                xf_dir = to_full(st.w, x_next) - to_full(st.w, x_last);
                [st, x_star, N2] = switch_pq(st, f_eq, NRM, lim, i_row, to_full(st.w, x_star), Ymat, r_tol, numel(rv_N) + 2);
                [st, x_star] = settle(st, f_eq, NRM, lim, x_star, Ymat, r_tol, numel(rv_N) + 2);   % "V", "S" beyond after the switch
                t_old  = from_full(st.w, xf_dir) / norm(from_full(st.w, xf_dir));
                x_past = [];
                r_h    = sqrt(sct_options.ArcLength);
            else
                [x_star, N2] = correct_at(NRM, st.f_PF, st.f_Jac, x_star, x_last);
                st = add_stop(st, lim, i_row, x_star(end), numel(rv_N) + 2);
            end
            x_next = x_star;
            N      = N + N2;
        end
        x_current = x_next;

        sol_pred = [sol_pred,xf_pred];                  %#ok
        sol      = [sol,to_full(st.w, x_current)];      %#ok
        rv_N     = [rv_N,N];                            %#ok
        g_current = limit_values(lim, st.w, sol(:,end), Ymat);

        if sct_options.Verbose
            fprintf("CPF step %4d: lambda = %.6g\n", Iteration, x_current(end));
            if i_row > 0
                fprintf("  limit %s of %s %s (%.6g) reached\n", lim.sv_limit(i_row), ...
                        lim.sv_class(i_row), lim.sv_object(i_row), lim.rv_bound(i_row));
            end
        end

        if x_current(end) < 0
            break;
        end
        Iteration = Iteration + 1;
    end

    rm_x    = sol;
    rm_xPrd = sol_pred;
    rv_lambda = rm_x(end,:);
    cm_Vbus   = rm_x(w.rv_BusVi(1:2:end),:) .* exp(1j*rm_x(w.rv_BusVi(2:2:end),:));

    tab_switch = cell2table(st.c_switch, 'VariableNames', ["lambda","Step","Bus","Limit","Bound"]);
    tab_stop   = cell2table(st.c_stop,   'VariableNames', ["lambda","Step","Class","Object","Limit","Bound"]);
    tab_switch = convertvars(tab_switch, ["Bus","Limit"], "string");
    tab_stop   = convertvars(tab_stop, ["Class","Object","Limit"], "string");

    [r_lambdaMax, i_nose] = max(rv_lambda);
    l_stop = ~isempty(st.c_stop);
    flag = i_nose > 1 && i_nose < numel(rv_lambda) || l_stop && numel(rv_lambda) > 1;
    output = struct();
    output.iterations          = numel(rv_lambda) - 1;
    output.correctorIterations = rv_N;
    if l_stop
        output.message = sprintf("The path stopped at the operating limit %s = %.6g of %s %s at lambda = %.6g (step %d of %d).", ...
                                 tab_stop.Limit, tab_stop.Bound, lower(tab_stop.Class), tab_stop.Object, ...
                                 tab_stop.lambda, tab_stop.Step - 1, output.iterations);
    elseif flag
        output.message = sprintf("The path passed the nose at lambda = %.6g (step %d of %d).", ...
                                 r_lambdaMax, i_nose - 1, output.iterations);
    else
        output.message = sprintf("The path did not pass the nose within %d steps (largest lambda = %.6g). " + ...
                                 "Increase MaxIteration or StepSize.", output.iterations, r_lambdaMax);
    end

    result = ResultCPF(net, obj, sct_options, flag, output, t0, ...
                       string(net.a_Bus(:)), rv_lambda, cm_Vbus, rm_x, rm_xPrd, tab_switch, tab_stop);
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


function sv = limit_kinds(sv_limits)
% Kinds of operating limits of the option Limits, in the order "Q", "V", "S"
    sv = ["Q","V","S"];
    if isequal(sv_limits, "none")
        sv = strings(1,0);
    elseif ~isequal(sv_limits, "all")
        sv = sv(ismember(sv, sv_limits));
    end
end


function xf = to_full(w, x)
% Full variable vector [|V|; angle V of each bus (and states); lambda] of x = [unknowns; lambda]
    xf = [w.rm_BusEM * x(1:end-1) + w.CONSTANT; x(end)];
end


function x = from_full(w, xf)
% Unknowns of the layout w (and lambda) taken from a full variable vector
    x = [w.rm_BusEM.' * xf(1:end-1); xf(end)];
end


function st = equations(st, net, useInt, sv_load, Ymat, r_inc)
% Layout and equations after a switch to PQ (st.w.rv_Qfix holds the fixed Q)
    rv_Qfix = st.w.rv_Qfix;
    st.w    = build_layout(net, useInt, ~isnan(rv_Qfix));
    st.w.rv_Qfix = rv_Qfix;
    w       = st.w;
    st.f_PF  = @(x) pf_equation(net, w, sv_load, useInt, x, Ymat);
    f_PF     = st.f_PF;
    st.f_Jac = @(x) tools.fd_jacobian(f_PF, x, Step=r_inc);
end


function [i_row, r_t] = find_limit(lim, lv_active, g0, g1, r_tol)
% First limit that the step from values g0 to g1 crosses (beyond it by more than r_tol at
% g1), and the fraction r_t of the step where it is met (linear interpolation); 0 if none
    i_row = 0;
    r_t   = 1;
    iv = find(lv_active & lim.rv_sign .* (g1 - lim.rv_bound) > r_tol);
    if isempty(iv)
        return
    end
    rv_t = (lim.rv_bound(iv) - g0(iv)) ./ (g1(iv) - g0(iv));
    rv_t(~isfinite(rv_t)) = 0;
    [r_t, k] = min(min(max(rv_t, 0), 1));
    i_row = iv(k);
end


function [st, x] = settle(st, f_eq, NRM, lim, x, Ymat, r_tol, i_step)
% Limits violated at the point x (not moved by a step): "Q" switches the buses at once,
% then "V" or "S" stops there
    xf = to_full(st.w, x);
    g  = limit_values(lim, st.w, xf, Ymat);
    iv = find(st.lv_active & lim.sv_kind == "Q" & lim.rv_sign .* (g - lim.rv_bound) > r_tol);
    if ~isempty(iv)
        [st, x] = switch_pq(st, f_eq, NRM, lim, iv, xf, Ymat, r_tol, i_step);
        g = limit_values(lim, st.w, to_full(st.w, x), Ymat);
    end
    iv = find(st.lv_active & lim.sv_kind ~= "Q" & lim.rv_sign .* (g - lim.rv_bound) > r_tol, 1);
    if ~isempty(iv)
        st = add_stop(st, lim, iv, x(end), i_step);
    end
end


function [st, x, N] = switch_pq(st, f_eq, NRM, lim, iv_row, xf, Ymat, r_tol, i_step)
% Switches the buses of the "Q" rows iv_row to PQ with Q fixed at the bound, corrects the
% full point xf at its lambda, and repeats while other generators are beyond their limits;
% records the switches at path index i_step
    N = 0;
    while ~isempty(iv_row)
        for i_row = reshape(iv_row, 1, [])
            i_bus = lim.iv_object(i_row);
            st.w.rv_Qfix(i_bus) = lim.rv_bound(i_row);
            st.lv_active(lim.sv_kind == "Q" & lim.iv_object == i_bus) = false;
            st.c_switch(end+1,:) = {xf(end), i_step, lim.sv_object(i_row), lim.sv_limit(i_row), lim.rv_bound(i_row)};
        end
        st = f_eq(st);
        [x, N_i] = correct_at(NRM, st.f_PF, st.f_Jac, from_full(st.w, xf), []);
        N  = N + N_i;
        xf = to_full(st.w, x);
        g  = limit_values(lim, st.w, xf, Ymat);
        iv_row = find(st.lv_active & lim.sv_kind == "Q" & lim.rv_sign .* (g - lim.rv_bound) > r_tol);
    end
    st.c_switch(cell2mat(st.c_switch(:,2)) == i_step, 1) = {x(end)};   % lambda of the corrected point
end


function st = add_stop(st, lim, i_row, r_lambda, i_step)
% Records the limit where the path stops
    st.c_stop(end+1,:) = {r_lambda, i_step, lim.sv_class(i_row), lim.sv_object(i_row), lim.sv_limit(i_row), lim.rv_bound(i_row)};
end
