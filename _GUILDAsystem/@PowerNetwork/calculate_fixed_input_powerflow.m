function [result, flag, output] = calculate_fixed_input_powerflow(obj, opt)
% Calculate the power flow with the inputs of the components held.
%
% Solves the equilibrium of the network with the inputs that the components hold
% (rv_Uequilibrium, edited with Component.set_input). The unknowns are the states x and
% the currents I of every component, the bus voltages V and the Pmech of the first
% generator of the slack bus, which balances the power. The equations are f_dx = 0 and
% f_I = I of every component, Kirchhoff's current law Y*V = sum(I) at every bus and the
% reference angle 0 at the slack bus. The V and Varg settings of the slack bus and the
% powerflow settings of the components are not used. Local and global controllers are not
% in the equations. net.initialize(Method="FixedInput") writes the solution and gives the
% controllers their equilibria.
%
% The network is not changed. The slack bus and the admittance matrix come from
% net.get_pf_condition: a network without a slack bus (l_isSlack) stops with
% GUILDA:PowerNetwork:NoSlackBus. Every component must hold its inputs
% (GUILDA:PowerNetwork:InitializeInputNotSet), and the slack bus needs a generator
% (GUILDA:PowerNetwork:InitializeNoSlackGenerator). A network split into islands has no
% unique solution, so the calculation does not converge (initialize names the islands in
% its error). The values of the options that are left out come from the
% PowerFlowCalculation section of GUILDA.setting. Options not listed below stop with the
% MATLAB error of an unknown name.
%
% Name-Value options:
%
% - `Format` — Form of the first output (flag and output stay the 2nd and 3rd outputs). Default: "GUILDAorigin".
%   - "V": complex bus voltages [pu], a column in net.a_Bus order.
%   - "powerflow(mat)": n-by-4 complex double, one row per bus (net.a_Bus order); columns V, I (complex phasors of the voltage and the current injection), P, Q (real injections into the network) [pu].
%   - "powerflow(tab)": the same as a table with the variables V, I, P, Q; row names = bus tags.
%   - "GUILDAorigin": a ResultPF whose solver is "FixedInput" (bus table, branch flows, violated operating limits, the disp_* methods and export).
% - `Solver` — Algorithm: "newton", "levenberg-marquardt" or "fsolve" ("gradient" and "dynamic" stop with GUILDA:PowerNetwork:InitializeFixedInputSolver). Default: "newton".
% - `Tolerance` — Largest residual of a converged solution. Default: GUILDA.setting (1e-8).
% - `MaxIteration` — Maximum number of iterations; NaN for the automatic value (50 "newton", 100 "levenberg-marquardt", 400 "fsolve"). Default: GUILDA.setting (NaN).
% - `Verbose` — Print the progress of each iteration. Default: GUILDA.setting (false).
% - `WarmStart` — true starts from the held equilibrium when every component holds one; false, or a component without one, from a power flow that is not written. Default: GUILDA.setting (true).
%
% output.tab_component is the solution of each component: one row per component (row
% names = component tags, bus by bus in net.a_Bus order) with the variables Bus (bus tag),
% X (states), U (inputs, with the solved Pmech of the slack generator) and I (current
% injection, complex phasor) [pu].
%
% <@Examples>
% ```matlab
% net = network.IEEE9bus();
% net.initialize();
% ld = net.a_Bus{5}.a_Component{1};
% ld.set_input(ld.rv_Uequilibrium/0.95);              % 5 % less load
% [res, flag, output] = net.calculate_fixed_input_powerflow();   % ResultPF
% res.tab_bus               % V, P, Q of each bus at the held inputs
% output.tab_component      % X, U, I of each component
% pf = net.calculate_fixed_input_powerflow(Format="powerflow(mat)", Solver="levenberg-marquardt");
% net.initialize(Method="FixedInput");                % write the solution
% ```
%
% See also PowerNetwork.initialize, PowerNetwork.calculate_powerflow, Component.set_input, ResultPF
%
% <@Group> Power flow
    arguments (Input)
        obj
        opt.Solver (1,1) string {mustBeMember(opt.Solver, ["newton","gradient","levenberg-marquardt","fsolve","dynamic"])} = "newton" % Algorithm: "newton", "levenberg-marquardt" or "fsolve".
        opt.Tolerance (1,1) double {mustBePositive} = GUILDA.config("PowerFlowCalculation", "Tolerance") % Largest residual of a converged solution.
        opt.MaxIteration (1,1) double {mustBeIntegerOrNaN} = GUILDA.config("PowerFlowCalculation", "MaxIteration") % Maximum number of iterations; NaN for the automatic value.
        opt.Verbose (1,1) logical = GUILDA.config("PowerFlowCalculation", "Verbose") % Print the progress of each iteration.
        opt.WarmStart (1,1) logical = GUILDA.config("PowerFlowCalculation", "WarmStart") % Start from the held equilibrium.
        opt.Format (1,1) string {mustBeMember(opt.Format, ["V","powerflow(mat)","powerflow(tab)","GUILDAorigin"])} = "GUILDAorigin" % Form of the first output.
    end
    arguments (Output)
        result   % Solution in the form of Format: a ResultPF (default), bus voltages, or an n-by-4 matrix or table of V, I, P, Q.
        flag     % 1 converged, 0 MaxIteration reached, -2 diverged or no solution (see the Method* classes).
        output   % Solver details; output.message describes the outcome, output.tab_component holds X, U, I of each component.
    end
    if any(opt.Solver == ["gradient","dynamic"])
        error(msg("GUILDA:PowerNetwork:InitializeFixedInputSolver", char(opt.Solver)))
    end
    sct_PFcondition = obj.get_pf_condition(Display=false);   % slack bus and Y

    %% Solve the equations of all components and buses for z = [x; I of each component; V; Pmech]
    t0  = tic;
    eq  = equation_data(obj, sct_PFcondition);
    z0  = initial_point(obj, eq, opt.WarmStart);
    f_F = @(z) residual(eq, z);
    f_J = @(z) residual_jacobian(eq, z);
    s_display = replace(string(opt.Verbose), ["true","false"], ["iter","none"]);
    cfg   = GUILDA.config("PowerFlowCalculation");
    n_max = opt.MaxIteration;   % NaN: the automatic value of the method
    switch opt.Solver
        case "newton"
            n_max(isnan(n_max)) = 50;
            [z, flag, output, rm_history] = MethodNewtonRaphson(Fcn=f_F, Jac=f_J, InitVal=z0, ConvTol=opt.Tolerance, ...
                MaxIter=n_max, StepSize=cfg.NewtonStepSize.Value, Display=s_display).solve();
        case "levenberg-marquardt"
            n_max(isnan(n_max)) = 100;
            [z, flag, output, rm_history] = MethodLevenbergMarquardt(Fcn=f_F, Jac=f_J, InitVal=z0, ConvTol=opt.Tolerance, ...
                MaxIter=n_max, Display=s_display).solve();
        case "fsolve"
            n_max(isnan(n_max)) = 400;
            n_fev = cfg.FsolveMaxFunctionEvaluations.Value;
            n_fev(isnan(n_fev)) = 0;
            [z, flag, output, rm_history] = MethodFsolve(Fcn=f_F, Jac=f_J, InitVal=z0, ConvTol=opt.Tolerance, ...
                MaxIter=n_max, MaxFunEvals=n_fev, UseParallel=cfg.FsolveUseParallel.Value, Display=s_display, ...
                Feature='Method="FixedInput" of initialize').solve();
    end
    r_elapsed = toc(t0);

    %% Per component values, and V, I, P, Q of each bus
    c_X  = cell(eq.n_comp,1);
    c_U  = c_X;
    cv_I = zeros(eq.n_comp,1);
    for k = 1:eq.n_comp
        c_X{k}  = z(eq.c_ix{k});
        c_U{k}  = input_of(eq, k, z);
        cv_I(k) = [1 1j]*z(eq.c_iI{k});
    end
    sv_comp = string(cellfun(@(c) char(c.s_tag), eq.c_comp, "UniformOutput", false));
    output.tab_component = table(eq.sv_bus(eq.iv_bus), c_X, c_U, cv_I, ...
        'VariableNames', ["Bus","X","U","I"], 'RowNames', sv_comp);

    rv_V = z(eq.iv_V);
    cv_V = rv_V(1:2:end) + 1j*rv_V(2:2:end);
    if opt.Format == "V"
        result = cv_V;
        return
    end
    cv_Ibus = accumarray(eq.iv_bus, cv_I, [eq.n_bus 1]);
    cv_S    = cv_V .* conj(cv_Ibus);
    if opt.Format == "powerflow(mat)"
        result = [cv_V, cv_Ibus, real(cv_S), imag(cv_S)];
        return
    end
    tab_pf = table(cv_V, cv_Ibus, real(cv_S), imag(cv_S), 'VariableNames', ["V","I","P","Q"], 'RowNames', eq.sv_bus);
    switch opt.Format
        case "powerflow(tab)"
            result = tab_pf;
        case "GUILDAorigin"
            cm_Vhistory = rm_history(eq.iv_V(1:2:end),:) + 1j*rm_history(eq.iv_V(2:2:end),:);
            sct_solver = struct("solver", "FixedInput", "options", opt, "flag", flag, "output", output, ...
                "elapsed", r_elapsed, "cm_Vhistory", cm_Vhistory, "rv_step", 0:size(rm_history,2)-1);
            result = ResultPF(tab_pf, eq.cm_Y, struct(obj, false), sct_solver);
    end
