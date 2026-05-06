function [o, x0, Mass, tp, np, options] = makeODE(obj)
    o = ode;
        
    cls = metaclass(o);
    pList = arrayfun(@(P) P.Name, cls.PropertyList, 'UniformOutput', false);
    pLogc = arrayfun(@(P) strcmp(P.SetAccess, 'public'), cls.PropertyList);

    props = pList(pLogc);
    
    nprops = numel(props);
    ip = 1;
    while ip <= nprops        
        o.(props{ip}) = obj.(props{ip});
        ip = ip + 1;        
    end

    options = odeset("RelTol", o.RelativeTolerance, "AbsTol", o.AbsoluteTolerance);                        

    tp = 1;
    np = size(obj.odeTimeTable,1);                   

    x0   = [];
    Mass = [];
end