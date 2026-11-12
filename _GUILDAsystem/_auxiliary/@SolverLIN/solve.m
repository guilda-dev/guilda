function [sct_sys, output] = solve(obj, c_block, tab, tab_connection, sct_port) %#ok<INUSL>
% Connect linear blocks along the variable map.
%
% The numerical connector of the linearization: get_sys of every layer
% (PowerSystemModel.get_sys) collects the linear blocks of its model objects
% (Component.get_linear_block, LocalController.get_linear_block,
% GlobalController.get_linear_block) and its port (get_linear_port), and this method
% connects them. It reads only its arguments: no network and no model object.
%
% - Each input of a block is the sum of its sources in tab_connection (the rows whose
%   TargetIndex is the row of tab with the Label of the input): an output of a block
%   (Kind "y" or "yc") or a state (Kind "x"). The rows "equilibrium" add nothing (the
%   values are deviations from the point). An input in sct_port.sv_input also adds the
%   external input of that name. A bus voltage input is the algebraic variable of the bus
%   when it is in sct_port.sv_algebraic, otherwise an external input.
% - The inputs and outputs of the blocks are eliminated: u_b = K y_b + Sx x + Sv v + P w
%   and y_b = C x + D u_b give (I - D K) y_b = ... An I - D K that is singular stops with
%   GUILDA:SolverLIN:AlgebraicLoop.
% - Each bus of sct_port.sv_algebraic adds the current balance 0 = Y v - sum(I) (+ the
%   external current of the bus, for the port "I2V"), where sum(I) are the outputs
%   [Ire; Iim] of the blocks at that bus (sct_port.tab_current) and Y = sct_port.cm_Y.
% - The outputs are sct_port.sv_output: outputs or states of the blocks, bus voltages,
%   or bus currents (Y v for an algebraic bus, otherwise the sum of the currents of its
%   blocks).
%
% sct_sys is the descriptor model E [dx; dv]/dt = A [x; v] + B w, y = C [x; v] + D w,
% with the states x of the blocks in their order and the algebraic variables v
% (E = 0 on their rows). A block that is not finite stops with
% GUILDA:SolverLIN:JacobianNotFinite (naming its owner), and a name of a block that is
% not in tab with GUILDA:SolverLIN:VariableMap.
    arguments (Input)
        obj                          % Solver (net.solver_LIN, or a SolverLIN for the other layers).
        c_block (:,1) cell           % Blocks in the order of the variable map: struct A, B, C, D, E, StateName, InputName, OutputName (and Owner, the text of the error messages).
        tab table                    % Variable map of the layer (all rows).
        tab_connection table         % Connection map of the layer.
        sct_port (1,1) struct        % Port of the layer: sv_input, sv_output, sv_algebraic, cm_Y, tab_bus, tab_current.
    end
    arguments (Output)
        sct_sys struct               % Fields A, B, C, D, E, StateName, InputName, OutputName, n_v.
        output struct                % s_issue ("", "NotFinite", "SingularAvv"), rcond_Avv, n_x, n_v, n_u.
    end
    for k = 1:numel(c_block)
        S = c_block{k};
        for s = ["A","B","C","D","E"]
            if ~all(isfinite(S.(s)(:)))
                s_owner = join(string(S.StateName), ", ");
                if isfield(S, "Owner")
                    s_owner = S.Owner;
                end
                error(msg("GUILDA:SolverLIN:JacobianNotFinite", char(s_owner)))
            end
        end
    end

    % The blocks side by side
    c_A = tools.cellfun(@(S) S.A, c_block);  c_B = tools.cellfun(@(S) S.B, c_block);
    c_C = tools.cellfun(@(S) S.C, c_block);  c_D = tools.cellfun(@(S) S.D, c_block);
    c_E = tools.cellfun(@(S) S.E, c_block);
    A = blkdiag(zeros(0), c_A{:});  B = blkdiag(zeros(0), c_B{:});  C = blkdiag(zeros(0), c_C{:});
    D = blkdiag(zeros(0), c_D{:});  E = blkdiag(zeros(0), c_E{:});
    sv_x   = names(c_block, "StateName");
    sv_in  = names(c_block, "InputName");
    sv_out = names(c_block, "OutputName");
    n_x = numel(sv_x);
    n_l = numel(sv_in);
    n_y = numel(sv_out);
    A = reshape(A, n_x, n_x);   B = reshape(B, n_x, n_l);
    C = reshape(C, n_y, n_x);   D = reshape(D, n_y, n_l);   E = reshape(E, n_x, n_x);

    sv_v = reshape(string(sct_port.sv_algebraic), [], 1);
    sv_w = reshape(string(sct_port.sv_input), [], 1);
    n_v = numel(sv_v);
    n_w = numel(sv_w);
    lv_V = tab.Kind == "Vre" | tab.Kind == "Vim";
    sv_Vall = tab.Label(lv_V);

    % Sources of each input of the blocks: u_b = K y_b + Sx x + Sv v + P w
    K  = zeros(n_l, n_y);
    Sx = zeros(n_l, n_x);
    Sv = zeros(n_l, n_v);
    P  = zeros(n_l, n_w);
    tab_c = tab_connection(tab_connection.SourceIndex > 0, :);
    sv_src  = tab.Label(tab_c.SourceIndex);
    sv_kind = tab.Kind(tab_c.SourceIndex);
    sv_tgt  = tab.Label(tab_c.TargetIndex);
    for l = 1:n_l
        s_in = sv_in(l);
        for m = reshape(find(sv_tgt == s_in), 1, [])
            if sv_kind(m) == "x"
                j = find(sv_x == sv_src(m), 1);
                if isempty(j), error(msg("GUILDA:SolverLIN:VariableMap", char(sv_src(m)))); end
                Sx(l,j) = Sx(l,j) + 1;
            else
                j = find(sv_out == sv_src(m), 1);
                if isempty(j), error(msg("GUILDA:SolverLIN:VariableMap", char(sv_src(m)))); end
                K(l,j) = K(l,j) + 1;
            end
        end
        if any(sv_Vall == s_in)
            j = find(sv_v == s_in, 1);
            if ~isempty(j)
                Sv(l,j) = 1;
                continue
            end
        end
        j = find(sv_w == s_in, 1);
        if ~isempty(j)
            P(l,j) = 1;
        end
    end

    % y_b = C x + D u_b  =>  (I - D K) y_b = (C + D Sx) x + D Sv v + D P w
    M = eye(n_y) - D*K;
    if n_y > 0 && ~(rcond(M) > 1e-14)
        error(msg("GUILDA:SolverLIN:AlgebraicLoop"))
    end
    Cy = M \ (C + D*Sx);
    Dv = M \ (D*Sv);
    Dw = M \ (D*P);
    Axx = A + B*(K*Cy + Sx);
    Axv = B*(K*Dv + Sv);
    Bxw = B*(K*Dw + P);

    % Current balance of the algebraic buses: 0 = Y v - sum(I) + I_ext
    tab_bus = sct_port.tab_bus;
    tab_I   = sct_port.tab_current;
    Avx = zeros(n_v, n_x);
    Avv = zeros(n_v, n_v);
    Bvw = zeros(n_v, n_w);
    if n_v > 0
        Avv = tools.complex2matrix(sct_port.cm_Y .* ones(n_v/2));
        for i = 1:n_v/2
            iv_r = 2*i - [1, 0];
            s_bus = tab_bus.Bus(tab_bus.Vre == sv_v(iv_r(1)));
            for s_part = ["Ire","Iim"]
                r = iv_r(1 + (s_part == "Iim"));
                [~, iv_y] = ismember(tab_I.Label(tab_I.Bus == s_bus & tab_I.Name == s_part), sv_out);
                Avx(r,:) = Avx(r,:) - sum(Cy(iv_y,:), 1);
                Avv(r,:) = Avv(r,:) - sum(Dv(iv_y,:), 1);
                Bvw(r,:) = Bvw(r,:) - sum(Dw(iv_y,:), 1);
                j = find(sv_w == tab_bus.(s_part)(tab_bus.Bus == s_bus), 1);
                if ~isempty(j)
                    Bvw(r,j) = Bvw(r,j) + 1;
                end
            end
        end
    end

    % Outputs
    sv_o = reshape(string(sct_port.sv_output), [], 1);
    n_o  = numel(sv_o);
    Co = zeros(n_o, n_x + n_v);
    Do = zeros(n_o, n_w);
    Yr = zeros(n_v, n_v);
    if n_v > 0
        Yr = tools.complex2matrix(sct_port.cm_Y .* ones(n_v/2));
    end
    for k = 1:n_o
        s = sv_o(k);
        j = find(sv_out == s, 1);
        if ~isempty(j)
            Co(k,:) = [Cy(j,:), Dv(j,:)];
            Do(k,:) = Dw(j,:);
            continue
        end
        j = find(sv_x == s, 1);
        if ~isempty(j)
            Co(k,j) = 1;
            continue
        end
        j = find(sv_v == s, 1);
        if ~isempty(j)
            Co(k,n_x+j) = 1;
            continue
        end
        j = find(sv_w == s, 1);
        if ~isempty(j) && any(sv_Vall == s)
            Do(k,j) = 1;
            continue
        end
        [lv_re, i_re] = ismember(s, tab_bus.Ire);
        [lv_im, i_im] = ismember(s, tab_bus.Iim);
        if lv_re || lv_im
            i_b = max(i_re, i_im);
            s_part = "Ire";
            if lv_im, s_part = "Iim"; end
            j = find(sv_v == tab_bus.Vre(i_b), 1);
            if ~isempty(j)
                % the current into the network: Y v
                Co(k,n_x+1:end) = Yr(j + (s_part == "Iim"), :);
            else
                [~, iv_y] = ismember(tab_I.Label(tab_I.Bus == tab_bus.Bus(i_b) & tab_I.Name == s_part), sv_out);
                Co(k,:) = sum([Cy(iv_y,:), Dv(iv_y,:)], 1);
                Do(k,:) = sum(Dw(iv_y,:), 1);
            end
            continue
        end
        error(msg("GUILDA:SolverLIN:VariableMap", char(s)))
    end

    sct_sys = struct("A", [Axx, Axv; Avx, Avv], "B", [Bxw; Bvw], "C", Co, "D", Do, ...
                     "E", blkdiag(E, zeros(n_v)), "StateName", [sv_x; sv_v], ...
                     "InputName", sv_w, "OutputName", sv_o, "n_v", n_v);

    % An Avv below this reciprocal condition number has no usable inverse (the shipped
    % networks are at 1e-4 or above)
    r_rcondMin = 1e-14;
    output = struct("s_issue", "", "rcond_Avv", Inf, "n_x", n_x, "n_v", n_v, "n_u", n_w);
    if n_v > 0
        output.rcond_Avv = rcond(Avv);
    end
    if ~all(isfinite(sct_sys.A(:))) || ~all(isfinite(sct_sys.B(:))) || ~all(isfinite(sct_sys.C(:))) || ~all(isfinite(sct_sys.D(:)))
        output.s_issue = "NotFinite";
    elseif n_v > 0 && output.rcond_Avv < r_rcondMin
        output.s_issue = "SingularAvv";
    end
end


function sv = names(c_block, s_field)
    c = tools.cellfun(@(S) reshape(string(S.(s_field)), [], 1), c_block);
    sv = vertcat(strings(0,1), c{:});
end
