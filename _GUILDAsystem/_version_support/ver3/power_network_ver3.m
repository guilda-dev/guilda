classdef power_network_ver3  < power_network
    methods
        function cls = a_bus(obj)
            cls = obj.Buses;
        end
        function cls = a_branch(obj)
            cls = obj.Branches;
        end
        function cls = a_controller_local(obj)
            cls = obj.LocalControllers;
        end
        function cls = a_controller_global(obj)
            cls = obj.GlobalControllers;
        end
    end
end