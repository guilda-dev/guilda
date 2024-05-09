classdef map_forAnime1 < supporters.for_graph.map
    
    properties
        a_cell
    end

    methods
        function obj = map_forAnime1(varargin)
            obj@supporters.for_graph.map(varargin{:});
            obj.initialize;
        end

        function initialize(obj)
            
            func = @(b) angle(b.object.V_equilibrium)+pi/2;
            
            cellfun(@(b) set(b,'marker', 'o'               ), obj.a_bus)
            cellfun(@(b) set(b,'color' , [0.5,0.5,0.5]     ), obj.a_bus)
            cellfun(@(b) set(b,'size'  , 8                 ), obj.a_bus)
            cellfun(@(b) set(b,'ZData' , func(b)           ), obj.a_bus)
            cellfun(@(b) set(b,'Label' , num2str(b.number) ), obj.a_bus)

            is_empty = tools.vcellfun(@(b) isa(b.component,'component.empty'), obj.net.a_bus);
            
            cellfun(@(c) set(c,'marker', '_'   ), obj.a_component(~is_empty));
            cellfun(@(c) set(c,'marker', 'none'), obj.a_component( is_empty));
            cellfun(@(c) set(c,'size'  , 8  ), obj.a_component(~is_empty));
            cellfun(@(c) set(c,'ZData' , 0  ), obj.a_component(~is_empty));
            cellfun(@(c) set(c,'Label' , '' ), obj.a_component(~is_empty))

            cellfun(@(b) set(b,'width',2     ), obj.a_branch)
            cellfun(@(b) set(b,'width',0.1   ), obj.a_busline(~is_empty))
            cellfun(@(b) set(b,'style','none'), obj.a_busline(is_empty))
            
            view(obj.Axes,0,40)
            axis(obj.Axes,'off')
            obj.plot_circle();

            obj.ZLim = [0,pi];

            %obj.Axes.InnerPosition = [0,0,1,1];
        end
    end
end