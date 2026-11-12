function [result, flag, output, sct_point] = solve_fixed_input(net, c_nv)
% Solve the equilibrium with the inputs of the components held (initialize, Method="FixedInput").
%
% Unknowns: the states x and the injected currents I of every component, the bus voltages
% V and the Pmech of the first generator of the slack bus. Equations: f_dx = 0 and
% f_I = I of every component, Kirchhoff's current law Y*V = sum(I) at every bus and the
% reference angle Im(V_slack) = 0. The inputs are the held rv_Uequilibrium. Local and
% global controllers are not in the equations: initialize sets their equilibria
% afterwards. The network is not changed here (except the slack bus that initialize
% selects before); sct_point holds the solution for the write-back.
%
% Options (Name-Value): Solver ("newton", "levenberg-marquardt" or "fsolve"; default
% "newton"), Tolerance and MaxIteration (default: the PowerFlowCalculation section of
% GUILDA.setting), Verbose and WarmStart (default: the PowerFlowCalculation section). WarmStart=true starts from the held equilibrium when every component holds
% one; otherwise, and for WarmStart=false, from a power flow (not written) and the
% get_equilibrium of each component.
    arguments (Input)
        net    % Network with a slack bus (initialize selects one when none is set).
        c_nv   % Name-Value options of initialize without Method.
    end
    arguments (Output)
        result     % ResultPF of the solution (s_solver "FixedInput").
        flag       % 1 converged, 0 MaxIteration reached, -2 diverged or no solution (the Method class).
        output     % Details of the Method class; output.message describes the outcome.
        sct_point  % Solution: cv_V (bus voltages), c_X, c_U, cv_I (per component, in sct_eq order), c_comp, iv_bus.
    end
    t0  = tic;
    sct = options(c_nv);
    eq  = equation_data(net);

    z0 = initial_point(net, eq, sct.WarmStart);
    f_F = @(z) residual(eq, z);
    f_J = @(z) residual_jacobian(eq, z);
    s_display = "none";
    if sct.Verbose
        s_display = "iter";
    end
    cfg = GUILDA.config("PowerFlowCalculation");
    switch sct.Solver
        case "newton"
            [z, flag, output] = MethodNewtonRaphson(Fcn=f_F, Jac=f_J, InitVal=z0, ConvTol=sct.Tolerance, ...
                MaxIter=auto(sct.MaxIteration, 50), StepSize=cfg.NewtonStepSize.Value, Display=s_display).solve();
        case "levenberg-marquardt"
            [z, flag, output] = MethodLevenbergMarquardt(Fcn=f_F, Jac=f_J, InitVal=z0, ConvTol=sct.Tolerance, ...
                MaxIter=auto(sct.MaxIteration, 100), Display=s_display).solve();
        case "fsolve"
            [z, flag, output] = MethodFsolve(Fcn=f_F, Jac=f_J, InitVal=z0, ConvTol=sct.Tolerance, ...
                MaxIter=auto(sct.MaxIteration, 400), MaxFunEvals=auto(cfg.FsolveMaxFunctionEvaluations.Value, 0), ...
                UseParallel=cfg.FsolveUseParallel.Value, Display=s_display, ...
                Feature='Method="FixedInput" of initialize').solve();
    end

    sct_point = split_point(eq, z);
    cv_V = sct_point.cv_V;
    cv_Ibus = zeros(eq.n_bus,1);
    for k = 1:eq.n_comp
        cv_Ibus(eq.iv_bus(k)) = cv_Ibus(eq.iv_bus(k)) + sct_point.cv_I(k);
    end
    tab_pf = powerflow_table(eq.sv_bus(:), cv_V, cv_Ibus);
    sct_solver = struct("solver", "FixedInput", "options", struct("Method", "FixedInput", "Solver", sct.Solver, ...
        "Tolerance", sct.Tolerance, "MaxIteration", sct.MaxIteration, "WarmStart", sct.WarmStart), ...
        "flag", flag, "output", output, "elapsed", toc(t0));
    result = ResultPF(tab_pf, eq.cm_Y, struct(net, false), sct_solver);
end


function sct = options(c_nv)
% Effective options: GUILDA.setting (PowerFlowCalculation) for Tolerance, MaxIteration,
% Verbose and WarmStart, "newton" for Solver; the Name-Value options override them
    cfg = GUILDA.config("PowerFlowCalculation");
    sct = struct("Solver", "newton", "Tolerance", cfg.Tolerance.Value, ...
                 "MaxIteration", cfg.MaxIteration.Value, "Verbose", logical(cfg.Verbose.Value), ...
                 "WarmStart", logical(cfg.WarmStart.Value));
    sct_map = struct("Solver", "Solver", "Tolerance", "Tolerance", "MaxIteration", "MaxIteration", ...
                     "Verbose", "Verbose", "WarmStart", "WarmStart");
    sct = tools.resolve_options(sct, sct_map, c_nv);
    sct.Solver = string(sct.Solver);
    if any(strcmpi(sct.Solver, ["gradient","dynamic"]))
        error(msg("GUILDA:PowerNetwork:InitializeFixedInputSolver", char(sct.Solver)))
    end
    c_check = namedargs2cell(sct);
    validate(c_check{:});
    sct.WarmStart = logical(sct.WarmStart);
    sct.Verbose   = logical(sct.Verbose);
