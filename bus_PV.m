classdef bus_PV < bus
    
    properties(SetAccess = private)
        Vabs
        P
    end
    
    methods
        function obj = bus_PV(P, V, shunt)
            obj@bus(shunt);
            obj.Vabs = V;
            obj.P = P;
        end
        
        function out = get_constraint(obj, Vr, Vi, P, Q)
            Vabs = norm([Vr; Vi]); %#ok
            out = [Vabs-obj.Vabs; P-obj.P]; %#ok
        end
    end
end

