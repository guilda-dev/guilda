function tab = binding_table(obj)
% Binding constraints of the solution: the bounds of the variables and the inequalities of OPFprob that hold with equality.
%
% A bound or an inequality g <= 0 (as evaluate gives it) is binding when its value is
% within 1e-4 * max(1, |limit|) of its limit. The value and the limit are physical for the
% GUILDA constraints: the variable and its bound (bounds "<element>max" / "<element>min",
% e.g. Vmax, Pmin); P or -P (Pmax_, two elements), Q or -Q (Qmax_), |I| (Imax_), |S|
% (Smax_) of the branch end; the angle difference From - To (VargMax1_, VargMax2_), the
% limits from tab_parameter.operation of the branch in sct_network. For another
% inequality (e.g. from Constraint) the value is g and the limit 0. The point is the solution of the result tables, and the last
% iteration of sct_iteration for other variables of a given Problem; an inequality that
% cannot be evaluated there is left out. Called by disp_binding and disp_summary.
    arguments (Input)
        obj  % ResultOPF.
    end
    arguments (Output)
        tab  % Table: Constraint, Object, Value, Limit, Multiplier; one row per binding constraint (element).
    end
    r_tol    = 1e-4;
    s_method = string(obj.options.Method);
    prob     = obj.OPFprob;
    tab      = table(strings(0,1), strings(0,1), zeros(0,1), zeros(0,1), zeros(0,1), ...
        'VariableNames', ["Constraint","Object","Value","Limit","Multiplier"]);
    if isempty(prob)
        return
    end

    % the point: bus [Varg; V] (Varg), component [P; Q] (P), other variables from the iterations
    sv_bus = string(obj.tab_bus.Properties.RowNames);
    sct_x  = struct();
    for s_var = string(fieldnames(prob.Variables)).'
        if ismember(s_var, sv_bus) && s_method == "AC OPF"
            sct_x.(s_var) = obj.tab_bus{s_var, ["Varg","V"]}.';
        elseif ismember(s_var, sv_bus) && s_method == "DC OPF"
            sct_x.(s_var) = obj.tab_bus{s_var, "Varg"};
        elseif ismember(s_var, string(obj.tab_cub.Properties.RowNames))
            sct_x.(s_var) = obj.tab_cub{s_var, intersect(["P","Q"], string(obj.tab_cub.Properties.VariableNames), "stable")}.';
        elseif isfield(obj.sct_iteration, "X") && isfield(obj.sct_iteration.X, s_var)
            sct_x.(s_var) = obj.sct_iteration.X.(s_var)(:, end);
        end
    end
    c_row = {};

    % bounds of the variables: "<element>max" / "<element>min", multiplier of lambda.Variables;
    % a fixed element (equal bounds, e.g. the P of a load) is left out
    for s_var = string(fieldnames(sct_x)).'
        var = prob.Variables.(s_var);
        sv_el = string(var.IndexNames{1});
        if isempty(sv_el)
            sv_el = "x" + (1:numel(var));
        end
        for e = reshape(find(var.LowerBound(:) ~= var.UpperBound(:)), 1, [])   % a fixed value (e.g. a load) is no limit
            val = sct_x.(s_var)(e);
            if isfinite(var.UpperBound(e)) && abs(val - var.UpperBound(e)) <= r_tol*max(1, abs(var.UpperBound(e)))
                c_row(end+1,:) = {sv_el(e) + "max", s_var, val, var.UpperBound(e), obj.lambda.Variables.(s_var).Upper(e)}; %#ok<AGROW>
            end
            if isfinite(var.LowerBound(e)) && abs(val - var.LowerBound(e)) <= r_tol*max(1, abs(var.LowerBound(e)))
                c_row(end+1,:) = {sv_el(e) + "min", s_var, val, var.LowerBound(e), obj.lambda.Variables.(s_var).Lower(e)}; %#ok<AGROW>
            end
        end
    end

    % inequalities of the problem; the limit of a GUILDA branch constraint is in
    % tab_parameter.operation of the branch in the snapshot, its value follows from g
    sv_br = string(cellfun(@(b) b.s_tag, obj.sct_network.a_Branch, "UniformOutput", false));
    for s_con = string(fieldnames(prob.Constraints)).'
        % the kind of a GUILDA branch limit, or "" for another constraint; an equality is
        % skipped (a nonlinear constraint has the general class: its text tells the relation)
        con    = prob.Constraints.(s_con);
        s_kind = extractBefore(s_con, "_");
        s_obj  = extractAfter(s_con, "_");
        i_br   = find(s_obj == sv_br | arrayfun(@(b) startsWith(s_obj, b + "_"), sv_br), 1, "last");
        if ismissing(s_kind) || isempty(i_br) || ~ismember(s_kind, ["Pmax","Qmax","Imax","Smax","VargMax1","VargMax2"])
            [s_kind, s_obj] = deal("", "");
            if isa(con, "optim.problemdef.OptimizationEquality") || ...
                    (~isa(con, "optim.problemdef.OptimizationInequality") && contains(expand2str(con(1)), "=="))
                continue
            end
        else
            ope = obj.sct_network.a_Branch{i_br}.tab_parameter.operation;
        end
        try
            rv_g = evaluate(con, sct_x);
        catch
            continue
        end
        for e = 1:numel(rv_g)
            switch s_kind
                case {"Pmax","Qmax"}      % [x; -x] <= limit
                    lim = ope.(s_kind);
                    val = rv_g(e) + lim;
                case {"Imax","Smax"}      % |x|^2 <= limit^2
                    lim = ope.(s_kind);
                    val = sqrt(max(rv_g(e) + lim^2, 0));
                case "VargMax1"           % Varg_from - Varg_to <= Vargmax
                    lim = ope.Vargmax;
                    val = rv_g(e) + lim;
                case "VargMax2"           % Varg_from - Varg_to >= -Vargmax
                    lim = -ope.Vargmax;
                    val = lim - rv_g(e);
                otherwise
                    [val, lim] = deal(rv_g(e), 0);
            end
            if abs(val - lim) <= r_tol*max(1, abs(lim))
                s_name = s_con;
                if numel(rv_g) > 1
                    s_name = s_con + "(" + e + ")";
                end
                rv_mu = obj.lambda.Constraints.(s_con);
                c_row(end+1,:) = {s_name, s_obj, val, lim, rv_mu(e)}; %#ok<AGROW>
            end
        end
    end
    if ~isempty(c_row)
        tab = cell2table(c_row, 'VariableNames', ["Constraint","Object","Value","Limit","Multiplier"]);
        tab.Constraint = string(tab.Constraint);
        tab.Object     = string(tab.Object);
    end
end
