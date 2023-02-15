classdef map_bus < tools.graph.map_base
    
    methods
        function obj = map_bus(net)
            obj@tools.graph.map_base(net);

            obj.function_CompSize    = @(comp,t,x,V,I,u) 5;
            obj.function_BusHeigth   = @( bus, V, I)     norm(V);
            obj.function_CompHeight  = @(comp,t,x,V,I,u) 0;
            obj.function_BranchColor = @(  br,Vf,Vt)     nan;
            obj.function_BranchWidth = @(  br,Vfrom,Vto) abs(1/br.x);

            obj.set_LineStyle;
            obj.set_MarkerStyle;
            
            obj.plot_circle();
            obj.set_equilibrium
            

            hold off
            zlim([0,1.1])
            view(0,70)
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
    end

end
