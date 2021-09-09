function add_bus(obj, bus)
if iscell(bus)
    if any(tools.vcellfun(@(b) ~isa(b, 'bus'), bus))
       error('must be a child of bus');
    end
    obj.a_bus = [obj.a_bus; bus];
else
    if isa(bus, 'bus')
        obj.a_bus = [obj.a_bus; {bus}];
    else
       error('must be a child of bus'); 
    end
end
end