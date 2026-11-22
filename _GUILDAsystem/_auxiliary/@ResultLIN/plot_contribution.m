function sct_graph = plot_contribution(obj, opt)
% Plot the contribution of each element on the network diagram: its share in the damping of a mode, or the stiffness of its port.
%
% The DAE (get_ss("DAE") in the Port of the result) is the sum of the parts of its
% elements, A = sum of A_e (get_contribution: the components, the local and global
% controllers, the branches and the buses). plot_contribution draws, from these parts, one
% of three quantities (Quantity) in the figure of plot_participation: the eigenvalue map
% (Type "DAE") on the left, the diagram of sct_network on the right and a table below it.
%
% "damping" (default): the share of each element in the eigenvalue of the mode picked
% (click an eigenvalue on the map; mode 1, the first row of get_mode(Type="DAE"), first).
% With the right and left eigenvectors v, w of the DAE (get_eigenvector("DAE"),
% w' E v = 1),
%
% ```
% lambda_e = w' A_e v / (w' E v),    sum over the elements of lambda_e = lambda
% ```
%
% Re(lambda_e) is the part of the element in the decay rate of the mode: a negative
% value adds damping, a positive one removes it (Im(lambda_e), its part in the frequency
% [rad/s], is in the table only). The colors are Re(lambda_e) on a colorbar symmetric
% about 0: each component with the shares of its local controllers added (its label
% "Re (with controllers)" says so), each branch, and each bus by the share of the bus
% itself (its shunt). Global controllers are in the table, which lists Re and Im of every
% element (their sum lambda in its title) until a bus is clicked, then the elements at
% that bus.
%
% "synchronizing" and "voltage" need no mode. Each component, with its local controllers,
% is reduced to the port of its bus: the part A_e of the component and its controllers
% (get_contribution), restricted to their states x and the two variables v of the bus,
% with x eliminated by the rule of get_reduced_matrix (State "settled", default: every x,
% K = Jvv - Jvx / Jxx * Jxv, the states follow (E dx/dt = 0), the steady-state stiffness;
% "fixed": the dynamic states held at the point, only the algebraic ones eliminated, the
% instantaneous stiffness). K is 2 x 2 over the rows of the balance of the bus and the bus
% variables of the Port:
%
% - "synchronizing" = K(1,1) = dP/dtheta, the synchronizing power coefficient of the
%   device: the increase of the power it absorbs from the bus (its injection decreasing)
%   when the bus angle advances. Positive values pull the bus angle back. For a
%   generator, State "fixed" (the rotor angle held) gives the classical coefficient
%   E' V cos(delta - theta) / X'.
% - "voltage" = K(2,2): dQ/drho = V dQ/dV in Port "PQ" (d(Q/V)/dV in Port "PI"), the
%   reactive stiffness of the device: how much reactive power it gives when the voltage
%   of its bus falls. Positive values support the voltage.
%
% Port "I" has no angle and voltage variables and stops with GUILDA:ResultLIN:PortQuantity.
% The color of a component is its value and that of a bus the sum over its components
% (NaN without one). Each branch is colored by its own coupling, -(K_ij + K_ji)/2 of its
% part over the variables of its two buses (theta for "synchronizing", the second variable
% for "voltage"): the synchronizing (or reactive) coupling it adds between them. The table
% lists the 2 x 2 K of each component (K11 K12; K21 K22). The eigenvalue map is shown for
% reference; a click on it changes nothing.
%
% A result with several sections switches them through the playback bar (the colors and
% the table follow), starting at Index. Another layer than the network stops with
% GUILDA:ResultLIN:NetworkOnly.
%
% It returns a struct with Eigenvalue (GraphChart), Diagram (GraphNetDiagram) and Table
% (uitable).
%
% On a contribution result (sv_target nonempty, see get_contribution) the numbers are of
% the part alone and have no meaning for the whole system.
%
% <@Examples>
% ```matlab
% res = net.get_sys();
% sct = res.plot_contribution();                            % click a mode: which elements damp it
% sct = res.plot_contribution(Quantity="synchronizing", State="fixed");
% sct = res.plot_contribution(Quantity="voltage");          % steady-state reactive stiffness
% ```
%
% See also ResultLIN.get_contribution, ResultLIN.get_reduced_matrix, ResultLIN.plot_participation
    arguments (Input)
        obj
        opt.Quantity (1,1) string {mustBeMember(opt.Quantity, ["damping","synchronizing","voltage"])} = "damping"  % Quantity: "damping" (share in an eigenvalue), "synchronizing" (dP/dtheta of the ports) or "voltage" (dQ/drho of the ports).
        opt.State (1,1) string {mustBeMember(opt.State, ["settled","fixed"])} = "settled"  % Ports of "synchronizing" and "voltage": states "settled" (eliminated) or "fixed" (held at the point).
        opt.Index (1,1) double {mustBeInteger, mustBePositive} = obj.Index  % Section shown first (1 ... numel(rv_t)); res.Index when omitted.
        opt.Parent = []                                        % Container (figure, uifigure, uipanel, uitab, uigridlayout) to draw in; [] for a new figure.
    end
    arguments (Output)
        sct_graph struct  % Eigenvalue (GraphChart), Diagram (GraphNetDiagram) and Table (uitable).
    end
    if ~(isfield(obj.output, "s_layer") && obj.output.s_layer == "PowerNetwork")
        error(msg("GUILDA:ResultLIN:NetworkOnly", "plot_contribution"))
    end
    n_t = numel(obj.rv_t);
    if opt.Index > n_t
        error(msg("GUILDA:ResultLIN:IndexRange", string(n_t)))
    end
    c_opt = struct("Type", "DAE", "Index", opt.Index, "Parent", opt.Parent);
    if opt.Quantity == "damping"
        sct_spec = struct("s_name", "Share in the damping", "s_colorbar", "Re(λ_e)", ...
            "s_explain", ["Color: Re \lambda_e, the element's part in the decay rate"; "Negative: adds damping; \Sigma\lambda_e = \lambda"], ...
            "s_limit", "symmetric", "sv_column", ["Re", "Im"], "l_tableAll", true, "l_cartesian", true, ...
            "fcn_section", @(sv_bus, sv_comp, sv_branch) share_sections(obj, sv_bus, sv_comp, sv_branch));
        sct_graph = mode_diagram(obj, c_opt, sct_spec);
        return
    end

    s_port = "PQ";
    if isfield(obj.options, "Port")
        s_port = obj.options.Port;
    end
    if s_port == "I"
        error(msg("GUILDA:ResultLIN:PortQuantity", opt.Quantity))
    end
    i_var = 1 + (opt.Quantity == "voltage");
    sv_name = ["∂P/∂θ", "∂Q/∂ρ"];
    if s_port == "PI"
        sv_name(2) = "∂(Q/V)/∂V";
    end
    s_quantity = opt.Quantity + " " + sv_name(i_var) + " (" + opt.State + ", Port " + s_port + ")";
    s_q = opt.Quantity;
    s_state = opt.State;
    sv_explain = ["Color: ∂P/∂θ of the devices at the bus (positive: pulls the angle back)", ...
                  "Color: " + sv_name(2) + " of the devices at the bus (positive: supports the voltage)"];
    sct_spec = struct("s_name", "Port stiffness", "s_colorbar", sv_name(i_var), "s_limit", "symmetric", ...
        "s_explain", sv_explain(i_var), ...
        "sv_column", ["K11", "K12", "K21", "K22"], "l_tableAll", true, "l_modeFree", true, "s_quantity", s_quantity, ...
        "fcn_section", @(sv_bus, sv_comp, sv_branch) port_sections(obj, s_q, s_state, sv_bus, sv_comp, sv_branch));
    sct_graph = mode_diagram(obj, c_opt, sct_spec);
end


function sct_sec = share_sections(obj, sv_bus, sv_comp, sv_branch)
% Data of each section for mode_diagram: the share w' A_e v / (w' E v) of each element in each mode
    arguments (Input)
        obj ResultLIN           % The result.
        sv_bus (:,1) string     % Bus tags of the diagram.
        sv_comp (:,1) string    % Component tags of the diagram.
        sv_branch (:,1) string  % Branch tags of the diagram.
    end
    arguments (Output)
        sct_sec struct          % Data of each section (see mode_diagram).
    end
    sct_part = obj.get_participation(Type="DAE", Index="all");
    sct_vec  = obj.get_eigenvector("DAE", Index="all");
    c_sec = cell(1, numel(sct_part));
    for s = 1:numel(sct_part)
        V = sct_vec(s);
        cv_lambda = sct_part(s).cv_lambda;
        n_m = numel(cv_lambda);
        iv_col = zeros(1, n_m);
        for m = 1:n_m
            [~, iv_col(m)] = min(abs(V.cv_lambda - cv_lambda(m)));
        end
        W = V.cm_left(:, iv_col);
        R = V.cm_right(:, iv_col);
        E = full(obj.get_ss("DAE", Index=s, Format="struct").E);
        rv_wEv = sum(conj(W) .* (E * R), 1);
        [sv_elem, sv_elemBus, iv_comp] = element_places(obj, s, sv_bus, sv_comp);
        cm_share = complex(zeros(numel(sv_elem), n_m));
        for e = 1:numel(sv_elem)
            A_e = part_matrix(obj, s, sv_elem(e));
            cm_share(e, :) = sum(conj(W) .* (A_e * R), 1) ./ rv_wEv;
        end
        rm_bus = NaN(numel(sv_bus), n_m);
        [lv, iv] = ismember(sv_bus, sv_elem);
        rm_bus(lv, :) = real(cm_share(iv(lv), :));
        rm_comp = NaN(numel(sv_comp), n_m);
        sm_comp = strings(numel(sv_comp), n_m);
        for i = 1:numel(sv_comp)
            lv_c = iv_comp == i;
            if any(lv_c)
                rm_comp(i, :) = real(sum(cm_share(lv_c, :), 1));
                s_with = "";
                if nnz(lv_c) > 1
                    s_with = " (with controllers)";
                end
                sm_comp(i, :) = compose("%.3g", rm_comp(i, :)) + s_with;
            end
        end
        rm_branch = NaN(numel(sv_branch), n_m);
        [lv, iv] = ismember(sv_branch, sv_elem);
        rm_branch(lv, :) = real(cm_share(iv(lv), :));
        c_sec{s} = struct("cv_lambda", cv_lambda, "rm_bus", rm_bus, "sm_busLabel", strings(0, 0), ...
            "rm_comp", rm_comp, "rm_branch", rm_branch, "sv_row", sv_elem, "sv_rowBus", sv_elemBus, ...
            "rm_row", cm_share, "sm_compLabel", sm_comp);
    end
    sct_sec = [c_sec{:}];
