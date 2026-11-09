function [prob, x0, const, var] = build_bus(bus, prob, x0, const, s_method, rv_init)
% Add the variables and shunt power of one bus to the OPF problem.
%
% "AC OPF": variable <bus> = [Varg; V] with Vmin <= V <= Vmax (tab_parameter.operation;
% ±Inf removes a bound) and the shunt power -V^2*Gshunt, V^2*Bshunt in the balance.
% "DC OPF": variable <bus> = Varg and the shunt power -Gshunt (|V| = 1). "ELD": none.
    arguments (Input)
        bus                    % Bus to add.
        prob                   % Problem being built.
        x0       (1,1) struct  % Initial values, extended.
        const    (1,1) struct  % Power-balance expressions by "P_<bus>" / "Q_<bus>", extended.
        s_method (1,1) string  % "ELD", "DC OPF" or "AC OPF".
        rv_init  (1,2) double  % [rad, pu] Initial Varg and V of the bus.
    end
    arguments (Output)
        prob                   % Problem (unchanged; kept for a uniform signature).
        x0                     % Extended initial values.
        const                  % Extended power-balance expressions.
        var                    % Variable of the bus; [] in "ELD".
    end
    sv_con = ["P","Q"] + "_" + string(bus);
    s_bus  = string(bus);
    dyn    = group(bus, "dynamics");
    switch s_method
        case "AC OPF"
            ope = group(bus, "operation");
            var = optimvar(s_bus, {'Varg','V'}, 1, "Type","continuous", ...
                           "LowerBound", [-inf; ope.Vmin], ...
                           "UpperBound", [ inf; ope.Vmax]);
            x0.(s_bus) = rv_init(:);

            if dyn.Gshunt ~= 0
                const.(sv_con(1)) = - var("V")^2 * dyn.Gshunt;
            else
                const.(sv_con(1)) = 0;
            end
            if dyn.Bshunt
                const.(sv_con(2)) =   var("V")^2 * dyn.Bshunt;
            else
                const.(sv_con(2)) =   0;
            end

        case "DC OPF"
            var = optimvar(s_bus, {'Varg'}, 1, "Type","continuous");
            x0.(s_bus) = rv_init(1);
            % With |V| = 1 the shunt draws Pshunt + jQshunt = G - jB.
            const.(sv_con(1)) = - dyn.Gshunt;

        case "ELD"
            var = [];
    end
end


function tab = group(obj, s_group)
    tab = obj.a_Parameter{cellfun(@(p) p.s_tag==s_group, obj.a_Parameter)}.tab_parameter;
end
