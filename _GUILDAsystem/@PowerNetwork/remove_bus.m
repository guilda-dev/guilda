function remove_bus(obj, i_bus)
    arguments
        obj 
        i_bus (1,1) double {mustBePositive,mustBeInteger}
    end
    assert(i_bus <= numel(obj.Buses), config.lang("indexがBusの要素数を越えています。","index exceeds the number of Bus."))
    obj.Buses{i_bus}.disband;
    obj.Buses{i_bus} = bus.empty;
    obj.onEdit("remove Bus"+i_bus);
    for i_branch = 1:numel(obj.Branches)
        branch = obj.Branches{i_branch};
        i_Connected_bus = [branch.from,branch.to];
        if any(i_Connected_bus==i_bus)
            obj.remove_branch(i_branch)
        end
    end
end