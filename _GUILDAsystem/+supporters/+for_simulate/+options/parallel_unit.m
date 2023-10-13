classdef parallel_unit < handle
    properties
        time  = [];
        index = [];
        onoff = 'off';
        a_component
    end

    properties(Access=protected)
        net
    end


    methods
        function obj = parallel_unit(time,complist,onoff)
            if nargin==3
                obj.time = time;
                obj.index = complist;
                obj.onoff = onoff;
            elseif  nargin==2
                obj.time = time;
                obj.index = complist;
                obj.onoff = 'off';
            else
                switch class(data)
                    case 'cell'
                        obj.time = time{1};
                        obj.index = time{2};
                        obj.onoff = time{3};
                    case {'struct','supporters.for_simulate.option.parallel_unit'}
                        obj.time = time.time;
                        obj.index = time.index;
                        obj.onoff = time.onoff;
                    otherwise
                        error('')
                end
            end
        end

        function register_net(obj,net)
            obj.net = net;
            obj.a_component = tools.arrayfun(@(i) net.a_bus{i}.component, obj.index(:));
        end


        function set_time(obj,t)
            if ~isempty(obj.time) && t == obj.time
                switch obj.onoff
                    case 'on'
                        cellfun(@(c) c.connect,    obj.a_component)
                    case 'off'
                        cellfun(@(c) c.disconnect, obj.a_component)
                end
            end
        end
    end
end