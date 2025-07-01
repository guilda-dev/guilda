function add_nonleq(obj,cond,ConNames,opt)
    arguments
        obj
        cond       (:,1) sym
        ConNames   (:,1) string
        opt.method (1,1) string {mustBeMember(opt.method,["append","overwrite"])} = "append";
    end
    obj.validsym(cond);
    switch opt.method
        case "append"
            obj.nonleq = [obj.nonleq;...
                          array2table(cond, "VariableNames","con","RowNames",ConNames)];
        case "overwrite"
            obj.nonleq =  array2table(cond, "VariableNames","con","RowNames",ConNames);
    end
end