end


function eq = equation_data(net, sct_PFcondition)
% Components, their positions in z, the admittance matrix and the slack generator
    a_Bus  = net.a_Bus;
    n_bus  = numel(a_Bus);
    sv_bus = reshape(string(a_Bus), [], 1);
    c_comp = cell(0,1);
    iv_bus = zeros(0,1);
    for i_bus = 1:n_bus
        a_Comp = a_Bus{i_bus}.a_Component;
        c_comp = [c_comp; a_Comp(:)]; %#ok<AGROW>
        iv_bus = [iv_bus; repmat(i_bus, numel(a_Comp), 1)]; %#ok<AGROW>
    end
    n_comp = numel(c_comp);

    % every component holds its inputs
    lv_unset = cellfun(@(c) numel(c.rv_Uequilibrium) ~= numel(c.sv_u), c_comp);
    if any(lv_unset)
        sv = string(cellfun(@(c) char(c.s_tag), c_comp(lv_unset), "UniformOutput", false));
        error(msg("GUILDA:PowerNetwork:InitializeInputNotSet", char(join(sv(1:min(end,5)), ", "))))
    end

    % the first generator of the slack bus balances the power with its Pmech
    i_slack = find(sct_PFcondition.Bus.Type == "slack", 1);
    k_slack = find(iv_bus == i_slack & cellfun(@(c) isa(c, "component.generator.abstract"), c_comp), 1);
    if isempty(k_slack)
        error(msg("GUILDA:PowerNetwork:InitializeNoSlackGenerator", char(sv_bus(i_slack))))
    end
    i_Pm = find(string(c_comp{k_slack}.sv_u) == "Pmech", 1);

    nv_x = cellfun(@(c) numel(c.sv_x), c_comp);
    c_ix = cell(n_comp,1);        % positions of x_k in z
    c_iI = cell(n_comp,1);        % positions of [Ire; Iim] of component k in z
    p = 0;
    for k = 1:n_comp
        c_ix{k} = p + (1:nv_x(k))';  p = p + nv_x(k);
        c_iI{k} = p + (1:2)';        p = p + 2;
    end
    iv_V  = p + (1:2*n_bus)';     % [Vre; Vim] of each bus
    i_zPm = p + 2*n_bus + 1;

    cm_Y  = sct_PFcondition.Y{sv_bus, sv_bus};
    % real form of Y for the interleaved [Vre; Vim] of the buses
    rm_Y = kron(sparse(real(cm_Y)), sparse([1 0; 0 1])) + kron(sparse(imag(cm_Y)), sparse([0 -1; 1 0]));

    c_U = cellfun(@(c) reshape(c.rv_Uequilibrium, [], 1), c_comp, "UniformOutput", false);
    eq = struct("c_comp", {c_comp}, "iv_bus", iv_bus, "n_comp", n_comp, "n_bus", n_bus, ...
                "sv_bus", sv_bus, "nv_x", nv_x, "c_ix", {c_ix}, "c_iI", {c_iI}, "iv_V", iv_V, ...
                "i_zPm", i_zPm, "n_z", i_zPm, "k_slack", k_slack, "i_Pm", i_Pm, ...
                "i_slack", i_slack, "cm_Y", cm_Y, "rm_Y", rm_Y, "c_U", {c_U});
