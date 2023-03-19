classdef Outputeq_manager < handle

    properties
        net
        y
        t

        a_has_ny
        t_latest
        func_switch
    end

    methods
        function obj = Outputeq_manager(net)
            obj.net         = net;
            obj.a_has_ny    = tools.hcellfun(@(b) b.component.get_ny>0, net.a_bus);
            obj.y           = cell( numel(net.a_bus), 1);
            obj.t_latest    =  nan;
        end

        function add_data(obj,idx,t,x,V,I,u)
            if obj.func_switch && obj.a_has_ny(idx)        
                c = obj.net.a_bus{idx}.component;
                yi = c.get_y_func(c,t,x,V,I,u);
                obj.y{idx} = [obj.y{idx} ; reshape(yi,1,[])];
            end
        end

        function new_time(obj,newtime)
            obj.func_switch = (obj.t_latest ~= newtime);
            if obj.func_switch
                obj.t_latest = newtime;
                obj.t = [obj.t ; newtime];
            end
        end

        function out = export_y(obj, time)
            a_isTime = ismember(obj.t, time);
            for i = find(obj.a_has_ny)
                obj.y{i} = obj.y{i}(a_isTime,:);
            end
            out = obj.y;
        end
    end
end
