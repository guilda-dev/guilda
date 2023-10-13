classdef map_forUI < supporters.for_graph.map
    methods
        function obj = map_forUI(net,ax)
            obj@supporters.for_graph.map(net,ax);
            obj.initialize;
        end

        function initialize(obj)
            culcP = @(c) real(c.V_equilibrium*conj(c.I_equilibrium));
    
            cellfun(@(b) set(b,'marker', 's' ), obj.a_bus)
            cellfun(@(b) set(b,'color' , [0.5,0.5,0.5] ), obj.a_bus)
            cellfun(@(b) set(b,'size' , 5 ), obj.a_bus)
            
            is_empty = tools.vcellfun(@(b) isa(b.component,'component.empty'), obj.net.a_bus);
            cellfun(@(c) set(c,'marker', supporters.for_graph.function.marker.subject2CompType(c.object)), obj.a_component)
            cellfun(@(c) set(c,'size' , 8), obj.a_component(~is_empty));
            cellfun(@(c) set(c,'ZData' , sign(culcP(c.object))), obj.a_component(~is_empty));
            cellfun(@(c) set(c,'Label' , [c.object.Tag,num2str(c.number)] ), obj.a_component(~is_empty))

            cellfun(@(b) set(b,'width',2), obj.a_branch)
            cellfun(@(b) set(b,'width',0.1), obj.a_busline(~is_empty))
            cellfun(@(b) set(b,'style','none'), obj.a_busline(is_empty))
            
            view(obj.Axes,0,40)
            obj.Axes.XAxis.Visible = 'off';
            obj.Axes.YAxis.Visible = 'off';
            obj.Axes.ZAxis.Visible = 'off';
            
            for i = 1:numel(obj.a_bus)
                b = obj.a_component{i};
                if strcmp(b.object.parallel,'on')
                    b.color = [0,1,0];
                else
                    b.color = [1,0,0];
                end
            end

            obj.ZLim = 1.5;
        end
    end
end