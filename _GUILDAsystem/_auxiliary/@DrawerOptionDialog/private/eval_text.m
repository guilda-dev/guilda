function [value, l_ok] = eval_text(s_expr, obj, arg)
% Value of an expression of functionSignatures.json (a default or a choices list), if it can be evaluated here.
%
% The expression is evaluated in this function, whose only variables for it are obj and arg
% (the values of other inputs of the method, `arg.unit`, see eval_depend): an expression on
% another variable, or on obj when it is not given, fails and gives l_ok = false.
    arguments (Input)
        s_expr      % Expression (string, possibly empty).
        obj  = []   %#ok<INUSA> Object the expression may use as obj ([]: none).
        arg (1,1) struct = struct()   %#ok<INUSA> Values of other inputs by name, used as arg.<name>.
    end
    arguments (Output)
        value               % Value of the expression ([] when it cannot be evaluated).
        l_ok (1,1) logical  % True when the expression was evaluated.
    end
    value = [];
    l_ok  = false;
    if isempty(s_expr) || strtrim(s_expr) == ""
        return
    end
    try
        value = eval(char(s_expr));
        l_ok  = true;
    catch
    end
end