end


function validate(sct)
% Value checks of the options
    arguments (Input)
        sct.Solver       (1,1) string  {mustBeMember(sct.Solver, ["newton","levenberg-marquardt","fsolve"])}
        sct.Tolerance    (1,1) double  {mustBePositive}
        sct.MaxIteration (1,1) double  {mustBeIntegerOrNaN}
        sct.Verbose      (1,1) logical
        sct.WarmStart    (1,1) logical
    end
end


function mustBeIntegerOrNaN(r)
% NaN (the automatic value) or a nonnegative integer
    if ~isnan(r)
        mustBeNonnegative(r)
        mustBeInteger(r)
    end
end


function eq = equation_data(net)
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
    i_slack = find(cellfun(@(b) b.l_isSlack, a_Bus), 1);
    k_slack = find(iv_bus == i_slack & cellfun(@(c) isa(c, "component.generator.abstract"), c_comp), 1);
    if isempty(k_slack)
        error(msg("GUILDA:PowerNetwork:InitializeNoSlackGenerator", char(sv_bus(i_slack))))
    end
    i_Pm = find(string(c_comp{k_slack}.sv_u) == "Pmech", 1);

    nv_x  = cellfun(@(c) numel(c.sv_x), c_comp);
    c_ix  = cell(n_comp,1);        % positions of x_k in z
    c_iI  = cell(n_comp,1);        % positions of [Ire; Iim] of component k in z
    p = 0;
    for k = 1:n_comp
        c_ix{k} = p + (1:nv_x(k))';  p = p + nv_x(k);
        c_iI{k} = p + (1:2)';        p = p + 2;
    end
    iv_V = p + (1:2*n_bus)';       % [Vre; Vim] of each bus
    p = p + 2*n_bus;
    i_zPm = p + 1;

    tab_Y = net.get_admittance_matrix;
    cm_Y  = tab_Y{sv_bus, sv_bus};
    % real form of Y for the interleaved [Vre; Vim] of the buses
    rm_Y = kron(sparse(real(cm_Y)), sparse([1 0; 0 1])) + kron(sparse(imag(cm_Y)), sparse([0 -1; 1 0]));

    c_U = cellfun(@(c) reshape(c.rv_Uequilibrium, [], 1), c_comp, "UniformOutput", false);
    eq = struct("c_comp", {c_comp}, "iv_bus", iv_bus, "n_comp", n_comp, "n_bus", n_bus, ...
                "sv_bus", sv_bus, "nv_x", nv_x, "c_ix", {c_ix}, "c_iI", {c_iI}, "iv_V", iv_V, ...
                "i_zPm", i_zPm, "n_z", i_zPm, "k_slack", k_slack, "i_Pm", i_Pm, ...
                "i_slack", i_slack, "cm_Y", cm_Y, "rm_Y", rm_Y, "c_U", {c_U});
end


function u = input_of(eq, k, z)
% Inputs of component k: the held ones, with the solved Pmech for the slack generator
    u = eq.c_U{k};
    if k == eq.k_slack
        u(eq.i_Pm) = z(eq.i_zPm);
    end
end


function F = residual(eq, z)
% Residuals: per component [f_dx; f_I - I], then Kirchhoff's current law, then Im(V_slack)
    F_comp = cell(eq.n_comp,1);
    rv_Isum = zeros(2*eq.n_bus,1);
    for k = 1:eq.n_comp
        comp = eq.c_comp{k};
        x = z(eq.c_ix{k});
        I = z(eq.c_iI{k});
        iv_Vk = eq.iv_V(2*eq.iv_bus(k) + (-1:0));
        V = z(iv_Vk);
        u = input_of(eq, k, z);
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
    n_row = eq.n_z;
    c_r = cell(eq.n_comp,1); c_c = c_r; c_v = c_r;
    i_row = 0;
    i_kcl = sum(eq.nv_x) + 2*eq.n_comp;          % rows before Kirchhoff's current law
    for k = 1:eq.n_comp
        comp = eq.c_comp{k};
        ix = eq.c_ix{k};
        iI = eq.c_iI{k};
        iv_Vk = eq.iv_V(2*eq.iv_bus(k) + (-1:0));
        x = z(ix); V = z(iv_Vk);
        u = input_of(eq, k, z);
        [Axx, Bxv, Bxu] = comp.f_JacobiDx(0, x, V, u);
        [Cix, Div, Diu] = comp.f_JacobiI(0, x, V, u);
        n_x = numel(ix);
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
        [c_r{k}, c_c{k}, c_v{k}] = blocks(c_blk);
        % Kirchhoff's current law: - I_k at its bus
        rows_kcl = i_kcl + 2*eq.iv_bus(k) + (-1:0)';
        c_r{k} = [c_r{k}; rows_kcl]; c_c{k} = [c_c{k}; iI]; c_v{k} = [c_v{k}; -1; -1];
    end
    [iv_r, iv_c, rv_v] = find(eq.rm_Y);
    J = sparse([vertcat(zeros(0,1), c_r{:}); i_kcl + iv_r; n_row], ...
               [vertcat(zeros(0,1), c_c{:}); eq.iv_V(iv_c); eq.iv_V(2*eq.i_slack)], ...
               [vertcat(zeros(0,1), c_v{:}); rv_v; 1], n_row, eq.n_z);
