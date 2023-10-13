classdef fault_unit < handle
    properties
        time    = [];
        bus_idx = [];

        is_now = false
    end
    methods
        function obj = fault_unit(time,idx)
            if nargin==2
                obj.time = time;
                obj.bus_idx = idx;
            else
                switch class(data)
                    case 'cell'
                        obj.time = time{1};
                        obj.bus_idx = time{2};
                    case {'struct','supporters.for_simulate.options.fault_unit'}
                        obj.time = time.time;
                        obj.bus_idx = time.bus_idx;
                    otherwise
                        if isempty(time)
                            return
                        else
                            error('')
                        end
                end
            end
        end

        function idx = get_bus_idx(obj,t)
            idx = [];
            if isempty(obj.time)
                return
            end

            if t == obj.time(1)
                obj.is_now = true;
            elseif t == obj.time(2)
                obj.is_now = false;
            end

            if obj.is_now
                idx = obj.bus_idx(:)';
            end
        end

    end
end