end


function sct_sec = port_sections(obj, s_q, s_state, sv_bus, sv_comp, sv_branch)
% Data of each section for mode_diagram: the 2 x 2 port stiffness K of each component (with its local controllers)
    arguments (Input)
        obj ResultLIN           % The result.
        s_q (1,1) string        % "synchronizing" or "voltage".
        s_state (1,1) string    % "settled" or "fixed".
        sv_bus (:,1) string     % Bus tags of the diagram.
        sv_comp (:,1) string    % Component tags of the diagram.
        sv_branch (:,1) string  % Branch tags of the diagram.
    end
    arguments (Output)
        sct_sec struct          % Data of each section (see mode_diagram).
    end
    i_var = 1 + (s_q == "voltage");
    tab = obj.tab_variable;
    c_sec = cell(1, numel(obj.rv_t));
    for s = 1:numel(obj.rv_t)
        sys = obj.get_ss("DAE", Index=s, Format="struct");
        E = full(sys.E);
        [sv_bv, sv_bvBus, iv_kind] = bus_variables(obj, s);
        [sv_elem, ~, iv_comp] = element_places(obj, s, sv_bus, sv_comp);
        rm_K = NaN(numel(sv_comp), 4);
        sv_compBus = strings(numel(sv_comp), 1);
        for i = 1:numel(sv_comp)
            sv_own = sv_elem(iv_comp == i);
            sv_b = sv_bus(arrayfun(@(b) startsWith(sv_comp(i), b), sv_bus));
            [~, ib] = max(strlength(sv_b));
            sv_compBus(i) = sv_b(ib);
            J = part_matrix(obj, s, sv_own);
            ix = find(ismember(sys.StateName, tab.Label(ismember(tab.Owner, sv_own) & tab.Kind == "x")));
            iv = [find(sys.StateName == sv_bv(sv_bvBus == sv_compBus(i) & iv_kind == 1)); ...
                  find(sys.StateName == sv_bv(sv_bvBus == sv_compBus(i) & iv_kind == 2))];
            if s_state == "fixed"
                ix = ix(~any(E(ix, :) ~= 0, 2));        % only the algebraic states are eliminated
            end
            K = J(iv, iv);
            if ~isempty(ix)
                K = K - J(iv, ix) / J(ix, ix) * J(ix, iv);
            end
            rm_K(i, :) = [K(1,1), K(1,2), K(2,1), K(2,2)];
        end
        rv_comp = rm_K(:, 1 + 3*(i_var == 2));
        rv_bus = NaN(numel(sv_bus), 1);
        for b = 1:numel(sv_bus)
            if any(sv_compBus == sv_bus(b))
                rv_bus(b) = sum(rv_comp(sv_compBus == sv_bus(b)));
            end
        end
        % each branch: its own coupling between its two buses, -(K_ij + K_ji)/2
        rv_branch = NaN(numel(sv_branch), 1);
        a_branch = reshape(obj.sct_network.a_Branch, [], 1);
        sv_netBus = string(cellfun(@(b) b.s_tag, reshape(obj.sct_network.a_Bus, [], 1), "UniformOutput", false));
        for k = 1:numel(sv_branch)
            sv_end = strings(2, 1);
            for e = 1:2
                x = a_branch{k}.a_Bus{e};
                if isstruct(x)
                    sv_end(e) = string(x.s_tag);
                else
                    sv_end(e) = sv_netBus(str2double(regexp(string(x), "a_Bus\{(\d+)\}$", "tokens", "once")));
                end
            end
            if ~any(sv_elem == sv_branch(k))
                continue
            end
            J = part_matrix(obj, s, sv_branch(k));
            i1 = find(sys.StateName == sv_bv(sv_bvBus == sv_end(1) & iv_kind == i_var));
            i2 = find(sys.StateName == sv_bv(sv_bvBus == sv_end(2) & iv_kind == i_var));
            if ~isempty(i1) && ~isempty(i2)
                rv_branch(k) = -(J(i1, i2) + J(i2, i1)) / 2;
            end
        end
        c_sec{s} = struct("cv_lambda", obj.get_participation(Type="DAE", Index=s).cv_lambda, "rm_bus", rv_bus, ...
            "sm_busLabel", strings(0, 0), "rm_comp", rv_comp, "rm_branch", rv_branch, "sv_row", sv_comp, ...
            "sv_rowBus", sv_compBus, "rm_row", rm_K, "sm_compLabel", compose("%.3g", rv_comp));
    end
    sct_sec = [c_sec{:}];
