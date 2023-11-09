function out = get_next_tend(obj,t)
    f = obj.fault.get_next_tend(t);
    i = obj.input.get_next_tend(t);
    p = obj.parallel.get_next_tend(t);
    out = min([f,i,p,obj.StopTime,obj.tlim(end)]);
end