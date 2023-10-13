classdef graph_node < matlab.mixin.SetGet
    
    properties
        fXData = @(x) x;  
        fYData = @(x) x;
        fZData = @(x) x;
        fcolor = @(x) x;
        fsize  = @(x) x;
        fLabel = @(x) x;
        object
        number
    end

    properties(Dependent)
        XData
        YData
        ZData

        color
        marker
        size

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

        function obj = graph_node(G,index,parent,number,object)
            obj.Graph  = G;
            obj.index  = index;
            obj.object = object;
            obj.parent = parent;
            obj.number = number;
        end

        function fset(obj,prop,varargin)
            obj.(prop) = obj.(['f',prop])(varargin{:});
        end

        % XData
        function set.XData(obj,data)
            obj.Graph.XData(obj.index) = data;
        end
        function data = get.XData(obj)
            data = obj.Graph.XData(obj.index);
        end


        % YData
        function set.YData(obj,data)
            obj.Graph.YData(obj.index) = data;
        end
        function data = get.YData(obj)
            data = obj.Graph.YData(obj.index);
        end


        % ZData
        function set.ZData(obj,data)
            obj.Graph.ZData(obj.index) = data;
        end
        function data = get.ZData(obj)
            data = obj.Graph.ZData(obj.index);
        end


        % color
        function set.color(obj,data)
            if isstring(data) || ischar(data) 
                data = validatecolor(data);
            elseif isnumeric(data) && numel(data) == 1
                data = obj.parent.ColorMap(data,:);
            end
            obj.Graph.NodeColor(obj.index,:) = data(:)';
        end
        function data = get.color(obj)
            data = obj.Graph.NodeColor(obj.index,:);
        end


        % marker
        function set.marker(obj,data)
            obj.Graph.Marker{obj.index} = data;
        end
        function data = get.marker(obj)
            data = obj.Graph.Marker{obj.index};
        end
        

        % size
        function set.size(obj,data)
            obj.Graph.MarkerSize(obj.index) = data;
        end
        function data = get.size(obj)
            data = obj.Graph.MarkerSize(obj.index);
        end


        % Label
        function set.Label(obj,data)
            if isnumeric(data)
                data = num2str(data);
            end
            obj.Graph.NodeLabel{obj.index} = data;
        end
        function data = get.Label(obj)
            data = obj.Graph.NodeLabel{obj.index};
        end


        % FontSize
        function set.FontSize(obj,data)
            obj.Graph.NodeFontSize(obj.index) = data;
        end
        function data = get.FontSize(obj)
            data = obj.Graph.NodeFontSize(obj.index);
        end


        % FontWeight
        function set.FontWeight(obj,data)
            obj.Graph.NodeFontWeight{obj.index} = data;
        end
        function data = get.FontWeight(obj)
            data = obj.Graph.NodeFontWeight{obj.index};
        end


    end
end