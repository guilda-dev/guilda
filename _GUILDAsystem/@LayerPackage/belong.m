function belong(obj,parentInstance,index)
    arguments
        obj 
        parentInstance (1,1) LayerPackage
        index          (1,1) double {mustBeInteger,mustBePositive}
    end
    obj.parent = parentInstance;
    obj.index  = index;
end