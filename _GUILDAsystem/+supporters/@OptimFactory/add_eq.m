function add_eq(obj,Aeq,beq,ConNames,opt)
    arguments
        obj 
        Aeq      (:,:) double
        beq      (:,1) double
        ConNames (:,1) string
        opt.method   (1,1) string {mustBeMember(opt.method,["append","overwrite"])} = "append";
    end
    Aeq = obj.validmat(Aeq, ConNames, [obj.x;obj.xsub]);
    beq = obj.validmat(beq, ConNames, "b");
    switch opt.method
        case "append"
            obj.Aeq = [obj.Aeq; Aeq];
            obj.beq = [obj.beq; beq];
        case "overwrite"
            obj.Aeq = Aeq;
            obj.beq = beq;
    end
end
