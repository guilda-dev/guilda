function r_P0 = initial_output(obj, u)
% Turbine output at the equilibrium [pu of the rated MW]: Pmech / Prate.
    arguments (Input)
        obj
        u  % [pu] Equilibrium input of the generator (Pmech is read by name).
    end
    arguments (Output)
        r_P0  % [pu of the rated MW] Turbine output at the equilibrium.
    end
    comp = obj.a_Component;
    r_Pmech = u(1);
    if isa(comp, "Component") && any(comp.sv_u == "Pmech")
        r_Pmech = u(comp.sv_u == "Pmech");
    end
    r_P0 = r_Pmech / obj.tab_parameter.dynamics{:, 'Prate'};
end
