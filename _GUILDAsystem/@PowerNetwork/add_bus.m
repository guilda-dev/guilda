function add_bus(obj, BusInstance)
    arguments
        obj 
        BusInstance (1,1) Bus
    end
    BusInstance.checkParent;
    BusInstance.belong(obj, 1+numel(obj.Buses) );
    obj.Buses = [obj.Buses;{BusInstance}];
    obj.onEdit("add Bus");
end