function u_name = naming_port(obj)
% Return the input port names (v1 interface).
    arguments (Input)
        obj
    end
    arguments (Output)
        u_name  % Input port names {'RealPower','ReactivePower'}.
    end
    u_name = {'RealPower','ReactivePower'};
end
