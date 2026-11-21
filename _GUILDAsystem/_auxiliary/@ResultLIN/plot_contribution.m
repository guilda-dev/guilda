function sct_graph = plot_contribution(obj, opt)
% Plot the share of each element in an eigenvalue on the network diagram.
%
% The DAE (get_ss("DAE") in the Port of the result) is the sum of the parts of its
% elements, A = sum of A_e (get_contribution: the components, the local and global
% controllers, the branches and the buses). For a mode with the right and left
% eigenvectors v, w of the DAE (get_eigenvector("DAE"), w' E v = 1), the share of element e
% in its eigenvalue is
%
% ```
% lambda_e = w' A_e v,    sum over the elements of lambda_e = lambda
% ```
%
% so Re(lambda_e) is the part of the element in the damping of the mode (negative:
% damping it) and Im(lambda_e) its part in the frequency [rad/s].
%
% Draws the same figure as plot_participation (the eigenvalue map of Type "DAE" on the
% left, the diagram of sct_network on the right and a table below it), with the mode
% picked on the map (Mode is the column of get_participation(Type="DAE") picked first).
% Quantity chooses the value shown: "real" (default, Re lambda_e), "imag" (Im lambda_e) or
% "abs" (|lambda_e|). The diagram colors each component by its share plus the shares of
% its local controllers (their tags start with the tag of the component), each branch by
% its share, and each bus by the share of the bus (its shunt); the colorbar is symmetric
% about 0 ([0 max] for "abs"). Global controllers have no place on the diagram: they are
% in the table. The table lists every element with Re and Im of lambda_e (their sum,
% lambda, in its title) until a bus is clicked, then the elements at that bus. Sections
% switch through the playback bar as in plot_participation; a Mode beyond the modes of
% the section shown first stops with GUILDA:ResultLIN:ModeRange, and another layer than
% the network with GUILDA:ResultLIN:NetworkOnly.
%
% It returns a struct with Eigenvalue (GraphChart), Diagram (GraphNetDiagram) and Table
% (uitable).
%
% <@Examples>
% ```matlab
% res = net.get_sys();
% sct = res.plot_contribution(Mode=4);            % which elements damp mode 4
% sct.Table.Data                                  % Re, Im of each element's share
% sct = res.plot_contribution(Quantity="imag");
% ```
%
% See also ResultLIN.get_contribution, ResultLIN.get_eigenvector, ResultLIN.plot_participation
    arguments (Input)
        obj
        opt.Quantity (1,1) string {mustBeMember(opt.Quantity, ["real","imag","abs"])} = "real"  % Value of the colors: Re, Im or |.| of the share of each element.
        opt.Mode (1,1) double {mustBeInteger, mustBePositive} = 1  % Mode picked first: a column of get_participation(Type="DAE").
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
    s_limit = "symmetric";
    if opt.Quantity == "abs"
        s_limit = "zero";
    end
    s_q = opt.Quantity;
    sct_spec = struct("s_name", "Share in the eigenvalue (" + s_q + ")", "s_colorbar", s_q + "(\lambda_e)", ...
        "s_limit", s_limit, "sv_column", ["Re", "Im"], "l_tableAll", true, "l_cartesian", true, ...
        "fcn_section", @(sv_bus, sv_comp, sv_branch) share_sections(obj, s_q, sv_bus, sv_comp, sv_branch));
    sct_graph = mode_diagram(obj, struct("Type", "DAE", "Index", opt.Index, "Mode", opt.Mode, "Parent", opt.Parent), sct_spec);
end


function sct_sec = share_sections(obj, s_q, sv_bus, sv_comp, sv_branch)
% Data of each section for mode_diagram: the share w' A_e v of each element in each mode
    arguments (Input)
        obj ResultLIN           % The result.
        s_q (1,1) string        % Quantity: "real", "imag" or "abs".
        sv_bus (:,1) string     % Bus tags of the diagram.
        sv_comp (:,1) string    % Component tags of the diagram.
        sv_branch (:,1) string  % Branch tags of the diagram.
    end
    arguments (Output)
        sct_sec struct          % Data of each section (see mode_diagram).
    end
    switch s_q
        case "real", fcn = @real;
        case "imag", fcn = @imag;
        otherwise,   fcn = @abs;
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
        % the share of every element (tab_owner of the connected model)
        tab_owner = obj.c_section{s}.tab_owner;
        sv_elem = tab_owner.Owner;
        cm_share = complex(zeros(numel(sv_elem), n_m));
        for e = 1:numel(sv_elem)
            A_e = obj.get_contribution(sv_elem(e), Index=s).A;
            cm_share(e, :) = sum(conj(W) .* (A_e * R), 1);
        end
        % the bus of each element: the bus itself, the bus of a component, the component of a local controller
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
        rm_bus = NaN(numel(sv_bus), n_m);
        [lv, iv] = ismember(sv_bus, sv_elem);
        rm_bus(lv, :) = fcn(cm_share(iv(lv), :));
        rm_comp = NaN(numel(sv_comp), n_m);
        for i = 1:numel(sv_comp)
            if any(iv_comp == i)
                rm_comp(i, :) = fcn(sum(cm_share(iv_comp == i, :), 1));
            end
        end
        rm_branch = NaN(numel(sv_branch), n_m);
        [lv, iv] = ismember(sv_branch, sv_elem);
        rm_branch(lv, :) = fcn(cm_share(iv(lv), :));
        c_sec{s} = struct("cv_lambda", cv_lambda, "rm_bus", rm_bus, "sm_busLabel", strings(0, 0), ...
            "rm_comp", rm_comp, "rm_branch", rm_branch, "sv_row", sv_elem, "sv_rowBus", sv_elemBus, "rm_row", cm_share);
    end
    sct_sec = [c_sec{:}];
end
