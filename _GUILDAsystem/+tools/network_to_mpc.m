function mpc = network_to_mpc(net)
% <@Desc>
% Converts a PowerNetwork into a MATPOWER case struct (mpc, version 2) for optimal
% power flow, so that the same network can be solved by MATPOWER (runopf, rundcopf).
% MATPOWER itself is not needed for the conversion.
% Buses keep their order (bus i = net.a_Bus{i}); the slack bus (the first bus if none
% is set) is the reference bus. Loads (component.load.abstract) become the fixed
% demand of their bus, PD/QD = -(P,Q of tab_parameter.powerflow). Every other component
% is a generator with the limits of tab_parameter.operation and the polynomial cost of
% tab_parameter.OPF (c2 = HP/baseMVA^2, c1 = fP/baseMVA; Q costs as extra gencost rows
% when HQ or fQ is nonzero). The cost of loads is a constant in GUILDA and is dropped.
% Each branch is fitted to the MATPOWER branch model from its 2x2 admittance matrix
% (R, X, B, tap, shift); a shunt part that the model cannot hold is moved to the bus
% shunts GS/BS. Smax becomes RATE_A and Vargmax becomes ANGMIN/ANGMAX.
% Stops with GUILDA:network_to_mpc:Unsupported when the network uses something the
% MATPOWER model cannot express: a finite branch Imax, Pmax or Qmax, a load without
% fixed P and Q, or a branch admittance matrix that does not fit the branch model.
% mpc.bus_name, mpc.gen_name and mpc.branch_name hold the GUILDA tags.
% <@Role> Converter
% <@Summary> PowerNetwork -> MATPOWER case struct (mpc) for OPF.
% <@Signatures>
% [
%   "mpc = tools.network_to_mpc(net)"
% ]
% <@Parameters>
% [
%   {"Name": "net", "Type": "PowerNetwork", "Description": "Network to convert. It is only read.", "Required": true, "Default": "-"}
% ]
% <@Returns>
% [
%   {"Name": "mpc", "Type": "struct", "Description": "MATPOWER case (version 2): baseMVA, bus, gen, branch, gencost, plus bus_name, gen_name and branch_name."}
% ]
% <@Examples>
% [
%   "```matlab\nmpc = tools.network_to_mpc(network.IEEE14bus);\nr   = runopf(mpc, mpoption(\"verbose\",0,\"out.all\",0));   % needs MATPOWER\n```"
% ]
    base    = net.para_base.baseMVA;
    a_Bus   = net.a_Bus;
    n_bus   = numel(a_Bus);
    str_bus = string(a_Bus);
    unsupported = @(str) error("GUILDA:network_to_mpc:Unsupported", "network_to_mpc: %s", str);

    % ---- buses -----------------------------------------------------------------------
    rm_bus = zeros(n_bus, 13);
    rm_bus(:,1)  = (1:n_bus).';
    rm_bus(:,2)  = 1;                                      % PQ
    rm_bus(:,7)  = 1;                                      % area
    rm_bus(:,11) = 1;                                      % zone
    rm_gen  = zeros(0, 21);
    c_cost  = cell(0, 1);                                  % [HP, fP, HQ, fQ, startup, shutdown]
    str_gen = strings(0, 1);
    for i = 1:n_bus
        bus = a_Bus{i};
        pf  = bus.para_powerflow;
        ope = bus.para_operation;
        dyn = bus.para_dynamics;
        rm_bus(i, [5 6])   = [dyn.Gshunt, dyn.Bshunt] * base;
        rm_bus(i, [8 9])   = [pf.V0, pf.Varg0*180/pi];
        rm_bus(i, 10)      = ope.baseKV;
        rm_bus(i, [12 13]) = [ope.Vmax, ope.Vmin];

        for k = 1:numel(bus.a_Component)
            com = bus.a_Component{k};
            if isa(com, "component.load.abstract")
                PQ = com.tab_parameter.powerflow{1, ["P","Q"]};
                if any(isnan(PQ))
                    unsupported("load " + string(com) + " has no fixed P and Q (tab_parameter.powerflow).");
                end
                rm_bus(i, [3 4]) = rm_bus(i, [3 4]) - PQ * base;
                continue
            end
            opf = com.para_OPF;
            cop = com.para_operation;
            V_g = pf.V;
            if isnan(V_g); V_g = pf.V0; end
            r_gen = zeros(1, 21);
            r_gen(1:10) = [i, opf.P0*base, opf.Q0*base, cop.Qmax*base, cop.Qmin*base, ...
                           V_g, cop.baseMVA, 1, cop.Pmax*base, cop.Pmin*base];
            rm_gen  = [rm_gen; r_gen];                                          %#ok<AGROW>
            c_cost  = [c_cost; {[opf.HP, opf.fP, opf.HQ, opf.fQ, opf.startup, opf.shutdown]}]; %#ok<AGROW>
            str_gen = [str_gen; string(com)];                                   %#ok<AGROW>
            rm_bus(i, 2) = 2;                                                   % PV
        end
    end
    i_ref = find(cellfun(@(b) b.l_isSlack, a_Bus), 1);
    if isempty(i_ref); i_ref = 1; end
    rm_bus(i_ref, 2) = 3;
    if isnan(a_Bus{i_ref}.para_powerflow.Varg)
        rm_bus(i_ref, 9) = 0;
    else
        rm_bus(i_ref, 9) = a_Bus{i_ref}.para_powerflow.Varg*180/pi;
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
    str_branch = string(a_Branch(:));
    for k = 1:n_br
        br  = a_Branch{k};
        ope = br.para_operation;
        dyn = br.para_dynamics;
        [~, iv_bus] = ismember(string(br.a_Bus), str_bus);
        for str_lim = ["Imax","Pmax","Qmax"]
            if ~isnan(ope.(str_lim)) && ~isinf(ope.(str_lim))
                unsupported("branch " + string(br) + " has a finite " + str_lim + " (only Smax maps to RATE_A).");
            end
        end
        Y  = br.get_admittance_matrix();
        ys = 1/(dyn.R + 1j*dyn.X);
        if ~isfinite(ys) || Y(1,2) == 0 || Y(2,1) == 0
            unsupported("branch " + string(br) + " has a zero impedance or no coupling.");
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
            unsupported("the admittance matrix of branch " + string(br) + " does not fit the MATPOWER branch model.");
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
    mpc.bus_name    = cellstr(str_bus(:));
    mpc.gen_name    = cellstr(str_gen);
    mpc.branch_name = cellstr(str_branch);
end
