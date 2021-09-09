classdef bus_slack < bus

    properties(SetAccess=private)
        Vabs
        Vangle
    end
    
    methods
        function obj = bus_slack(Vabs, Vangle, shunt)
            obj@bus(shunt);
            obj.Vabs = Vabs;
            obj.Vangle = Vangle;
        end
        
        function out = get_constraint(obj, Vr, Vi, P, Q)
            Vabs = norm([Vr; Vi]); %#ok
            Vangle = atan2(Vi, Vr); %#ok
            out = [Vabs-obj.Vabs; Vangle-obj.Vangle]; %#ok
        end
    end
end

