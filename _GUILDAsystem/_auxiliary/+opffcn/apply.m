function prob = apply(obj, prob, str_method, s_var)
% Add the set_opffcn terms of obj to the OPF problem.
%
% Called by build_opf_problem of each class.
%
% - Cost: fcnCost(v, p) is added to the objective. The caller leaves out its default
%   cost when obj.f_opfcost is set, so the handle replaces the default.
% - Constraint: each field <name> of fcnCon(v, p) becomes prob.Constraints.<name>_<tag>
%   (prob.Constraints.<name> for PowerNetwork); its dual has the same label.
%
% v is opffcn.variables(obj, prob, str_method, s_var); p is opffcn.param(obj, str_method).
%
% See also opffcn.variables, opffcn.param, opffcn.update
    arguments (Input)
        obj                                % Component, Bus, Branch or PowerNetwork whose f_opfcost and f_opfconst are applied.
        prob                               % Optimization problem being built.
        str_method (1,1) string            % "ELD", "DC OPF" or "AC OPF".
        s_var      (1,1) struct = struct() % Optimization variables of the caller by name.
    end
    arguments (Output)
        prob                               % Problem with the terms added.
    end
    if isempty(obj.f_opfcost) && isempty(obj.f_opfconst)
        return
    end
    str_obj = string(obj);
    v = opffcn.variables(obj, prob, str_method, s_var);
    p = opffcn.param(obj, str_method);

    if ~isempty(obj.f_opfcost)
        cost = call(obj.f_opfcost, v, p, str_obj, "Cost");
        if ~(isscalar(cost) && (isa(cost, "optim.problemdef.OptimizationExpression") ...
                                || (isnumeric(cost) && isreal(cost))))
            error(msg("GUILDA:apply:InvalidCost", str_obj))
        end
        prob.Objective.GenCost = prob.Objective.GenCost + cost;
    end

    if ~isempty(obj.f_opfconst)
        con = call(obj.f_opfconst, v, p, str_obj, "Constraint");
        if ~(isstruct(con) && isscalar(con))
            error(msg("GUILDA:apply:InvalidConstraint", str_obj))
        end
        for str_name = string(fieldnames(con)).'
            c = con.(str_name);
            if ~isa(c, "optim.problemdef.OptimizationConstraint") ...
                    && ~isa(c, "optim.problemdef.OptimizationEquality") ...
                    && ~isa(c, "optim.problemdef.OptimizationInequality")
                error(msg("GUILDA:apply:InvalidConstraintField", str_name, str_obj))
            end
            if isa(obj, "PowerNetwork")
                str_label = str_name;
            else
                str_label = str_name + "_" + str_obj;
            end
            if isfield(prob.Constraints, str_label)
                error(msg("GUILDA:apply:DuplicateName", str_label, str_obj))
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
