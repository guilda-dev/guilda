function tab_Ybus2bus = get_admittance_matrix(obj, opt)
% Return the bus admittance matrix of the network as a table.
%
% Rows and columns are the bus tags in the order of `a_Bus`. The matrix sums the
% admittance matrices of the branches and the shunt admittances Gshunt + j*Bshunt of
% the buses, in per unit.
%
% BranchStatus gives the states of branches: a table with the columns Target (branch
% tag), Status and Point; other columns (such as Tag and Time of the event table of a
% Scenario) are ignored. Branches without a row are closed, and an empty table gives the
% matrix of the closed network. A branch takes at most one fault row (Status "3LG",
% "6LG" or "none", with the fault position Point, 0 < Point < 1, from the from end) and
% one parallel row (Status "3open", "6open" or "close"; Point is ignored, e.g. NaN). A
% missing fault row is "none" and a missing parallel row "close". The two rows of a
% branch with n circuits combine into one matrix Y(...) = Branch.get_admittance_matrix(
% Status=..., Point=...):
%
%   fault \ parallel | close         | 3open                   | 6open
%   none             | Y("close")    | Y("3open")              | Y("6open") = 0
%   3LG at p         | Y("3LG", p)   | Y("3open") (the faulted | Y("6open")
%                    |               | circuit is opened)      |
%   6LG at p         | Y("6LG", p)   | (n-1)/n * Y("6LG", p)   | Y("6open")
%                    |               | (the other circuits     |
%                    |               | stay grounded)          |
%
% Only this method and Branch.get_admittance_matrix build the matrix of branch states;
% the power flow, the linearization and the simulation share them. A wrong table stops
% with GUILDA:PowerNetwork:InvalidBranchStatus (a Target that is not a branch tag, a
% Status that is not a branch state, such as "BG" or "open", or two rows of the same
% kind on one branch); the branch reports a wrong Point (GUILDA:Branch:InvalidPoint) and
% "3LG" or "3open" on a single-circuit branch (GUILDA:Branch:SingleCircuit).
%
% <@Examples>
% ```matlab
% tab_Y = net.get_admittance_matrix();
% Y = tab_Y.Variables;
% % one circuit of EL001 grounded at 30 %, all circuits of EL002 open
% tab_state = table(["EL001";"EL002"], ["3LG";"6open"], [0.3; NaN], ...
%     VariableNames=["Target","Status","Point"]);
% tab_Yf = net.get_admittance_matrix(BranchStatus=tab_state);
% ```
%
% See also Branch.get_admittance_matrix
%
% <@Group> Called by analyses
    arguments (Input)
        obj
        opt.BranchStatus table = table(strings(0,1), strings(0,1), zeros(0,1), VariableNames=["Target","Status","Point"])   % States of branches with the columns Target, Status, Point (rows of a Scenario's event table can be passed as they are); branches without a row are closed.
    end
    arguments (Output)
        tab_Ybus2bus   % [pu] Admittance matrix (complex) with bus tags as row and variable names.
    end

    sv_Bus = string(obj.a_Bus);

    n_Bus   = numel(sv_Bus);
    tab_Ybus2bus   = array2table(zeros(n_Bus,n_Bus),"VariableNames",sv_Bus,"RowNames",sv_Bus);

    % State of each branch: fault ("none", "3LG", "6LG") at Point, and parallel ("close", "3open", "6open")
    n_Branch  = numel(obj.a_Branch);
    sv_fault  = repmat("none", n_Branch, 1);
    rv_point  = nan(n_Branch, 1);
    sv_par    = repmat("close", n_Branch, 1);
    tab_state = opt.BranchStatus;
    if height(tab_state) > 0
        sv_col = ["Target","Status","Point"];
        sv_missing = sv_col(~ismember(sv_col, string(tab_state.Properties.VariableNames)));
        if ~isempty(sv_missing)
            error(msg("GUILDA:PowerNetwork:InvalidBranchStatus", char(obj.s_tag), ...
                "the table has no column " + strjoin(sv_missing, ", ")))
        end
        sv_target = string(tab_state.Target(:));
        sv_status = string(tab_state.Status(:));
        [lv_known, iv_branch] = ismember(sv_target, string(obj.a_Branch));
        if ~all(lv_known)
            error(msg("GUILDA:PowerNetwork:InvalidBranchStatus", char(obj.s_tag), ...
                "'" + sv_target(find(~lv_known, 1)) + "' is not a branch tag"))
        end
        lv_fault = ismember(sv_status, ["3LG","6LG","none"]);
        lv_par   = ismember(sv_status, ["3open","6open","close"]);
        if ~all(lv_fault | lv_par)
            i_bad = find(~(lv_fault | lv_par), 1);
            error(msg("GUILDA:PowerNetwork:InvalidBranchStatus", char(obj.s_tag), ...
                "Status """ + sv_status(i_bad) + """ of '" + sv_target(i_bad) + "' is not a branch state"))
        end
        sv_kind = ["fault", "parallel"];
        lm_kind = [lv_fault, lv_par];
        for k = 1:2
            iv_kind = find(lm_kind(:,k));
            [~, iv_first] = unique(iv_branch(iv_kind), "stable");
            iv_dup = setdiff(1:numel(iv_kind), iv_first);
            if ~isempty(iv_dup)
                error(msg("GUILDA:PowerNetwork:InvalidBranchStatus", char(obj.s_tag), ...
                    "'" + sv_target(iv_kind(iv_dup(1))) + "' has two " + sv_kind(k) + " rows"))
            end
        end
        sv_fault(iv_branch(lv_fault)) = sv_status(lv_fault);
        rv_point(iv_branch(lv_fault)) = double(tab_state.Point(lv_fault));
        sv_par(iv_branch(lv_par))     = sv_status(lv_par);
    end

    for i = 1:n_Branch
        br  = obj.a_Branch{i};
        if sv_fault(i) == "none" && sv_par(i) == "close"
            Yij = br.get_admittance_matrix();
        elseif sv_fault(i) == "none" || sv_par(i) == "6open"
            Yij = br.get_admittance_matrix(Status=sv_par(i));
        elseif sv_par(i) == "close"
            Yij = br.get_admittance_matrix(Status=sv_fault(i), Point=rv_point(i));
        elseif sv_fault(i) == "3LG"   % 3open: the faulted circuit is opened
            Yij = br.get_admittance_matrix(Status="3open");
        else                          % 6LG and 3open: the other circuits stay grounded
            br.get_admittance_matrix(Status="3open");   % GUILDA:Branch:SingleCircuit for one circuit
            n_circuit = br.tab_parameter.dynamics.circuit;
            Yij = (n_circuit-1)/n_circuit * br.get_admittance_matrix(Status="6LG", Point=rv_point(i));
        end
        sv_iBus = string(br.a_Bus);
        tab_Ybus2bus{sv_iBus,sv_iBus} = tab_Ybus2bus{sv_iBus,sv_iBus} + Yij;
    end

    cm_Yshunt = tools.dcellfun(@(b) [b.a_Parameter{cellfun(@(p) p.s_tag=="dynamics", b.a_Parameter)}.tab_parameter.Gshunt, b.a_Parameter{cellfun(@(p) p.s_tag=="dynamics", b.a_Parameter)}.tab_parameter.Bshunt]*[1;1j], obj.a_Bus);
    tab_Ybus2bus.Variables = cm_Yshunt + tab_Ybus2bus.Variables;
end
