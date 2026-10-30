function [s, str_log] = update(s, opt)
% Update s_opffcn with the given handles (shared part of set_opffcn).
%
% Used by set_opffcn of Component, Bus, Branch and PowerNetwork. The given fields replace
% the stored ones, the others are kept. Cost=[] or Constraint=[] clears that handle.
%
% <@Examples>
% ```matlab
% [s, str_log] = opffcn.update(obj.s_opffcn, Cost=@(v, p) 2*v.P, DefaultConstraint=true);
% ```
    arguments
        s (1,1) struct % Stored s_opffcn.
        opt.Cost       {mustBeHandleOrEmpty(opt.Cost)} % Cost handle @(v, p), or [] to clear.
        opt.Constraint {mustBeHandleOrEmpty(opt.Constraint)} % Constraint handle @(v, p) returning a struct of named constraints, or [] to clear.
        opt.DefaultConstraint (1,1) logical % Keep the default constraints of the object.
    end
    arguments (Output)
        s % New s_opffcn.
        str_log % Edit-log message.
    end
    str_name = string(fieldnames(opt)).';
    for str = str_name
        s.(str) = opt.(str);
    end
    if isempty(str_name)
        str_log = "set_opffcn";
    else
        str_log = "set_opffcn: " + join(str_name, ", ");
    end
end


function mustBeHandleOrEmpty(f)
    if ~(isempty(f) || isa(f, "function_handle"))
        error("GUILDA:opffcn:InvalidHandle", ...
              "Cost and Constraint must be function handles @(v, p) ... (or [] to clear).")
    end
end
