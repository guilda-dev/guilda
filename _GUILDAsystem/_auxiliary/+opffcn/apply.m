function prob = apply(obj, prob, s_method, sct_var)
% Add the set_opffcn terms of obj to the OPF problem.
%
% Called by build_opf_problem of each class.
%
% - Cost: fcnCost(v, p) is added to the objective. The caller leaves out its default
%   cost when obj.f_opfcost is set, so the handle replaces the default.
% - Constraint: each field <name> of fcnCon(v, p) becomes prob.Constraints.<name>_<tag>
%   (prob.Constraints.<name> for PowerNetwork); its dual has the same label.
%
% v is opffcn.variables(obj, prob, s_method, sct_var); p is opffcn.param(obj, s_method).
%
% Output `prob`: the problem with the terms added.
%
% See also opffcn.variables, opffcn.param, opffcn.update
    arguments
        obj % Component, Bus, Branch or PowerNetwork whose f_opfcost and f_opfconst are applied.
        prob % Optimization problem being built.
        s_method   (1,1) string % "ELD", "DC OPF" or "AC OPF".
        sct_var    (1,1) struct = struct() % Optimization variables of the caller by name.
    end
    if isempty(obj.f_opfcost) && isempty(obj.f_opfconst)
        return
    end
    s_obj = string(obj);
    v = opffcn.variables(obj, prob, s_method, sct_var);
    p = opffcn.param(obj, s_method);

    if ~isempty(obj.f_opfcost)
        cost = call(obj.f_opfcost, v, p, s_obj, "Cost");
        if ~(isscalar(cost) && (isa(cost, "optim.problemdef.OptimizationExpression") ...
                                || (isnumeric(cost) && isreal(cost))))
            error(msg("GUILDA:apply:InvalidCost", s_obj))
        end
        prob.Objective.GenCost = prob.Objective.GenCost + cost;
    end

    if ~isempty(obj.f_opfconst)
        con = call(obj.f_opfconst, v, p, s_obj, "Constraint");
        if ~(isstruct(con) && isscalar(con))
            error(msg("GUILDA:apply:InvalidConstraint", s_obj))
        end
        for s_name = string(fieldnames(con)).'
            c = con.(s_name);
            if ~isa(c, "optim.problemdef.OptimizationConstraint") ...
                    && ~isa(c, "optim.problemdef.OptimizationEquality") ...
                    && ~isa(c, "optim.problemdef.OptimizationInequality")
                error(msg("GUILDA:apply:InvalidConstraintField", s_name, s_obj))
            end
            if isa(obj, "PowerNetwork")
                s_label = s_name;
            else
                s_label = s_name + "_" + s_obj;
            end
            if isfield(prob.Constraints, s_label)
                error(msg("GUILDA:apply:DuplicateName", s_label, s_obj))
            end
            prob.Constraints.(s_label) = c;
        end
    end
end


function out = call(f, v, p, s_obj, s_term)
    try
        out = f(v, p);
    catch ME
        ME2 = MException("GUILDA:opffcn:HandleError", ...
                         "The %s handle of %s failed: %s\n(v has the fields: %s)", ...
                         s_term, s_obj, ME.message, join(string(fieldnames(v)).', ", "));
        throw(ME2.addCause(ME))
    end
end
