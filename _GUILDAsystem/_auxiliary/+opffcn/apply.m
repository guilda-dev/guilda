function prob = apply(obj, prob, str_method, s_var)
% Adds the set_opffcn terms of obj to prob (called by build_opf_problem of each class).
%   Cost       : fcnCost(v, p) is added to the objective. The caller leaves out its default
%                cost when obj.s_opffcn.Cost is set, so the handle replaces the default.
%   Constraint : each field <name> of fcnCon(v, p) becomes prob.Constraints.<name>_<tag>
%                (prob.Constraints.<name> for PowerNetwork); its dual has the same label.
% v: opffcn.variables(obj, prob, str_method, s_var) (s_var: optimvars of the caller by
% name); p: opffcn.param(obj, str_method).
    arguments
        obj
        prob
        str_method (1,1) string
        s_var      (1,1) struct = struct()
    end
    s = obj.s_opffcn;
    if isempty(s.Cost) && isempty(s.Constraint)
        return
    end
    str_obj = string(obj);
    v = opffcn.variables(obj, prob, str_method, s_var);
    p = opffcn.param(obj, str_method);

    if ~isempty(s.Cost)
        cost = call(s.Cost, v, p, str_obj, "Cost");
        if ~(isscalar(cost) && (isa(cost, "optim.problemdef.OptimizationExpression") ...
                                || (isnumeric(cost) && isreal(cost))))
            error("GUILDA:opffcn:InvalidCost", ...
                  "The Cost handle of %s must return a real scalar (an optimization expression or a number).", str_obj)
        end
        prob.Objective.GenCost = prob.Objective.GenCost + cost;
    end

    if ~isempty(s.Constraint)
        con = call(s.Constraint, v, p, str_obj, "Constraint");
        if ~(isstruct(con) && isscalar(con))
            error("GUILDA:opffcn:InvalidConstraint", ...
                  "The Constraint handle of %s must return a struct of named constraints, e.g. struct(""Vband"", v.V <= 1.02).", str_obj)
        end
        for str_name = string(fieldnames(con)).'
            c = con.(str_name);
            if ~isa(c, "optim.problemdef.OptimizationConstraint") ...
                    && ~isa(c, "optim.problemdef.OptimizationEquality") ...
                    && ~isa(c, "optim.problemdef.OptimizationInequality")
                error("GUILDA:opffcn:InvalidConstraint", ...
                      "Field ""%s"" of the Constraint handle of %s is not a constraint (use ==, <= or >=).", str_name, str_obj)
            end
            if isa(obj, "PowerNetwork")
                str_label = str_name;
            else
                str_label = str_name + "_" + str_obj;
            end
            if isfield(prob.Constraints, str_label)
                error("GUILDA:opffcn:DuplicateName", ...
                      "Constraint name ""%s"" (from %s) is already used in the OPF problem.", str_label, str_obj)
            end
            prob.Constraints.(str_label) = c;
        end
    end
end


function out = call(f, v, p, str_obj, str_term)
    try
        out = f(v, p);
    catch ME
        ME2 = MException("GUILDA:opffcn:HandleError", ...
                         "The %s handle of %s failed: %s\n(v has the fields: %s)", ...
                         str_term, str_obj, ME.message, join(string(fieldnames(v)).', ", "));
        throw(ME2.addCause(ME))
    end
end
