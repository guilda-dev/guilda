function [sct_sys, output] = solve(obj, c_block, tab, tab_connection, sct_port) %#ok<INUSL>
% Connect linear blocks along the variable map.
%
% The numerical connector of the linearization: get_sys of every layer
% (PowerSystemModel.get_sys) collects the linear blocks of its model objects
% (Component.get_linear_block, LocalController.get_linear_block,
% GlobalController.get_linear_block) and builds its port from the variable map (the
% inputs, outputs and algebraic bus voltages of the layer), and this method connects them. It reads only its arguments: no network and no model object.
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
% - Each bus of sct_port.sv_algebraic adds the current balance 0 = Y v - sum(I), where
%   sum(I) are the outputs [Ire; Iim] of the blocks at that bus (sct_port.tab_current)
%   and Y = sct_port.cm_Y.
% - The outputs are sct_port.sv_output: outputs or states of the blocks, bus voltages,
%   or bus currents (Y v for an algebraic bus, otherwise the sum of the currents of its
%   blocks).
%
% sct_sys is the descriptor model E [dx; dv]/dt = A [x; v] + B w, y = C [x; v] + D w,
% with the states x of the blocks in their order and the algebraic variables v
% (E = 0 on their rows).
%
% sct_sys.sct_term splits the model into the parts of its elements (the contributions,
% ResultLIN.get_contribution): its fields A, B, C, D and E list the nonzero terms of each
% matrix as rows [Row, Column, Owner, Value], Owner an index into sv_owner; Y lists the
% admittance terms over v alone (the current outputs Y v). A term belongs to the owner of
% its equation row: a state row to the block of the state (s_tag of the block), including
% the terms through its inputs; a current balance row to each block for its own current
% terms and to each admittance stamp of sct_port.tab_stamp (a branch, or the shunt of a
% bus) for its part of Y; an output row to the owner of the output (a bus for a voltage,
% the stamps for a current Y v, the blocks for a sum of their currents). The terms of
% each matrix sum to it.
%
% A block that is not finite stops with
% GUILDA:SolverLIN:JacobianNotFinite (naming its owner), and a name of a block that is
% not in tab with GUILDA:SolverLIN:VariableMap.
    arguments (Input)
        obj                          % Solver (net.solver_LIN, or a SolverLIN for the other layers).
        c_block (:,1) cell           % Blocks in the order of the variable map: struct A, B, C, D, E, StateName, InputName, OutputName (and Owner, the text of the error messages; s_tag, the owner of its terms).
        tab table                    % Variable map of the layer (all rows).
        tab_connection table         % Connection map of the layer.
        sct_port (1,1) struct        % Port of the layer: sv_input, sv_output, sv_algebraic, cm_Y, tab_bus, tab_current (and tab_stamp: Owner, Bus, Y, the admittance stamps that sum to cm_Y).
    end
    arguments (Output)
        sct_sys struct               % Fields A, B, C, D, E, StateName, InputName, OutputName, n_v, sct_term (the terms of each element: sv_owner, A, B, C, D, E, Y).
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
    % the owner of each block, and so of its states and outputs
    sv_xOwner = strings(0,1);
    sv_yOwner = strings(0,1);
    for k = 1:numel(c_block)
        s_blk = "";
        if isfield(c_block{k}, "s_tag")
            s_blk = string(c_block{k}.s_tag);
        elseif isfield(c_block{k}, "Owner")
            s_blk = string(c_block{k}.Owner);
        end
        sv_xOwner = [sv_xOwner; repmat(s_blk, numel(c_block{k}.StateName), 1)]; %#ok<AGROW>
        sv_yOwner = [sv_yOwner; repmat(s_blk, numel(c_block{k}.OutputName), 1)]; %#ok<AGROW>
    end
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

    % The terms of the state rows belong to the owners of the states
    n_xv = n_x + n_v;
    c_term = cell(0,5);
    c_term = add_term(c_term, "A", 1:n_x, 1:n_xv, [Axx, Axv], sv_xOwner);
    c_term = add_term(c_term, "B", 1:n_x, 1:n_w, Bxw, sv_xOwner);
    c_term = add_term(c_term, "E", 1:n_x, 1:n_x, E, sv_xOwner);

    % Current balance of the algebraic buses: 0 = Y v - sum(I)
    tab_bus = sct_port.tab_bus;
    tab_I   = sct_port.tab_current;
    Avx = zeros(n_v, n_x);
    Avv = zeros(n_v, n_v);
    Bvw = zeros(n_v, n_w);
    [c_Yr, sv_stamp] = stamps(sct_port, n_v);
    if n_v > 0
        Avv = tools.complex2matrix(sct_port.cm_Y .* ones(n_v/2));
        for k = 1:numel(c_Yr)
            c_term = add_term(c_term, "A", n_x+(1:n_v), n_x+(1:n_v), c_Yr{k}, sv_stamp(k));
            c_term = add_term(c_term, "Y", 1:n_v, 1:n_v, c_Yr{k}, sv_stamp(k));
        end
        for i = 1:n_v/2
            iv_r = 2*i - [1, 0];
            s_bus = tab_bus.Bus(tab_bus.Vre == sv_v(iv_r(1)));
            for s_part = ["Ire","Iim"]
                r = iv_r(1 + (s_part == "Iim"));
                [~, iv_y] = ismember(tab_I.Label(tab_I.Bus == s_bus & tab_I.Name == s_part), sv_out);
                Avx(r,:) = Avx(r,:) - sum(Cy(iv_y,:), 1);
                Avv(r,:) = Avv(r,:) - sum(Dv(iv_y,:), 1);
                Bvw(r,:) = Bvw(r,:) - sum(Dw(iv_y,:), 1);
                % each block its own current terms
                c_term = add_term(c_term, "A", n_x + r + zeros(size(iv_y)), 1:n_xv, -[Cy(iv_y,:), Dv(iv_y,:)], sv_yOwner(iv_y));
                c_term = add_term(c_term, "B", n_x + r + zeros(size(iv_y)), 1:n_w, -Dw(iv_y,:), sv_yOwner(iv_y));
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
            c_term = add_term(c_term, "C", k, 1:n_xv, Co(k,:), sv_yOwner(j));
            c_term = add_term(c_term, "D", k, 1:n_w, Do(k,:), sv_yOwner(j));
            continue
        end
        j = find(sv_x == s, 1);
        if ~isempty(j)
            Co(k,j) = 1;
            c_term = add_term(c_term, "C", k, j, 1, sv_xOwner(j));
            continue
        end
        j = find(sv_v == s, 1);
        if ~isempty(j)
            Co(k,n_x+j) = 1;
            c_term = add_term(c_term, "C", k, n_x+j, 1, tab_bus.Bus(tab_bus.Vre == s | tab_bus.Vim == s));
            continue
        end
        j = find(sv_w == s, 1);
        if ~isempty(j) && any(sv_Vall == s)
            Do(k,j) = 1;
            c_term = add_term(c_term, "D", k, j, 1, tab.Bus(find(tab.Label == s, 1)));
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
                for m = 1:numel(c_Yr)
                    c_term = add_term(c_term, "C", k, n_x+(1:n_v), c_Yr{m}(j + (s_part == "Iim"), :), sv_stamp(m));
                end
            else
                [~, iv_y] = ismember(tab_I.Label(tab_I.Bus == tab_bus.Bus(i_b) & tab_I.Name == s_part), sv_out);
                Co(k,:) = sum([Cy(iv_y,:), Dv(iv_y,:)], 1);
                Do(k,:) = sum(Dw(iv_y,:), 1);
                c_term = add_term(c_term, "C", k + zeros(size(iv_y)), 1:n_xv, [Cy(iv_y,:), Dv(iv_y,:)], sv_yOwner(iv_y));
                c_term = add_term(c_term, "D", k + zeros(size(iv_y)), 1:n_w, Dw(iv_y,:), sv_yOwner(iv_y));
            end
            continue
        end
        error(msg("GUILDA:SolverLIN:VariableMap", char(s)))
    end

    sct_sys = struct("A", [Axx, Axv; Avx, Avv], "B", [Bxw; Bvw], "C", Co, "D", Do, ...
                     "E", blkdiag(E, zeros(n_v)), "StateName", [sv_x; sv_v], ...
                     "InputName", sv_w, "OutputName", sv_o, "n_v", n_v);
    sct_sys.sct_term = term_table(c_term);

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


