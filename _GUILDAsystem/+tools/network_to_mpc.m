function mpc = network_to_mpc(net)
% Convert a PowerNetwork to a MATPOWER case struct (mpc) for OPF.
%
% Converts a PowerNetwork into a MATPOWER case struct (mpc, version 2) for optimal
% power flow, so that the same network can be solved by MATPOWER (runopf, rundcopf).
% MATPOWER itself is not needed for the conversion.
% Buses keep their order (bus i = net.a_Bus{i}); the bus of tools.slack_bus_index (the
% first bus if no bus has a component) is the reference bus. Loads (component.load.abstract) become the fixed
% demand of their bus, PD/QD = -(P,Q of tab_parameter.powerflow). Every other component
% is a generator with the limits of tab_parameter.operation and the polynomial cost of
% tab_parameter.OPF (c2 = HP/baseMVA^2, c1 = fP/baseMVA; Q costs as extra gencost rows
% when HQ or fQ is nonzero). The cost of loads is a constant in GUILDA and is dropped.
% Each branch is fitted to the MATPOWER branch model from its 2x2 admittance matrix
% (R, X, B, tap, shift); a shunt part that the model cannot hold is moved to the bus
% shunts GS/BS. Smax becomes RATE_A and Vargmax becomes ANGMIN/ANGMAX.
% Stops with GUILDA:network_to_mpc:LoadNoPQ, BranchLimit, BranchNoImpedance or
% BranchAdmittance when the network uses something the
% MATPOWER model cannot express: a finite branch Imax, Pmax or Qmax, a load without
% fixed P and Q, or a branch admittance matrix that does not fit the branch model.
% mpc.bus_name, mpc.gen_name and mpc.branch_name hold the GUILDA tags.
%
% <@Examples>
% ```matlab
% mpc = tools.network_to_mpc(network.IEEE14bus);
% r   = runopf(mpc, mpoption("verbose",0,"out.all",0));   % needs MATPOWER
% ```
    arguments (Input)
        net % Network to convert. It is only read.
    end
    arguments (Output)
        mpc % MATPOWER case (version 2): baseMVA, bus, gen, branch, gencost, plus bus_name, gen_name and branch_name.
    end
    base    = net.a_Parameter{cellfun(@(p) p.s_tag=="base", net.a_Parameter)}.tab_parameter.baseMVA;
    a_Bus   = net.a_Bus;
    n_bus   = numel(a_Bus);
    sv_bus  = string(a_Bus);

    % ---- buses -----------------------------------------------------------------------
    rm_bus = zeros(n_bus, 13);
    rm_bus(:,1)  = (1:n_bus).';
    rm_bus(:,2)  = 1;                                      % PQ
    rm_bus(:,7)  = 1;                                      % area
    rm_bus(:,11) = 1;                                      % zone
    rm_gen  = zeros(0, 21);
    c_cost  = cell(0, 1);                                  % [HP, fP, HQ, fQ, startup, shutdown]
    sv_gen  = strings(0, 1);
    for i = 1:n_bus
        bus = a_Bus{i};
        pf  = bus.a_Parameter{cellfun(@(p) p.s_tag=="powerflow", bus.a_Parameter)}.tab_parameter;
        ope = bus.a_Parameter{cellfun(@(p) p.s_tag=="operation", bus.a_Parameter)}.tab_parameter;
        dyn = bus.a_Parameter{cellfun(@(p) p.s_tag=="dynamics", bus.a_Parameter)}.tab_parameter;
        rm_bus(i, [5 6])   = [dyn.Gshunt, dyn.Bshunt] * base;
        rm_bus(i, [8 9])   = [pf.V0, pf.Varg0*180/pi];
        rm_bus(i, 10)      = ope.baseKV;
        rm_bus(i, [12 13]) = [ope.Vmax, ope.Vmin];

        for k = 1:numel(bus.a_Component)
            com = bus.a_Component{k};
            if isa(com, "component.load.abstract")
                PQ = com.tab_parameter.powerflow{1, ["P","Q"]};
                if any(isnan(PQ))
                    error(msg("GUILDA:network_to_mpc:LoadNoPQ", string(com)));
                end
                rm_bus(i, [3 4]) = rm_bus(i, [3 4]) - PQ * base;
                continue
            end
            opf = com.a_Parameter{cellfun(@(p) p.s_tag=="OPF", com.a_Parameter)}.tab_parameter;
            cop = com.a_Parameter{cellfun(@(p) p.s_tag=="operation", com.a_Parameter)}.tab_parameter;
            V_g = pf.V;
            if isnan(V_g); V_g = pf.V0; end
            r_gen = zeros(1, 21);
            r_gen(1:10) = [i, opf.P0*base, opf.Q0*base, cop.Qmax*base, cop.Qmin*base, ...
                           V_g, cop.baseMVA, 1, cop.Pmax*base, cop.Pmin*base];
            rm_gen  = [rm_gen; r_gen];                                          %#ok<AGROW>
            c_cost  = [c_cost; {[opf.HP, opf.fP, opf.HQ, opf.fQ, opf.startup, opf.shutdown]}]; %#ok<AGROW>
            sv_gen  = [sv_gen; string(com)];                                   %#ok<AGROW>
            rm_bus(i, 2) = 2;                                                   % PV
        end
    end
    i_ref = tools.slack_bus_index(net);
    if isempty(i_ref); i_ref = 1; end
    rm_bus(i_ref, 2) = 3;
    if isnan(a_Bus{i_ref}.a_Parameter{cellfun(@(p) p.s_tag=="powerflow", a_Bus{i_ref}.a_Parameter)}.tab_parameter.Varg)
        rm_bus(i_ref, 9) = 0;
    else
        rm_bus(i_ref, 9) = a_Bus{i_ref}.a_Parameter{cellfun(@(p) p.s_tag=="powerflow", a_Bus{i_ref}.a_Parameter)}.tab_parameter.Varg*180/pi;
    end

    % ---- generator costs: polynomial, P rows then (if any) Q rows -------------------------
    rm_c = vertcat(c_cost{:});
    if isempty(rm_c); rm_c = zeros(0, 6); end
    n_gen = size(rm_gen, 1);
    rm_gencost = [2*ones(n_gen,1), rm_c(:,5:6), 3*ones(n_gen,1), rm_c(:,1)/base^2, rm_c(:,2)/base, zeros(n_gen,1)];
    if any(rm_c(:,3:4) ~= 0, "all")
        rm_gencost = [rm_gencost; 2*ones(n_gen,1), zeros(n_gen,2), 3*ones(n_gen,1), rm_c(:,3)/base^2, rm_c(:,4)/base, zeros(n_gen,1)];
    end

    % ---- branches: fit Y = [Yff Yft; Ytf Ytt] to the MATPOWER model --------------------
    %   Yff = (ys + jb/2)/t^2, Yft = -ys/(t e^{-jφ}), Ytf = -ys/(t e^{jφ}), Ytt = ys + jb/2
    a_Branch   = net.a_Branch;
    n_br       = numel(a_Branch);
    rm_branch  = zeros(n_br, 13);
    sv_branch  = string(a_Branch(:));
    for k = 1:n_br
        br  = a_Branch{k};
        ope = br.a_Parameter{cellfun(@(p) p.s_tag=="operation", br.a_Parameter)}.tab_parameter;
        dyn = br.a_Parameter{cellfun(@(p) p.s_tag=="dynamics", br.a_Parameter)}.tab_parameter;
        [~, iv_bus] = ismember(string(br.a_Bus), sv_bus);
        for s_lim = ["Imax","Pmax","Qmax"]
            if ~isnan(ope.(s_lim)) && ~isinf(ope.(s_lim))
                error(msg("GUILDA:network_to_mpc:BranchLimit", string(br), s_lim));
            end
        end
        Y  = br.get_admittance_matrix();
        ys = 1/(dyn.R + 1j*dyn.X);
        if ~isfinite(ys) || Y(1,2) == 0 || Y(2,1) == 0
            error(msg("GUILDA:network_to_mpc:BranchNoImpedance", string(br)));
        end
        phi = angle(Y(1,2)/Y(2,1))/2;
        t   = abs(ys/Y(1,2));
        r_f = Y(1,1) - ys/t^2;                      % shunt part at the from end
        r_t = Y(2,2) - ys;                          % shunt part at the to end
        if abs(r_f*t^2 - r_t) < 1e-12*max(1, abs(ys)) && abs(real(r_t)) < 1e-12*max(1, abs(ys))
            b = 2*imag(r_t);                        % line charging of the pi model
        else
            b = 0;                                  % asymmetric shunts: move them to the buses
            rm_bus(iv_bus(1), [5 6]) = rm_bus(iv_bus(1), [5 6]) + [real(r_f), imag(r_f)]*base;
            rm_bus(iv_bus(2), [5 6]) = rm_bus(iv_bus(2), [5 6]) + [real(r_t), imag(r_t)]*base;
        end
        % check the fit
        Y_fit = [(ys + 1j*b/2)/t^2, -ys/(t*exp(-1j*phi)); -ys/(t*exp(1j*phi)), ys + 1j*b/2];
        if b == 0
            Y_fit = Y_fit + diag([r_f, r_t]);
        end
        if norm(Y_fit - Y) > 1e-9*max(1, norm(Y))
            error(msg("GUILDA:network_to_mpc:BranchAdmittance", string(br)));
        end
        if abs(phi) < 1e-12
            phi = 0;
            if abs(t - 1) < 1e-12
                t = 0;                              % MATPOWER: 0 = transmission line
            end
        end
        Smax = ope.Smax*base;
        if isnan(Smax) || isinf(Smax); Smax = 0; end   % 0 = unlimited
        ang = ope.Vargmax*180/pi;
        if isnan(ang) || isinf(ang); ang = 360; end
        rm_branch(k,:) = [iv_bus(1), iv_bus(2), dyn.R, dyn.X, b, Smax, Smax, Smax, t, phi*180/pi, 1, -ang, ang];
    end

    mpc = struct();
    mpc.version     = '2';
    mpc.baseMVA     = base;
    mpc.bus         = rm_bus;
    mpc.gen         = rm_gen;
    mpc.branch      = rm_branch;
    mpc.gencost     = rm_gencost;
    mpc.bus_name    = cellstr(sv_bus(:));
    mpc.gen_name    = cellstr(sv_gen);
    mpc.branch_name = cellstr(sv_branch);
end
