function sct_ode = reduce(sct_dae, iv_algebraic)
% Eliminate the algebraic variables of a linear DAE.
%
% The DAE E dx/dt = A x + B u, y = C x + D u has dynamic variables d and algebraic
% variables a (E is zero on their rows and columns). The algebraic equations
% 0 = A_ad x_d + A_aa x_a + B_a u give x_a = -A_aa \ (A_ad x_d + B_a u), and the reduced model is
%
% ```
% E_dd dx_d/dt = (A_dd - A_da A_aa^-1 A_ad) x_d + (B_d - A_da A_aa^-1 B_a) u
%            y = (C_d  - C_a  A_aa^-1 A_ad) x_d + (D   - C_a  A_aa^-1 B_a) u
% ```
%
% with the names of the dynamic variables, the inputs and the outputs. For the network
% (get_sys with Type "ODE", ResultLIN.get_ss("ODE")) the algebraic variables are the bus
% voltages, and A_aa is the current balance with respect to them (Avv). A model without
% algebraic variables is returned as it is. An A_aa with a reciprocal condition number
% below 1e-14 stops with GUILDA:SolverLIN:SingularAvv, naming the algebraic variables it
% does not determine.
%
% <@Examples>
% ```matlab
% res  = net.get_sys(Type="DAE");
% sct  = res.get_ss("DAE", Coordinate="Vre&Vim", Format="struct");
% sODE = SolverLIN.reduce(sct);             % = res.get_ss("ODE", Format="struct")
% ```
%
% See also PowerSystemModel.get_sys, ResultLIN.get_ss
    arguments (Input)
        sct_dae (1,1) struct            % DAE: fields A, B, C, D, E, StateName, InputName, OutputName.
        iv_algebraic (:,1) double = algebraic_rows(sct_dae.E)   % Positions of the algebraic variables in StateName. Default: the rows and columns where E is zero.
    end
    arguments (Output)
        sct_ode struct                  % Reduced model: fields A, B, C, D, E, StateName, InputName, OutputName (string columns).
    end
    sct_ode = sct_dae;
    for s = ["StateName","InputName","OutputName"]
        sct_ode.(s) = reshape(string(sct_dae.(s)), [], 1);
    end
    if isempty(iv_algebraic)
        return
    end
    n  = size(sct_dae.A, 1);
    ia = reshape(iv_algebraic, 1, []);
    id = setdiff(1:n, ia);
    A = sct_dae.A;  B = sct_dae.B;  C = sct_dae.C;

    % An A_aa below this reciprocal condition number has no usable inverse (as in SolverLIN.solve)
    r_rcondMin = 1e-14;
    Aaa = A(ia, ia);
    r_rcond = rcond(Aaa);
    if ~(r_rcond >= r_rcondMin)
        sv_a = sct_ode.StateName(ia);
        error(msg("GUILDA:SolverLIN:SingularAvv", sprintf("%g", r_rcond), char(list_names(undetermined(Aaa, sv_a)))))
    end
    Mx = A(id, ia) / Aaa;
    My = C(:, ia) / Aaa;
    sct_ode.A = A(id, id) - Mx * A(ia, id);
    sct_ode.B = B(id, :)  - Mx * B(ia, :);
    sct_ode.C = C(:, id)  - My * A(ia, id);
    sct_ode.D = sct_dae.D - My * B(ia, :);
    sct_ode.E = sct_dae.E(id, id);
    sct_ode.StateName = sct_ode.StateName(id);
end


function iv = algebraic_rows(E)
% Variables whose row and column of E are zero
    iv = find(all(E == 0, 2) & all(E == 0, 1).');
end


function sv = undetermined(Aaa, sv_a)
% Algebraic variables in the null space of A_aa
    [~, S, W] = svd(Aaa);
    rv_s = diag(S);
    rv_w = vecnorm(W(:, rv_s <= max(rv_s(end), 1e-12*rv_s(1))), 2, 2);
    sv = sv_a(rv_w > 0.1*max(rv_w));
end


function str = list_names(sv)
% Names for a message, at most 8
    n = numel(sv);
    str = join(sv(1:min(n,8)), ", ");
    if n > 8
        str = str + sprintf(" and %d more", n-8);
    end
end