end


function [sv_elem, sv_elemBus, iv_comp] = element_places(obj, s, sv_bus, sv_comp)
% Elements of section s (tab_owner of the connected model), the bus of each and the
% component of each component and local controller (its tag starts with the tag of the
% component; 0 for the others)
    arguments (Input)
        obj ResultLIN           % The result.
        s (1,1) double          % Section.
        sv_bus (:,1) string     % Bus tags of the diagram.
        sv_comp (:,1) string    % Component tags of the diagram.
    end
    arguments (Output)
        sv_elem (:,1) string    % Tags of the elements.
        sv_elemBus (:,1) string % Bus of each element ("": none, e.g. a branch or a global controller).
        iv_comp (:,1) double    % Component of each element (index in sv_comp; 0: none).
    end
    sv_elem = obj.c_section{s}.tab_owner.Owner;
    sv_elemBus = strings(numel(sv_elem), 1);
    iv_comp = zeros(numel(sv_elem), 1);
    for e = 1:numel(sv_elem)
        if any(sv_bus == sv_elem(e))
            sv_elemBus(e) = sv_elem(e);
            continue
        end
        lv = arrayfun(@(c) startsWith(sv_elem(e), c), sv_comp);
        if any(lv)
            [~, i] = max(strlength(sv_comp) .* lv);
            iv_comp(e) = i;
            sv_b = sv_bus(arrayfun(@(b) startsWith(sv_comp(i), b), sv_bus));
            [~, ib] = max(strlength(sv_b));
            sv_elemBus(e) = sv_b(ib);
        end
    end
end


function A_e = part_matrix(obj, k, sv_owner)
% A of the DAE (the Port of the result) of the part of the owners sv_owner in section k:
% the terms of contribution_part written by section_model, without a result of its own
    arguments (Input)
        obj ResultLIN             % The result.
        k (1,1) double            % Section.
        sv_owner (:,1) string     % Tags of the owners (tab_owner.Owner).
    end
    arguments (Output)
        A_e double                % Part of A over [x; v] of get_ss("DAE").
    end
    sct_opt = struct("Port", default_port(obj), "Form", "descriptor");
    sct = section_model(obj, contribution_part(obj.c_section{k}, sv_owner), obj.output.sv_issue(k), ...
        obj.output.sv_message(k), "DAE", sct_opt);
    A_e = full(sct.A);
end
