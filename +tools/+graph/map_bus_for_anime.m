classdef map_bus_for_anime < tools.graph.map_base
    
    methods
        function obj = map_bus_for_anime(net,ax)
            obj@tools.graph.map_base(net,ax);

            obj.function_CompSize    = 5;
            obj.function_BusSize     = 10;
            obj.function_BusHeight   = @( bus, V, I)     norm(V);
            obj.function_CompHeight  = @(comp,t,x,V,I,u) 0;
            obj.function_BranchColor = @(  br,Vf,Vt)     nan;
            obj.function_BranchWidth = @(  br,Vfrom,Vto) abs(1/br.x);

            obj.set_LineStyle;
            obj.set_MarkerStyle;
            
            obj.plot_circle(ax);
            obj.set_MarkerTag;
            

            hold(ax, 'off')
            zlim(ax,[0,1.1])
            view(ax,0,50)
            obj.normalize_range = 4;
        end
    end

    methods(Access=private)
        function set_LineStyle(obj)
            obj.Graph.LineStyle(obj.Edge_idx_BusLine) = {':'};
        end

        function set_MarkerStyle(obj)
            obj.Graph.Marker(1:obj.nbus)             = {'s'};
            obj.Graph.Marker(obj.nbus+(1:obj.nbus))  = {'_'};
        end

        function set_MarkerTag(obj)
            for i = 1:obj.nbus
                obj.Graph.NodeLabel{i} = num2str(i);
            end
        end

    end

end


