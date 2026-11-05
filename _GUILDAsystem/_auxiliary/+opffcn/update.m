function [f_cost, f_const, l_default, s_log] = update(obj, opt)
% Return the OPF terms of obj with the given handles (shared part of set_opffcn).
%
% Used by set_opffcn of Component, Bus, Branch and PowerNetwork, which store the outputs in
% f_opfcost, f_opfconst and l_opfdefault. The given names replace the stored values, the
% others are kept. Cost=[] or Constraint=[] clears that handle.
%
% <@Examples>
% ```matlab
% [obj.f_opfcost, obj.f_opfconst, obj.l_opfdefault, s_log] = ...
%     opffcn.update(obj, Cost=@(v, p) 2*v.P, DefaultConstraint=true);
% ```
    arguments
        obj % Component, Bus, Branch or PowerNetwork whose terms are updated.
        opt.Cost       {mustBeHandleOrEmpty(opt.Cost)} % Cost handle @(v, p), or [] to clear.
        opt.Constraint {mustBeHandleOrEmpty(opt.Constraint)} % Constraint handle @(v, p) returning a struct of named constraints, or [] to clear.
        opt.DefaultConstraint (1,1) logical % Keep the default constraints of the object.
    end
    arguments (Output)
        f_cost    % New f_opfcost.
        f_const   % New f_opfconst.
        l_default % New l_opfdefault.
        s_log     % Edit-log message.
    end
    f_cost    = obj.f_opfcost;
    f_const   = obj.f_opfconst;
    l_default = obj.l_opfdefault;
    if isfield(opt, "Cost");              f_cost    = opt.Cost;              end
    if isfield(opt, "Constraint");        f_const   = opt.Constraint;        end
    if isfield(opt, "DefaultConstraint"); l_default = opt.DefaultConstraint; end
    sr_name = string(fieldnames(opt)).';
    if isempty(sr_name)
        s_log = "set_opffcn";
    else
        s_log = "set_opffcn: " + join(sr_name, ", ");
    end
end


function mustBeHandleOrEmpty(f)
    if ~(isempty(f) || isa(f, "function_handle"))
        error(msg("GUILDA:update:InvalidHandle"))
    end
end