end


function z0 = initial_point(net, eq, l_warm)
% The held equilibrium when WarmStart and every component holds one; otherwise a power
% flow (not written) and get_equilibrium of each component
    z0 = zeros(eq.n_z,1);
    l_held = l_warm && all(cellfun(@(c) numel(c.rv_Xequilibrium) == numel(c.sv_x) ...
                                     && ~isempty(c.c_Iequilibrium), eq.c_comp));
    if l_held
        cv_V = cellfun(@(b) b.c_Vequilibrium, net.a_Bus(:));
        for k = 1:eq.n_comp
            comp = eq.c_comp{k};
            z0(eq.c_ix{k}) = comp.rv_Xequilibrium;
            z0(eq.c_iI{k}) = [real(comp.c_Iequilibrium); imag(comp.c_Iequilibrium)];
        end
    else
        [rm_pf, flag, out] = net.calculate_powerflow(WarmStart=l_warm, Format="powerflow(mat)");
        if flag ~= 1
            error(msg("GUILDA:PowerNetwork:InitializeFixedInputFailed", ...
                      char("the power flow for the initial point did not converge: " + string(out.message))))
        end
        cv_V = rm_pf(:,1);
        c_PQ = component_power(net, real(rm_pf(:,3:4)));
        for k = 1:eq.n_comp
            c_V   = cv_V(eq.iv_bus(k));
            rr_PQ = c_PQ{k};
            c_I   = conj((rr_PQ(1) + 1j*rr_PQ(2)) / c_V);
            z0(eq.c_ix{k}) = eq.c_comp{k}.get_equilibrium(c_V, c_I, rr_PQ(1), rr_PQ(2));
            z0(eq.c_iI{k}) = [real(c_I); imag(c_I)];
        end
    end
    z0(eq.iv_V) = reshape([real(cv_V(:)), imag(cv_V(:))].', [], 1);

    % rotate the voltages, the currents and the rotor angles ("delta") so that the slack
    % bus angle is 0 (the reference of the equations)
    th = -angle(cv_V(eq.i_slack));
    R  = [cos(th) -sin(th); sin(th) cos(th)];
    z0(eq.iv_V) = reshape(R*reshape(z0(eq.iv_V), 2, []), [], 1);
    for k = 1:eq.n_comp
        z0(eq.c_iI{k}) = R*z0(eq.c_iI{k});
        ix = eq.c_ix{k};
        lv_delta = string(eq.c_comp{k}.sv_x) == "delta";
        z0(ix(lv_delta)) = z0(ix(lv_delta)) + th;
    end
    z0(eq.i_zPm) = eq.c_U{eq.k_slack}(eq.i_Pm);
end


function c_PQ = component_power(net, rm_PQbus)
% [P Q] of each component at the power flow solution (initial point only): the settings,
% the rest of the bus to the components with Q = NaN (equally) and the rest of P at the
% slack bus to its first generator
    c_PQ = cell(0,1);
    for i_bus = 1:numel(net.a_Bus)
        bus = net.a_Bus{i_bus};
        a_Comp = bus.a_Component;
        n = numel(a_Comp);
        if n == 0
            continue
        end
        rm = zeros(n,2);
        for k = 1:n
            tp = a_Comp{k}.tab_parameter.powerflow;
            rm(k,:) = [tp.P, tp.Q];
        end
        lv_nan = isnan(rm(:,2));
        if any(lv_nan)
            rm(lv_nan,2) = (rm_PQbus(i_bus,2) - sum(rm(~lv_nan,2))) / sum(lv_nan);
        end
        if bus.l_isSlack
            i_rest = find(cellfun(@(c) isa(c, "component.generator.abstract"), a_Comp), 1);
            if isempty(i_rest), i_rest = 1; end
            lv_other = (1:n)' ~= i_rest;
            rm(i_rest,1) = rm_PQbus(i_bus,1) - sum(rm(lv_other,1));
            if ~any(lv_nan)
                rm(i_rest,2) = rm_PQbus(i_bus,2) - sum(rm(lv_other,2));
            end
        end
        c_PQ = [c_PQ; num2cell(rm, 2)]; %#ok<AGROW>
    end
end


function F = residual(eq, z)
% Residuals: per component [f_dx; f_I - I], then Kirchhoff's current law, then Im(V_slack)
    F_comp  = cell(eq.n_comp,1);
    rv_Isum = zeros(2*eq.n_bus,1);
    for k = 1:eq.n_comp
        comp  = eq.c_comp{k};
        I     = z(eq.c_iI{k});
        iv_Vk = eq.iv_V(2*eq.iv_bus(k) + (-1:0));
        x = z(eq.c_ix{k});  V = z(iv_Vk);  u = input_of(eq, k, z);
        dx  = comp.f_dx(0, x, V, u);
        c_I = comp.f_I(0, x, V, u);
        F_comp{k} = [reshape(dx, [], 1); real(c_I) - I(1); imag(c_I) - I(2)];
        rv_Isum(iv_Vk - eq.iv_V(1) + 1) = rv_Isum(iv_Vk - eq.iv_V(1) + 1) + I;
    end
    rv_V = z(eq.iv_V);
    F = [vertcat(zeros(0,1), F_comp{:}); eq.rm_Y*rv_V - rv_Isum; rv_V(2*eq.i_slack)];
end


function J = residual_jacobian(eq, z)
% Jacobian of residual from the Jacobians of the components (f_JacobiDx, f_JacobiI)
    c_r = cell(eq.n_comp,1); c_c = c_r; c_v = c_r;
    i_row = 0;
    i_kcl = sum(eq.nv_x) + 2*eq.n_comp;          % rows before Kirchhoff's current law
    for k = 1:eq.n_comp
        comp  = eq.c_comp{k};
        ix    = eq.c_ix{k};
        iI    = eq.c_iI{k};
        iv_Vk = eq.iv_V(2*eq.iv_bus(k) + (-1:0));
        x = z(ix);  V = z(iv_Vk);  u = input_of(eq, k, z);
        [Axx, Bxv, Bxu] = comp.f_JacobiDx(0, x, V, u);
        [Cix, Div, Diu] = comp.f_JacobiI(0, x, V, u);
        n_x    = numel(ix);
        rows_x = i_row + (1:n_x)';
        rows_I = i_row + n_x + (1:2)';
        i_row  = i_row + n_x + 2;
        c_blk = {rows_x, ix,    Axx;
                 rows_x, iv_Vk, Bxv;
                 rows_I, ix,    Cix;
                 rows_I, iI,    -eye(2);
                 rows_I, iv_Vk, Div};
        if k == eq.k_slack
            c_blk = [c_blk; {rows_x, eq.i_zPm, Bxu(:,eq.i_Pm); rows_I, eq.i_zPm, Diu(:,eq.i_Pm)}]; %#ok<AGROW>
        end
        % triplets of the dense blocks {rows, columns, values}
        for b = 1:size(c_blk,1)
            [rr, cc] = ndgrid(c_blk{b,1}, c_blk{b,2});
            if isempty(rr)
                c_blk(b,:) = {zeros(0,1)};
                continue
            end
            c_blk{b,1} = rr(:);  c_blk{b,2} = cc(:);  c_blk{b,3} = reshape(full(c_blk{b,3}), [], 1);
        end
        % Kirchhoff's current law: - I_k at its bus
        c_r{k} = [vertcat(zeros(0,1), c_blk{:,1}); i_kcl + 2*eq.iv_bus(k) + (-1:0)'];
        c_c{k} = [vertcat(zeros(0,1), c_blk{:,2}); iI];
        c_v{k} = [vertcat(zeros(0,1), c_blk{:,3}); -1; -1];
    end
    [iv_r, iv_c, rv_v] = find(eq.rm_Y);
    J = sparse([vertcat(zeros(0,1), c_r{:}); i_kcl + iv_r; eq.n_z], ...
               [vertcat(zeros(0,1), c_c{:}); eq.iv_V(iv_c); eq.iv_V(2*eq.i_slack)], ...
               [vertcat(zeros(0,1), c_v{:}); rv_v; 1], eq.n_z, eq.n_z);
end


function u = input_of(eq, k, z)
% Inputs of component k: the held ones, with the solved Pmech for the slack generator
    u = eq.c_U{k};
    if k == eq.k_slack
        u(eq.i_Pm) = z(eq.i_zPm);
    end
end
