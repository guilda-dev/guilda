function [s, str_log] = update(s, opt)
% Shared part of set_opffcn of Component, Bus, Branch and PowerNetwork.
%   [s, str_log] = opffcn.update(obj.s_opffcn, Cost=..., Constraint=..., DefaultConstraint=...)
% Returns the new s_opffcn: the given fields replace the stored ones, the others are kept.
% Cost=[] or Constraint=[] clears that handle. str_log is the edit-log message.
    arguments
        s (1,1) struct
        opt.Cost       {mustBeHandleOrEmpty(opt.Cost)}
        opt.Constraint {mustBeHandleOrEmpty(opt.Constraint)}
        opt.DefaultConstraint (1,1) logical
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
