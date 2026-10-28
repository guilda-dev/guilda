function [flag,tab_PFsol,output] = initialize(obj, options)
    arguments
        obj
        options.methods (1,1) string {mustBeMember(options.methods,["powerflow calculation","optimal powerflow","calculate from Xequilibrium"])} = "powerflow calculation"
    end

    % Steady-State Power Flow Calculation
    switch options.methods
        case "powerflow calculation"
            [tab_PFsol, flag, output] = obj.calculate_powerflow;
        case "optimal powerflow"
            [tab_PFsol, ~, flag, output] = optimize_powerflow(obj,"methods","AC OPF");
        case "calculate from Xequilibrium"
            [tab_PFsol, flag, output] = calculate_from_equilibrium(obj);
    end

    if ~isempty(obj.a_GlobalController)
        a_GC = obj.a_GlobalController{1};
        [a_GC.rv_Xequilibrium, a_GC.rv_Uequilibrium] = a_GC.get_equilibrium();
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

    % reset log
    obj.reset_edit()
end


function [tab_PFsol, flag, output] = calculate_from_equilibrium(obj)
% Build the bus equilibrium from the equilibria stored in the components
%   Vbus : the voltage the components on the bus hold
%   Ibus : the sum of the currents the components on the bus inject
%   Buses without components inject no current; their voltage is solved from Y*V = I.

    str_Bus = string(obj.a_Bus);
    n_Bus   = numel(str_Bus);
    tab_Y   = obj.get_admittance_matrix;
    cm_Y    = tab_Y{str_Bus,str_Bus};

    cv_Vbus  = nan(n_Bus,1);
    cv_Ibus  = zeros(n_Bus,1);
    lv_known = false(n_Bus,1);
    for i_bus = 1:n_Bus
        a_Comp = obj.a_Bus{i_bus}.a_Component;
        for i_comp = 1:numel(a_Comp)
            comp = a_Comp{i_comp};
            if isempty(comp.c_Vequilibrium) || isempty(comp.c_Iequilibrium)
                error("ERROR: The equilibrium of '"+string(comp)+"' is not set."+newline+...
                      "       Run initialize with ""powerflow calculation"" or ""optimal powerflow"" first.")
            end
            cv_Vbus(i_bus)  = comp.c_Vequilibrium;
            cv_Ibus(i_bus)  = cv_Ibus(i_bus) + comp.c_Iequilibrium;
            lv_known(i_bus) = true;
        end
    end

    % voltage of the buses without components (zero injection)
    if any(~lv_known)
        cv_Vbus(~lv_known) = - cm_Y(~lv_known,~lv_known) \ (cm_Y(~lv_known,lv_known)*cv_Vbus(lv_known));
    end

    % consistency check: Kirchhoff's current law at every bus
    tol     = 1e-6;
    r_resid = max(abs(cm_Y*cv_Vbus - cv_Ibus));
    flag    = double(r_resid < tol);
    output  = struct("residual", r_resid);
    if flag > 0
        output.message = "The equilibria of the components satisfy the network equations.";
    else
        output.message = "The equilibria of the components do not satisfy the network equations (max |Y*V-I| = "+r_resid+").";
        warning(output.message)
    end

    cv_Sbus   = cv_Vbus .* conj(cv_Ibus);
    tab_PFsol = array2table(...
        [angle(cv_Vbus),abs(cv_Vbus),real(cv_Sbus),imag(cv_Sbus),cv_Vbus,cv_Ibus], ...
        "VariableNames",["Varg","V","P","Q","Vphasor","Iphasor"],"RowNames",str_Bus);
end
