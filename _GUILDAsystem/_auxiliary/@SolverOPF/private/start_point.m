function x0 = start_point(x0, sv_bus, rm_V, s_method)
% Set the bus values of the OPF initial point from bus voltages.
%
% Sets x0.<bus> to the start voltage of each bus: [Varg; V] in "AC OPF", Varg in
% "DC OPF"; "ELD" has no bus variables. Called by build_problem (the flat start) and
% solve (the warm start).
    arguments (Input)
        x0         (1,1) struct  % Initial values by variable name.
        sv_bus     (:,1) string  % Bus tags (row names of the bus table).
        rm_V       (:,2) double  % [rad, pu] Start Varg and V of each bus of sv_bus.
        s_method   (1,1) string  % "ELD", "DC OPF" or "AC OPF".
    end
    arguments (Output)
        x0  % Initial values with the bus values set.
    end
    if s_method == "ELD"
        return
    end
    for i_bus = 1:numel(sv_bus)
        if s_method == "AC OPF"
            x0.(sv_bus(i_bus)) = rm_V(i_bus,:).';
        else
            x0.(sv_bus(i_bus)) = rm_V(i_bus,1);
        end
    end
end
