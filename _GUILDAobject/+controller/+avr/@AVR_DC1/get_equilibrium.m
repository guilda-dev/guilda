function get_equilibrium(obj, V, u)                   
% Set the equilibrium state and reference voltage of the AVR and of its PSS.
% The reference `Vref` is chosen so that the field voltage equals the
% generator's equilibrium field voltage `u(2)`; `Vpss` is 0 at the equilibrium.
% An error is raised when the required amplifier output is outside `(Vap_min, Vap_max)`
% or when `u(2)` is outside `[Vfld_min, Vfld_max]`.
    arguments (Input)
        obj
        V    % [pu] Complex terminal voltage of the generator at the equilibrium.
        u    % [pu] Equilibrium input of the generator `[Pmech; Vfield]`.
    end
    tab = obj.tab_parameter.dynamics;
    Vap_max = tab{:, 'Vap_max'};
    Vap_min = tab{:, 'Vap_min'};
    aex1    = tab{:, 'aex1'   };
    aex2    = tab{:, 'aex2'   };
    bex     = tab{:, 'bex'    };
    kap     = tab{:, 'kap'    };
    Vfld_max = tab{:, 'Vfld_max'};
    Vfld_min = tab{:, 'Vfld_min'};

    Vfld_st = u(2);
    if Vfld_st < Vfld_min || Vfld_st > Vfld_max
        error(msg("GUILDA:AVR_DC1:FieldOutOfRange", char(obj.s_tag), num2str(Vfld_st), num2str(Vfld_min), num2str(Vfld_max)))
    end
    Vap_st  = Vfld_st*(aex1 + aex2*exp(bex*Vfld_st));
    
    if Vap_st <= Vap_min || Vap_st >= Vap_max
        error(msg("GUILDA:AVR_DC1:InvalidValueRange", char(obj.s_tag), num2str(Vap_st), num2str(Vap_min), num2str(Vap_max)))
    end
    Vcom_st = Vap_st/kap;            
    Vref_st = abs(V) + Vcom_st;
    Vtr_st  = abs(V);
    Vst_st  = 0;
    Vpss_st = 0;

    obj.rv_Xequilibrium = [Vtr_st; Vap_st; Vfld_st; Vst_st];
    obj.rv_Uequilibrium = [Vref_st;Vpss_st];            

    cellfun(@(c) c.get_equilibrium(V,u), obj.a_LocalController);
end
