classdef Abstract < handle
    properties
        current_time
        data  
    end

    properties%(Access=private)
        parent
    end

    properties(Dependent)
        network
        tlim  
    end

    methods(Abstract)
        set_time(obj,time)
        out = get_bus_list(obj);
        tend = get_next_tend(obj,t)
        option = export_option(obj)
    end

    methods
        function set.current_time(obj,val)
            obj.set_time(val);
            obj.current_time = val;
        end

        function net = get.network(obj)
            net = obj.parent.network;
        end

        function t = get.tlim(obj)
            t = obj.parent.tlim;
        end

    end


    methods(Access=protected)
        function idx = get_all_bus(obj)
            idx = tools.harrayfun(@(i) obj.data(i).index(:)', 1:numel(obj.data));
            idx = unique(idx,'sorted');
        end
        function idx = get_all_time(obj)
            idx = [obj.tlim([1,end]),tools.harrayfun(@(i) obj.data(i).time(:)', 1:numel(obj.data))];
            idx = unique(idx,'sorted');
        end
    end
end