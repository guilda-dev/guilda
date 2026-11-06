function prob = apply(net, prob, sct_options, sct_var)
% Add the Cost and Constraint options to the OPF problem.
%
% - Cost: Cost(v, p) is added to the objective GenCost.
% - Constraint: each field <name> of Constraint(v, p) becomes prob.Constraints.<name>;
%   its dual has the same label in result.lambda.Constraints. A name already in the
%   problem stops with an error.
% v is variables(net, sct_var, Method); p is param(net, Method).
    arguments (Input)
        net                       % Network of the problem.
        prob                      % Problem being built.
        sct_options (1,1) struct  % Effective settings: Method, Cost, Constraint.
        sct_var     (1,1) struct  % Optimization variables by variable name.
    end
    arguments (Output)
        prob                      % Problem with the terms added.
    end
    if isempty(sct_options.Cost) && isempty(sct_options.Constraint)
        return
    end
    s_net = string(net);
    v = variables(net, sct_var, sct_options.Method);
    p = param(net, sct_options.Method);

    if ~isempty(sct_options.Cost)
        cost = call(sct_options.Cost, v, p, s_net, "Cost");
        if ~(isscalar(cost) && (isa(cost, "optim.problemdef.OptimizationExpression") ...
                                || (isnumeric(cost) && isreal(cost))))
            error(msg("GUILDA:SolverOPF:InvalidCost", s_net))
        end
        prob.Objective.GenCost = prob.Objective.GenCost + cost;
    end

    if ~isempty(sct_options.Constraint)
        con = call(sct_options.Constraint, v, p, s_net, "Constraint");
        if ~(isstruct(con) && isscalar(con))
            error(msg("GUILDA:SolverOPF:InvalidConstraint", s_net))
        end
        for s_name = string(fieldnames(con)).'
            c = con.(s_name);
            if ~isa(c, "optim.problemdef.OptimizationConstraint") ...
                    && ~isa(c, "optim.problemdef.OptimizationEquality") ...
                    && ~isa(c, "optim.problemdef.OptimizationInequality")
                error(msg("GUILDA:SolverOPF:InvalidConstraintField", s_name, s_net))
            end
            if isfield(prob.Constraints, s_name)
                error(msg("GUILDA:SolverOPF:DuplicateName", s_name, s_net))
            end
            prob.Constraints.(s_name) = c;
        end
    end
end


function out = call(f, v, p, s_net, s_term)
    try
        out = f(v, p);
    catch ME
        ME2 = MException("GUILDA:SolverOPF:HandleError", ...
                         "The %s handle of %s failed: %s\n(v has the fields: %s)", ...
                         s_term, s_net, ME.message, join(string(fieldnames(v)).', ", "));
        throw(ME2.addCause(ME))
    end
end
