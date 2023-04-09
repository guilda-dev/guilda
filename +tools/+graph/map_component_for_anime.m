classdef map_component_for_anime < tools.graph.map_base

    properties(Access = private)
        idx_component_empty
    end

    methods
        function obj = map_component_for_anime(net,ax)
            obj@tools.graph.map_base(net,ax)

            obj.set_MarkerStyle;
            obj.set_LineStyle;
            obj.set_BusMarker;
            
            hold(ax,'off')
            zlim(ax,[-1.1,1.1])
            view(ax,0,30)
            obj.normalize_range = 4;
        end
    end

    methods(Access=private)

        function set_MarkerStyle(obj)
            for i = 1:obj.nbus
                comp = obj.net.a_bus{i}.component;
                nclass = class(comp);
                obj.Graph.NodeLabel{i}  = '';
                obj.Graph.NodeLabel{obj.nbus+i}  = num2str(i);
                if contains(nclass,'generator') || contains(nclass,'Generator')
                    obj.Graph.Marker{obj.nbus+i} = 'o';
                elseif contains(nclass,'load') || contains(nclass,'Load')
                    obj.Graph.Marker{obj.nbus+i} = 'v';
                elseif isa(comp,'component_empty')
                    obj.Graph.NodeLabel{obj.nbus+i}  = '';
                    obj.Graph.Marker{obj.nbus+i} = 'none';
                else
                    obj.Graph.Marker{obj.nbus+i} = 's';
                end
                
                if ismember('tag',fieldnames(comp))
                    obj.Graph.NodeLabel{obj.nbus+i}  = [comp.tag,num2str(i)];
                end
            end
        end

        function set_LineStyle(obj)
            obj.Graph.LineStyle(obj.Edge_idx_nonunit) = {'none'};
        end

        function set_BusMarker(obj)
            obj.Graph.MarkerSize(1:obj.nbus) = 5;
            obj.Graph.Marker(1:obj.nbus) = {'s'};
        end
    end
end
