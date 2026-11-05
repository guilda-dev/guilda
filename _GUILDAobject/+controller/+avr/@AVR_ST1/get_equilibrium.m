function get_equilibrium(obj, V, u)                   
% Set the equilibrium state and reference voltage of the AVR and of its PSS.
% The reference `Vref` is chosen so that the field voltage equals the
% generator's equilibrium field voltage `u(2)`; `Vpss` is 0 at the equilibrium.
% An error is raised when the required amplifier output is outside `[Vap_min, Vap_max]`.
    arguments (Input)
        obj
        V    % [pu] Complex terminal voltage of the generator at the equilibrium.
        u    % [pu] Equilibrium input of the generator `[Pmech; Vfield]`.
    end
    tab = obj.tab_parameter.dynamics;
    Vap_max = tab{:, 'Vap_max'};
    Vap_min = tab{:, 'Vap_min'};            
    kap     = tab{:, 'kap'    };

    Vap_st = u(2);            
    
    if Vap_st <= Vap_min || Vap_st >= Vap_max
        error(msg("GUILDA:AVR_ST1:InvalidValueRange", char(obj.s_tag), num2str(Vap_st), num2str(Vap_min), num2str(Vap_max)))
    end

    Vst_st  = 0;
    Vcom_st = Vap_st/kap;                        
    Vtr_st  = abs(V);            
    Vref_st = Vcom_st + Vtr_st;
    Vpss_st = 0;

    obj.rv_Xequilibrium = [Vtr_st; Vap_st; Vst_st];
    obj.rv_Uequilibrium = [Vref_st;Vpss_st];            

    cellfun(@(c) c.get_equilibrium(V,u), obj.a_LocalController);
end
