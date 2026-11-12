function r_P0 = initial_output(obj, u)
% Turbine output at the equilibrium [pu of the rated MW]: Pmech / Prate.
    arguments (Input)
        obj
        u  % [pu] Equilibrium input of the generator (Pmech is read by name).
    end
    arguments (Output)
        r_P0  % [pu of the rated MW] Turbine output at the equilibrium.
    end
    r_Pmech = u(obj.a_Component.sv_u == "Pmech");    % the governor drives Pmech of its component
    r_P0 = r_Pmech / obj.tab_parameter.dynamics{:, 'Prate'};
end
