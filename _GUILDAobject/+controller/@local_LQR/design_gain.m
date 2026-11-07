function design_gain(obj, V, u)
% Design K at the equilibrium of the component; the caller builds the handles.
    arguments (Input)
        obj
        V  % [pu] Complex terminal voltage of the component at the equilibrium.
        u  % Equilibrium input of the component (in the order of its sv_u).
    end
    comp = obj.a_Component;
    x0 = comp.rv_Xequilibrium;
    I0 = comp.c_Iequilibrium;
    [~, iv_u] = ismember(obj.sv_y, comp.sv_u);

    % Design model: the component connected to the infinite bus V0 through the
    % admittance y = I*/(V* - V0), so that dI = y dV
    if abs(V - obj.V0) < 1e-9
        error(msg("GUILDA:local_LQR:DesignModel", obj.s_tag, sprintf("%g", obj.V0)))
    end
    y_inf = tools.complex2matrix(I0 / (V - obj.V0));
    sys   = comp.get_sys_alone(x0, [real(V); imag(V)], [real(I0); imag(I0)], u);
    [A, B, C, D, E] = deal(sys.A, sys.B, sys.C, sys.D, sys.E);   % struct of get_sys_alone
    Bv = B(:,1:2);   Bu = B(:,2+iv_u);
    Dv = D(:,1:2);   Du = D(:,2+iv_u);
    M  = y_inf - Dv;            % (y - Dv) dV = C dx + Du du
    A  = E \ (A + Bv * (M \ C));
    Bu = E \ (Bu + Bv * (M \ Du));
    obj.sys_design = ss(A, Bu, eye(size(A)), 0, ...
                        'StateName', cellstr(comp.sv_x), 'InputName', cellstr(obj.sv_y), 'OutputName', cellstr(comp.sv_x));

    nx = numel(x0);  nu = numel(iv_u);
    Qw = obj.Q;  if isempty(Qw); Qw = eye(nx); end
    Rw = obj.R;  if isempty(Rw); Rw = eye(nu); end
    if ~isequal(size(Qw), [nx nx]) || ~isequal(size(Rw), [nu nu])
        error(msg("GUILDA:local_LQR:WeightSize", obj.s_tag, string(nx), string(nx), join(comp.sv_x, ","), string(nu), string(nu), join(obj.sv_y, ",")))
    end
    obj.K = lqr(A, Bu, Qw, Rw);
    obj.r_designHz = obj.get_Hz();
end
