function [f_res, f_jac, f_grad] = power_equation(cm_Y, tab_PFcondition)
% Power equations of the buses and their Jacobian, shared by the power flow methods.
%
% The unknowns x are the bus voltages in real form [Vre_1; Vim_1; Vre_2; Vim_2; ...].
% Each bus gives two residuals (calculated - specified), in the order of x:
% PQ bus [P; Q], PV bus [P; |V|], slack bus [angle [rad]; |V|]. P and Q are the injected
% powers [pu] computed from x with cm_Y.
% For "gradient", f_grad works on the polar form xp = [theta; V] (n_bus each) and returns
% the step direction d = [dP; dQ./V] and the mismatch r = [dP; dQ] (dP = P_set - P is 0
% at the slack bus, dQ is 0 at the slack and PV buses); d and r are NaN when a V <= 0.
    arguments (Input)
        cm_Y            (:,:) double  % [pu] Bus admittance matrix (complex, in the bus order of tab_PFcondition).
        tab_PFcondition       table   % Power flow conditions of the buses (rows of get_pf_condition).
    end
    arguments (Output)
        f_res  (1,1) function_handle  % Residual F(x) (2*n_bus x 1).
        f_jac  (1,1) function_handle  % Jacobian dF/dx (sparse, 2*n_bus x 2*n_bus).
        f_grad (1,1) function_handle  % [d, r] = f_grad(xp) of "gradient".
    end
    n_bus = height(tab_PFcondition);
    sv_type  = tab_PFcondition.Type;
    lv_PV    = sv_type == "PV";
    lv_slack = sv_type == "slack";
    lv_PQ    = ~lv_PV & ~lv_slack;

    % specified values: first and second residual of each bus
    rv_set1 = zeros(n_bus,1);
    rv_set2 = zeros(n_bus,1);
    rv_set1(~lv_slack) = tab_PFcondition.P(~lv_slack);
    rv_set1( lv_slack) = tab_PFcondition.Varg(lv_slack);
    rv_set2( lv_PQ)    = tab_PFcondition.Q(lv_PQ);
    rv_set2(~lv_PQ)    = tab_PFcondition.V(~lv_PQ);

    rm_Y = sparse(tools.complex2matrix(cm_Y));
    iv_r = reshape([1;1;2;2] + 2*(0:n_bus-1), [], 1);   % rows and columns of the 2x2 bus blocks
    iv_c = reshape([1;2;1;2] + 2*(0:n_bus-1), [], 1);

    f_res = @residual;
    f_jac = @power_jacobian;
    f_grad = @direction;

    function F = residual(x)
        [e, f, a, b] = split(x);
        g1 = e.*a + f.*b;                                     % P
        g2 = f.*a - e.*b;                                     % Q
        g2(~lv_PQ) = hypot(e(~lv_PQ), f(~lv_PQ));             % |V|
        r1 = g1 - rv_set1;
        r1(lv_slack) = angle(complex(e(lv_slack), f(lv_slack)) .* exp(-1j*rv_set1(lv_slack)));
        F = reshape([r1, g2 - rv_set2].', [], 1);
    end

    function J = power_jacobian(x)
        [e, f, a, b] = split(x);
        Vm  = hypot(e, f);
        % 2x2 block of each bus as [d1/de, d1/df, d2/de, d2/df] (dF/dV and dF/dI)
        mV = [a, b, -b, a];                                   % PQ: d[P;Q]/dV
        mI = [e, f, f, -e];                                   % PQ: d[P;Q]/dI
        mV(lv_PV,[3 4]) = [e(lv_PV), f(lv_PV)] ./ Vm(lv_PV);  % PV: d|V|/dV
        mI(lv_PV,[3 4]) = 0;
        mV(lv_slack,[1 2]) = [-f(lv_slack), e(lv_slack)] ./ Vm(lv_slack).^2;
        mV(lv_slack,[3 4]) = [e(lv_slack), f(lv_slack)] ./ Vm(lv_slack);
        mI(lv_slack,:)  = 0;
        JV = sparse(iv_r, iv_c, reshape(mV.', [], 1), 2*n_bus, 2*n_bus);
        JI = sparse(iv_r, iv_c, reshape(mI.', [], 1), 2*n_bus, 2*n_bus);
        J  = JV + JI*rm_Y;
    end

    function [d, r] = direction(xp)
        T = xp(1:n_bus);
        V = xp(n_bus+1:end);
        if any(V <= 0)
            d = nan(2*n_bus, 1);  r = d;
            return
        end
        rm_F = reshape(residual(reshape([V.*cos(T), V.*sin(T)].', [], 1)), 2, []);
        dP = -rm_F(1,:).';  dP(lv_slack) = 0;
        dQ = -rm_F(2,:).';  dQ(~lv_PQ)   = 0;
        d = [dP; dQ./V];
        r = [dP; dQ];
    end

    function [e, f, a, b] = split(x)
        rm_V = reshape(x, 2, []);
        rm_I = reshape(rm_Y*x, 2, []);
        e = rm_V(1,:).';  f = rm_V(2,:).';
        a = rm_I(1,:).';  b = rm_I(2,:).';
    end
end
