function [flag,tab_PFsol,output] = initialize(obj, options)
    arguments
        obj
        options.methods (1,1) string {mustBeMember(options.methods,["powerflow calculation","optimal powerflow","calculate from Xequilibrium"])} = "powerflow calculation"
    end

    % Steady-State Power Flow Calculation
    switch options.methods
        case "powerflow calculation"
            [tab_PFsol, output, flag] = obj.calculate_powerflow;
        case "optimal powerflow"
            [tab_PFsol, output, flag] = optimize_powerflow(obj,"methods","AC OPF");
    end
    

    % distribute Qcomponent
    for i_bus = 1:numel(obj.a_Bus)
        rr_PFsol = tab_PFsol{i_bus,["Vphasor","Iphasor","P","Q"]};
        c_Vbus = rr_PFsol(1);
        c_Ibus = rr_PFsol(2);
        r_Pbus = rr_PFsol(3);
        r_Qbus = rr_PFsol(4);
        obj.a_Bus{i_bus}.set_equilibrium(c_Vbus,c_Ibus,r_Pbus,r_Qbus)
    end

    obj.str_methodPF = options.methods;
    obj.reset_odeset;
    obj.reset_edit()
end