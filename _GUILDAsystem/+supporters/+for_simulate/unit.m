classdef unit < matlab.mixin.SetGet
    properties
        object
        index

        get_dx_func

        simulate_when_disconnect = true;
        linear

        solver


        xlast
        Vlast
        Ilast

        xdata
        Vdata
        Idata
    end

    properties(Dependent)
        is_connected
        is_simulated
    end

    methods
        function obj = unit_component(object,solver,idx,linear)
            obj.object  = object;
            obj.solvaer = solver;
            obj.idx     = idx;
            if nargin == 4
                obj.linear = linear;
            end
        end

        function out = get.is_connected(obj)
            if strcmp(obj.object.parallel,'on')
                out = obj.index;
            else
                out = [];
            end
        end

        function out = get.is_simulated(obj)
            if obj.is_connected || obj.simulate_when_disconnect
                out = obj.index;
            else
                out = [];
            end
        end

        function set.is_connected(obj,onoff)
            if onoff
                obj.object.connect;
            else
                obj.object.disconnect;
            end
            obj.solver.ToBeStop = true;
        end

        function set.simulate_when_disconnect(obj,true_or_false)
            obj.simulate_when_disconnect = true_or_false;
            obj.solver.ToBeStop = true;%#ok
        end

        function set.linear(obj,linear)
            obj.set_linear(linear)
        end

        function storage_data(obj,x,V,I)
            obj.xdata = [ obj.xdata ; x ];
            obj.Vdata = [ obj.Vdata ; V ];
            obj.Idata = [ obj.Idata ; I ];

            obj.xlast = obj.xdata(end,:).';
            obj.Vlast = obj.Vdata(end,:).';
            obj.Ilast = obj.Idata(end,:).';
        end
    end
end