function [c_Yr, sv_owner] = stamps(sct_port, n_v)
% Real form of each admittance stamp over v (the buses in the order of cm_Y), and its
% owner; without tab_stamp, one stamp with no owner for all of cm_Y
    c_Yr = cell(0,1);
    sv_owner = strings(0,1);
    if n_v == 0
        return
    end
    if ~isfield(sct_port, "tab_stamp")
        c_Yr = {tools.complex2matrix(sct_port.cm_Y .* ones(n_v/2))};
        sv_owner = "";
        return
    end
    tab_s = sct_port.tab_stamp;
    n_bus = n_v/2;
    c_Yr = cell(height(tab_s),1);
    sv_owner = reshape(string(tab_s.Owner), [], 1);
    for k = 1:height(tab_s)
        [~, iv_b] = ismember(reshape(string(tab_s.Bus{k}), 1, []), sct_port.tab_bus.Bus);
        Ys = zeros(n_bus);
        Ys(iv_b, iv_b) = tab_s.Y{k};
        c_Yr{k} = tools.complex2matrix(Ys);
    end
end


function c_term = add_term(c_term, s_mat, iv_row, iv_col, M, sv_owner)
% Adds the nonzero entries of M, placed at the rows iv_row and the columns iv_col of the
% matrix s_mat; sv_owner is the owner of each row of M (or one owner for all)
    [I, J, V] = find(M);
    if isempty(I)
        return
    end
    sv_owner = reshape(string(sv_owner), [], 1);
    if isscalar(sv_owner)
        sv_o = repmat(sv_owner, numel(I), 1);
    else
        sv_o = sv_owner(I);
    end
    c_term(end+1,:) = {s_mat, reshape(iv_row(I), [], 1), reshape(iv_col(J), [], 1), V(:), sv_o};
end


function sct = term_table(c_term)
% The terms as rows [Row, Column, Owner, Value] per matrix, Owner an index into sv_owner
    sv_all = vertcat(strings(0,1), c_term{:,5});
    [sv_owner, ~, iv_owner] = unique(sv_all, "stable");
    sct = struct("sv_owner", reshape(sv_owner, [], 1));
    sv_mat = string(c_term(:,1));
    n_rows = cellfun(@numel, c_term(:,2));
    iv_end = cumsum(n_rows);
    for s = ["A","B","C","D","E","Y"]
        rm = zeros(0,4);
        for k = reshape(find(sv_mat == s), 1, [])
            iv = iv_end(k) - n_rows(k) + (1:n_rows(k));
            rm = [rm; c_term{k,2}, c_term{k,3}, iv_owner(iv), c_term{k,4}]; %#ok<AGROW>
        end
        sct.(s) = rm;
    end
end
