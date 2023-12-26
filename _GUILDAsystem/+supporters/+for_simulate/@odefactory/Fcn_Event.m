function [value,isterminal,direction] = Fcn_Event(obj,t,x)
    isterminal = 1;
    direction  = 0;
    value = ~obj.GoNext;
end