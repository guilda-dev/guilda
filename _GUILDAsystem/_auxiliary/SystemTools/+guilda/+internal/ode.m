function o = ode(obj)    
    
    o = ode;

    cls = metaclass(o);
    pList = arrayfun(@(P) P.Name, cls.PropertyList, 'UniformOutput', false);
    pLogc = arrayfun(@(P) strcmp(P.SetAccess, 'public'), cls.PropertyList);

    props = pList(pLogc);
    
    np = numel(props);
    ip = 1;
    while ip <= np        
        o.(props{ip}) = obj.(props{ip});
        ip = ip + 1;        
    end

    % x0 = obj.getODEInitVal;
    % o.InitialValue = x0;
end