classdef map_bus < supporters.for_graph.map

    methods
        function obj = map_bus(net, ax)
            if nargin < 2
                obj@supporters.for_graph.map(net);
            else
                obj@supporters.for_graph.map(net, ax);
            end
            obj.initialize;
        end

        function initialize(obj)
            is_empty = tools.vcellfun(@(b) isa(b.component,'component.empty'), obj.net.a_bus);

            cellfun(@(b) set(b,'marker', 's'                                                        ), obj.a_bus);
            cellfun(@(b) set(b,'color' , supporters.for_graph.function.Color.subject2BusType(b.object)), obj.a_bus);
            cellfun(@(b) set(b,'size'  , 10                                                         ), obj.a_bus);
            cellfun(@(b) set(b,'Label' , num2str(b.number)                                          ), obj.a_bus);

            cellfun(@(c) set(c,'marker', 'none'), obj.a_component);
            cellfun(@(c) set(c,'size'  , 0     ), obj.a_component);
            cellfun(@(c) set(c,'Label' , ''    ), obj.a_component);

            cellfun(@(b) set(b,'width',2     ), obj.a_branch);
            cellfun(@(b) set(b,'width',0.1   ), obj.a_busline(~is_empty));
            cellfun(@(b) set(b,'style','none'), obj.a_busline(is_empty));

            view(obj.Axes, 0, 90)
            axis(obj.Axes, 'off')

            obj.ZLim = 1.5;
        end
    end
end