end


function [iv_r, iv_c, rv_v] = blocks(c_blk)
% Triplets of the dense blocks {rows, columns, values}
    c_r = cell(size(c_blk,1),1); c_c = c_r; c_v = c_r;
    for b = 1:size(c_blk,1)
        [rr, cc] = ndgrid(c_blk{b,1}, c_blk{b,2});
        M = full(c_blk{b,3});
        if isempty(rr)
            continue
        end
        c_r{b} = rr(:); c_c{b} = cc(:); c_v{b} = reshape(M, [], 1);
    end
    iv_r = vertcat(zeros(0,1), c_r{:}); iv_c = vertcat(zeros(0,1), c_c{:}); rv_v = vertcat(zeros(0,1), c_v{:});
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
        [res, flag, out] = net.calculate_powerflow(WarmStart=l_warm);
        if flag ~= 1
            error(msg("GUILDA:PowerNetwork:InitializeFixedInputFailed", ...
                      char("the power flow for the initial point did not converge: " + string(out.message))))
        end
        cv_V = res.tab_bus.Vphasor;
        c_PQ = component_power(net, res.tab_bus);
        for k = 1:eq.n_comp
            comp = eq.c_comp{k};
            c_V  = cv_V(eq.iv_bus(k));
            rr_PQ = c_PQ{k};
            c_I  = conj((rr_PQ(1) + 1j*rr_PQ(2)) / c_V);
            x = comp.get_equilibrium(c_V, c_I, rr_PQ(1), rr_PQ(2));
            z0(eq.c_ix{k}) = x;
            z0(eq.c_iI{k}) = [real(c_I); imag(c_I)];
        end
    end
    z0(eq.iv_V) = reshape([real(cv_V(:)), imag(cv_V(:))].', [], 1);
    % rotate so that the slack bus angle is 0 (the reference of FixedInput)
    th = angle(cv_V(eq.i_slack));
    z0 = rotate_point(eq, z0, -th);
    z0(eq.i_zPm) = eq.c_U{eq.k_slack}(eq.i_Pm);
end


function z = rotate_point(eq, z, th)
% Rotates the bus voltages, the currents and the rotor angles ("delta") by th
    R = [cos(th) -sin(th); sin(th) cos(th)];
    V = reshape(z(eq.iv_V), 2, []);
    z(eq.iv_V) = reshape(R*V, [], 1);
    for k = 1:eq.n_comp
        z(eq.c_iI{k}) = R*z(eq.c_iI{k});
        lv_delta = string(eq.c_comp{k}.sv_x) == "delta";
        ix = eq.c_ix{k};
        z(ix(lv_delta)) = z(ix(lv_delta)) + th;
    end
end


function c_PQ = component_power(net, tab_bus)
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
            rm(lv_nan,2) = (tab_bus.Q(i_bus) - sum(rm(~lv_nan,2))) / sum(lv_nan);
        end
        if bus.l_isSlack
            i_rest = find(cellfun(@(c) isa(c, "component.generator.abstract"), a_Comp), 1);
            if isempty(i_rest), i_rest = 1; end
            lv_other = (1:n)' ~= i_rest;
            rm(i_rest,1) = tab_bus.P(i_bus) - sum(rm(lv_other,1));
            if ~any(lv_nan)
                rm(i_rest,2) = tab_bus.Q(i_bus) - sum(rm(lv_other,2));
            end
        end
        c_PQ = [c_PQ; num2cell(rm, 2)]; %#ok<AGROW>
    end
end


function sct_point = split_point(eq, z)
% Bus voltages, and states, inputs and currents of the components of z
    rv_V = z(eq.iv_V);
    cv_V = rv_V(1:2:end) + 1j*rv_V(2:2:end);
    c_X = cell(eq.n_comp,1); c_U = c_X;
    cv_I = zeros(eq.n_comp,1);
    for k = 1:eq.n_comp
        c_X{k} = z(eq.c_ix{k});
        c_U{k} = input_of(eq, k, z);
        I = z(eq.c_iI{k});
        cv_I(k) = I(1) + 1j*I(2);
    end
    sct_point = struct("cv_V", cv_V, "c_X", {c_X}, "c_U", {c_U}, "cv_I", cv_I, ...
                       "c_comp", {eq.c_comp}, "iv_bus", eq.iv_bus);
end


function n = auto(n, n_auto)
% NaN is the automatic value of the setting (n_auto: the value given to the method)
    if isnan(n)
        n = n_auto;
    end
end
