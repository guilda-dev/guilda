function replace_bus(obj, BusInstance, i_bus)
    arguments
        obj 
        BusInstance (1,1) Bus
        i_bus       (1,1) double {mustBePositive,mustBeInteger}
    end
    assert(i_bus <= numel(obj.Buses), config.lang("indexがBusの要素数を越えています。","index exceeds the number of Bus."))
    BusInstance.checkParent;
    if ~isa(obj.Buses{i_bus},"bus.empty")
        cellfun(@(c) BusInstance.add_component(c), obj.Buses{i_bus}.Components)
        obj.Buses{i_bus}.disband;
    end
    BusInstance.belong(obj, i_bus);
    obj.Buses{i_bus} = BusInstance;
    obj.onEdit("replace Bus"+i_bus);
end