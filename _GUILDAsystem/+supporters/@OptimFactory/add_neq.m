function add_neq(obj,A,b,ConNames,opt)
    arguments
        obj 
        A          (:,:) double
        b          (:,1) double
        ConNames   (:,1) string
        opt.method (1,1) string {mustBeMember(opt.method,["append","overwrite"])} = "append";
    end
    A = obj.validmat(A, ConNames, [obj.x;obj.xsub]);
    b = obj.validmat(b, ConNames, "b");
    switch opt.method
        case "append"
            obj.A = [obj.A; A];
            obj.b = [obj.b; b];
        case "overwrite"
            obj.A = A;
            obj.b = b;
    end
end
