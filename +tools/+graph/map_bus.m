classdef map_bus < tools.graph.map_base
    
    methods
        function obj = map_bus(net)
            obj@tools.graph.map_base(net);

            obj.function_CompSize    = 5;
            obj.function_BusSize     = 10;
            obj.function_BusColor    = @BusColor;
            obj.function_BusHeigth   = @( bus, V, I)     norm(V);
            obj.function_CompHeight  = @(comp,t,x,V,I,u) 0;
            obj.function_BranchColor = @(  br,Vf,Vt)     nan;
            obj.function_BranchWidth = @(  br,Vfrom,Vto) abs(1/br.x);

            obj.set_LineStyle;
            obj.set_MarkerStyle;
            
            obj.plot_circle();
            obj.set_MarkerTag;
            obj.set_equilibrium
            

            hold off
            zlim([0,1.1])
            view(2)
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
                bus_num = [' bus',num2str(i)];
                bus = obj.net.a_bus{i};
                bus_type = setdiff(class(bus),'bus_');
                obj.Graph.NodeLabel{i} = [bus_type, bus_num]; 
            end
        end

    end

end

function out = BusColor(bus,~,~)
    switch class(bus)
        case 'bus_slack'
            out = -1;
        case 'bus_PV'
            out = 0;
        case 'bus_PQ'
            out = 1;
    end
end
