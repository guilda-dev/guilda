classdef GlobalController < GuildaLayer
    properties
    end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Define Parent & Children for BaseClass.LayerPackage %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
        UpperNetwork
    end
    properties(Dependent,Access=protected)
        Children (:,1) cell
        Parent   (1,1)
    end
    methods
        function cls = get.Children(obj)
        end
        function cls = get.Parent(obj)
        end
    end
    

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Get Method from Control Object %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties(Dependent)
        index_input
        index_observe
    end
    methods
        function index = get.index_input(obj)
            index = tools.hcellfun(@(ci) ci.index, obj.class_input);
        end
        function index = get.index_observe(obj)
            index = tools.hcellfun(@(ci) ci.index, obj.class_observe);
        end
    end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Build Power_network linkage %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Properties inherited from parent classes 
    % >> parent  : Contains the parent class to which this class is subordinate.
    % >> index   : Branch Index
    properties(Dependent)
        network
    end
    properties
        class_input   = {};
        class_observe = {};
    end
    methods
        function net = get.network(obj)
            net = obj.parent;
        end
        function set_network(obj,net,index, index_input, index_observe)
            arguments
                obj 
                net   (1,1) power_network
                index (1,1) double {mustBePositive,mustBeInteger}
                index_input   (1,:) double {mustBePositive,mustBeInteger}
                index_observe (1,:) double {mustBePositive,mustBeInteger}
            end
            obj.index = index;
            obj.set_parent(net)

            bus = net.a_bus;
            bus_index = tools.hcellfun(@(b) b.index, bus);

            [~,index_input  ] = ismember(index_input  , bus_index);
            [~,index_observe] = ismember(index_observe, bus_index);
            
            obj.class_input   = bus(index_input  );
            obj.class_observe = bus(index_observe);
        end
    end



end