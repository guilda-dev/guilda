function tab = get_lmp(obj)
% Return the locational marginal price of every bus and its components.
%
% The price LMP of bus i is the change of the optimal cost per unit of load at the bus,
% -lambda.Constraints.balancedP_<bus> (balancedP in "ELD"), in the unit of the multiplier:
% cost per pu of active power (the cost of tab_parameter.OPF per pu). It is split into
% three components, LMP = Energy + Congestion + Loss:
%
% - `Energy`: the price at the reference bus (options.ReferenceBus of the run; the first
%   bus when it is "none"), the same at every bus.
% - `Loss`: -Energy * dPloss/dP_i, the price of the change of the losses when bus i injects
%   one more unit and the reference bus one less. dPloss/dP_i is the loss sensitivity at the
%   solution, from the Jacobian of the power flow equations (bus admittance matrix of the
%   branches cm_Y and bus shunts of sct_network; the angle of the reference bus fixed, the
%   reactive injections held). It is 0 at the reference bus, and 0 in "DC OPF" and "ELD",
%   which have no losses.
% - `Congestion`: the rest, LMP - Energy - Loss, from the binding limits (branches,
%   voltages). It is 0 at every bus without binding limits in "DC OPF".
%
% The components depend on the choice of the reference bus; LMP does not. In "ELD" every
% bus has the same price. It reads only the stored result.
%
% <@Examples>
% ```matlab
% res = network.IEEE14bus().calculate_optimal_powerflow(Method="AC OPF");
% tab = res.get_lmp();
% tab{"B014", ["LMP","Energy","Congestion","Loss"]}
% ```
%
% See also ResultOPF.disp_summary, ResultOPF.disp_binding
    arguments (Input)
        obj
    end
    arguments (Output)
        tab  % Table: LMP, Energy, Congestion, Loss (cost per pu), one row per bus (row names = bus tags).
    end
    s_method = obj.options.Method;
    sct_con  = obj.lambda.Constraints;
    sv_bus   = string(obj.tab_bus.Properties.RowNames);
    n_bus    = numel(sv_bus);
    if s_method == "ELD"
        rv_lmp = -sct_con.balancedP * ones(n_bus, 1);
    else
        rv_lmp = -arrayfun(@(s) sct_con.("balancedP_" + s), sv_bus);
    end
    i_ref = find(sv_bus == obj.options.ReferenceBus, 1);
    if isempty(i_ref)
        i_ref = 1;
    end
    rv_energy = rv_lmp(i_ref) * ones(n_bus, 1);
    rv_loss   = zeros(n_bus, 1);

    if s_method == "AC OPF" && n_bus > 1
        % Bus admittance matrix of the snapshot: branches (cm_Y, ends "net.a_Bus{i}" or bus
        % structs) and shunts Gshunt + jBshunt
        a_bus  = obj.sct_network.a_Bus;
        sv_tag = string(cellfun(@(b) b.s_tag, a_bus, "UniformOutput", false));
        cm_Y   = diag(cellfun(@(b) b.tab_parameter.dynamics.Gshunt + 1j*b.tab_parameter.dynamics.Bshunt, a_bus(:)));
        im_end = branch_ends(obj.sct_network);
        for k = 1:numel(obj.sct_network.a_Branch)
            iv = im_end(k, :);
            cm_Y(iv, iv) = cm_Y(iv, iv) + obj.sct_network.a_Branch{k}.cm_Y;
        end
        [~, iv_row] = ismember(sv_bus, sv_tag);
        cm_Y = cm_Y(iv_row, iv_row);

        % dS/dVarg and dS/d|V| of the injections S = V.*conj(Y*V) (polar form)
        cv_V  = obj.tab_bus.V .* exp(1j*obj.tab_bus.Varg);
        cv_I  = cm_Y * cv_V;
        cm_dA = 1j * diag(cv_V) * conj(diag(cv_I) - cm_Y*diag(cv_V));
        cm_dM = diag(cv_V) * conj(cm_Y*diag(cv_V./abs(cv_V))) + conj(diag(cv_I))*diag(cv_V./abs(cv_V));
        % Ploss = sum of P; with the reference angle fixed and the injections [P (other
        % buses); Q (all buses)] as inputs, dPloss/d(inputs) = J.' \ dPloss/d[Varg; |V|]
        iv_n  = setdiff(1:n_bus, i_ref);
        cm_J  = [real(cm_dA(iv_n, iv_n)), real(cm_dM(iv_n, :)); imag(cm_dA(:, iv_n)), imag(cm_dM)];
        rv_g  = [sum(real(cm_dA(:, iv_n)), 1).'; sum(real(cm_dM), 1).'];
        rv_s  = cm_J.' \ rv_g;
        rv_lf = zeros(n_bus, 1);
        rv_lf(iv_n) = rv_s(1:numel(iv_n));
        rv_loss = -rv_energy .* rv_lf;
    end
    rv_cong = rv_lmp - rv_energy - rv_loss;
    tab = table(rv_lmp, rv_energy, rv_cong, rv_loss, ...
        'VariableNames', ["LMP","Energy","Congestion","Loss"], 'RowNames', sv_bus);
end
