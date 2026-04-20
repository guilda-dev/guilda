classdef graph_edge < matlab.mixin.SetGet
    properties
        number
    end
    
    properties(Dependent)

        color
        style
        width

        Label
        FontSize 
        FontWeight
    end

    properties(SetAccess=protected)
        index
        Graph
        parent
    end

    methods
        function obj = graph_edge(G,index,parent,number)
            obj.Graph  = G;
            obj.index  = index;
            obj.parent = parent;
            obj.number = number;
        end

        % color
        function set.color(obj,data)
            if isstring(data) || ischar(data) 
                data = validatecolor(data);
            elseif isnumeric(data) && numel(data) == 1
                data = obj.parent.ColorMap(data,:);
            end
            obj.Graph.EdgeColor(obj.index,:) = data(:)';
        end
        function data = get.color(obj)
            data = obj.Graph.EdgeColor(obj.index,:);
        end


        % style
        function set.style(obj,data)
            obj.Graph.LineStyle{obj.index} = data;
        end
        function data = get.style(obj)
            data = obj.Graph.LineStyle{obj.index};
        end


        % width
        function set.width(obj,data)
            obj.Graph.LineWidth(obj.index) = data;
        end
        function data = get.width(obj)
            data = obj.Graph.LineWidth(obj.index);
        end


        % Label
        function set.Label(obj,data)
            if isnumeric(data)
                data = num2str(data);
            end
            obj.Graph.EdgeLabel{obj.index} = data;
        end
        function data = get.Label(obj)
            data = obj.Graph.EdgeLabel{obj.index};
        end


        % FontSize
        function set.FontSize(obj,data)
            obj.Graph.EdgeFontSize(obj.index) = data;
        end
        function data = get.FontSize(obj)
            data = obj.Graph.EdgeFontSize(obj.index);
        end


        % FontWeight
        function set.FontWeight(obj,data)
            obj.Graph.EdgeFontWeight{obj.index} = data;
        end
        function data = get.FontWeight(obj)
            data = obj.Graph.EdgeFontWeight{obj.index};
        end

        
    end
end