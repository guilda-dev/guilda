classdef bus_PQ < bus
    
    properties(SetAccess=private)
        P
        Q
    end
    
    methods
        function obj = bus_PQ(P, Q, shunt)
            obj@bus(shunt);
            obj.P = P;
            obj.Q = Q;
        end
        
        function out = get_constraint(obj, Vr, Vi, P, Q)
            out = [P-obj.P; Q-obj.Q];
        end
    end
end

