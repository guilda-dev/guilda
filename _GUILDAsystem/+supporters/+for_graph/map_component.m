classdef map_component < supporters.for_graph.map

    methods
        function obj = map_component(net, ax)
            if nargin < 2
                obj@supporters.for_graph.map(net);
            else
                obj@supporters.for_graph.map(net, ax);
            end
            obj.initialize;
        end

        function initialize(obj)
            is_empty = tools.vcellfun(@(b) isa(b.component,'component.empty'), obj.net.a_bus);
            func_marker = @(c) supporters.for_graph.function.marker.subject2CompType(c.object);
            func_color  = @(c) supporters.for_graph.function.Color.subject2CompType(c.object);

            cellfun(@(b) set(b,'marker', 's'              ), obj.a_bus);
            cellfun(@(b) set(b,'color' , [0.5, 0.5, 0.5] ), obj.a_bus);
            cellfun(@(b) set(b,'size'  , 7                ), obj.a_bus);
            cellfun(@(b) set(b,'Label' , ''               ), obj.a_bus);

            cellfun(@(c) set(c,'marker', func_marker(c)), obj.a_component);
            cellfun(@(c) set(c,'color' , func_color(c) ), obj.a_component(~is_empty));
            cellfun(@(c) set(c,'size'  , 15            ), obj.a_component(~is_empty));
            cellfun(@(c) set(c,'Label' , [c.object.Tag, num2str(c.number)]), obj.a_component(~is_empty));
            cellfun(@(c) set(c,'Label' , ''            ), obj.a_component( is_empty));

            cellfun(@(b) set(b,'width',2     ), obj.a_branch);
            cellfun(@(b) set(b,'width',0.1   ), obj.a_busline(~is_empty));
            cellfun(@(b) set(b,'style','none'), obj.a_busline(is_empty));

            view(obj.Axes, 0, 90)
            axis(obj.Axes, 'off')

            obj.ZLim = 1.5;
        end
    end
end
