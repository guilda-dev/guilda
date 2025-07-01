function connect_bus(obj,from,to)
    arguments
        obj 
        from (1,1) double {mustBeInteger,mustBeNonnegative} = obj.from;
        to   (1,1) double {mustBeInteger,mustBeNonnegative} = obj.to;
    end
    nbus = numel(obj.network.Buses);
    
    if from>0  && from<=nbus
        obj.Buses{1} = bus.empty;
    else
        obj.Buses{1} = obj.network.Buses{from};
    end

    if to>0  && to<=nbus
        obj.Buses{2} = bus.empty;
    else
        obj.Buses{2} = obj.network.Buses{to};
    end
    
    obj.onEdit("connect Branch")
end