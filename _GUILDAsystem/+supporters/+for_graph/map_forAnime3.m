classdef map_forAnime3 < supporters.for_graph.map

    properties
        a_cell
    end

    methods
        function obj = map_forAnime3(varargin)
            obj@supporters.for_graph.map(varargin{:});
            obj.initialize;
        end

        function initialize(obj)
            signP = @(c) sign(real(c.object.V_equilibrium*conj(c.object.I_equilibrium)));
    
            cellfun(@(b) set(b,'marker', 's' )          , obj.a_bus)
            cellfun(@(b) set(b,'color' , [0.5,0.5,0.5] ), obj.a_bus)
            cellfun(@(b) set(b,'size'  , 7             ), obj.a_bus)
            
            is_empty = tools.vcellfun(@(b) isa(b.component,'component.empty'), obj.net.a_bus);
            func = @(class) supporters.for_graph.function.marker.subject2CompType(class);

            cellfun(@(c) set(c,'marker', func(c.object) ), obj.a_component)
            cellfun(@(c) set(c,'size'  , 8              ), obj.a_component(~is_empty));
            cellfun(@(c) set(c,'ZData' , signP(c)       ), obj.a_component(~is_empty));
            cellfun(@(c) set(c,'Label' , [c.object.Tag,num2str(c.number)] ), obj.a_component(~is_empty))

            cellfun(@(b) set(b,'width',2     ), obj.a_branch)
            cellfun(@(b) set(b,'width',0.1   ), obj.a_busline(~is_empty))
            cellfun(@(b) set(b,'style','none'), obj.a_busline(is_empty))
            
            view(obj.Axes,0,40)
            axis(obj.Axes,'off')

            obj.ZLim = 1.5;

            %obj.Axes.InnerPosition = [0,0,1,1];
        end
    end
end