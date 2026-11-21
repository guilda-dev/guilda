function [r_P0, r_Prate] = initial_output(obj, u)
% Turbine output at the equilibrium [pu of the rated MW]: Pmech / Prate, with Prate
% resolved (NaN: the operation Pmax of the generator, 1 if not finite and positive).
    arguments (Input)
        obj
        u  % [pu] Equilibrium input of the generator (Pmech is read by name).
    end
    arguments (Output)
        r_P0     % [pu of the rated MW] Turbine output at the equilibrium.
        r_Prate  % [pu] Prate in use (rated MW of the machine divided by the system base).
    end
    r_Pmech = u(obj.a_Component.sv_u == "Pmech");    % the governor drives Pmech of its component
    r_Prate = rated_power(obj);
    r_P0 = r_Pmech / r_Prate;
end
