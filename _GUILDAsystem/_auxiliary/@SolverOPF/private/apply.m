function prob = apply(prob, sct_options, tab_bus, tab_component, tab_branch, sct_var)
% Add the Cost and Constraint options to the OPF problem.
%
% - Cost: Cost(v, p) is added to the objective GenCost.
% - Constraint: each field <name> of Constraint(v, p) becomes prob.Constraints.<name>;
%   its dual has the same label in result.lambda.Constraints. A name already in the
%   problem stops with an error.
% v is variables(tab_bus, tab_component, tab_branch, sct_var, Method); p holds p.Method
% and p.base (sct_options.base: baseMVA, Hz of the network).
    arguments (Input)
        prob                      % Problem being built.
        sct_options (1,1) struct  % Effective settings: Method, Cost, Constraint, base.
        tab_bus       table       % Bus table of the problem.
        tab_component table       % Component table of the problem.
        tab_branch    table       % Branch table of the problem.
        sct_var     (1,1) struct  % Optimization variables by variable name.
    end
    arguments (Output)
        prob                      % Problem with the terms added.
    end
    if isempty(sct_options.Cost) && isempty(sct_options.Constraint)
        return
    end
    v = variables(tab_bus, tab_component, tab_branch, sct_var, sct_options.Method);
    p = struct("Method", sct_options.Method, "base", sct_options.base);

    if ~isempty(sct_options.Cost)
        cost = call(sct_options.Cost, v, p, "Cost");
        if ~(isscalar(cost) && (isa(cost, "optim.problemdef.OptimizationExpression") ...
                                || (isnumeric(cost) && isreal(cost))))
            error(msg("GUILDA:SolverOPF:InvalidCost"))
        end
        prob.Objective.GenCost = prob.Objective.GenCost + cost;
    end

    if ~isempty(sct_options.Constraint)
        con = call(sct_options.Constraint, v, p, "Constraint");
        if ~(isstruct(con) && isscalar(con))
            error(msg("GUILDA:SolverOPF:InvalidConstraint"))
        end
        for s_name = string(fieldnames(con)).'
            c = con.(s_name);
            if ~isa(c, "optim.problemdef.OptimizationConstraint") ...
                    && ~isa(c, "optim.problemdef.OptimizationEquality") ...
                    && ~isa(c, "optim.problemdef.OptimizationInequality")
                error(msg("GUILDA:SolverOPF:InvalidConstraintField", s_name))
            end
            if isfield(prob.Constraints, s_name)
                error(msg("GUILDA:SolverOPF:DuplicateName", s_name))
            end
            prob.Constraints.(s_name) = c;
        end
    end
end


function out = call(f, v, p, s_term)
    try
        out = f(v, p);
    catch ME
        ME2 = MException("GUILDA:SolverOPF:HandleError", ...
                         "The %s handle failed: %s\n(v has the fields: %s)", ...
                         s_term, ME.message, join(string(fieldnames(v)).', ", "));
        throw(ME2.addCause(ME))
    end
end
