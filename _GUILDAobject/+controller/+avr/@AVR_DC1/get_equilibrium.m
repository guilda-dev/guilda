function [rv_Xequilibrium, rv_Uequilibrium] = get_equilibrium(obj, V, u, x) %#ok<INUSD>
% Return the equilibrium state and reference voltage of the AVR (Component.set_equilibrium calls its PSS; nothing is stored).
% The reference `Vref` is chosen so that the field voltage equals the
% generator's equilibrium field voltage `u(2)`; `Vpss` is 0 at the equilibrium.
% When `Limiter` is true, an error is raised when the required amplifier output is
% outside `(Vap_min, Vap_max)` or when `u(2)` is outside `[Vfld_min, Vfld_max]`.
% `kap = 0` is always an error, whatever `Limiter` is.
    arguments (Input)
        obj
        V  % [pu] Complex terminal voltage of the generator at the equilibrium.
        u  % [pu] Equilibrium input of the generator `[Pmech; Vfield]`.
        x = zeros(0,1)  % State of the component at the point (unused).
    end
    arguments (Output)
        rv_Xequilibrium  % Equilibrium state in the order of `sv_x`.
        rv_Uequilibrium  % Equilibrium input in the order of `sv_u`.
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
    Limiter  = tab{:, 'Limiter' };

    Vfld_st = u(2);
    if Limiter && (Vfld_st < Vfld_min || Vfld_st > Vfld_max)
        error(msg("GUILDA:AVR_DC1:FieldOutOfRange", char(obj.s_tag), num2str(Vfld_st), num2str(Vfld_min), num2str(Vfld_max)))
    end
    Vap_st  = Vfld_st*(aex1 + aex2*exp(bex*Vfld_st));
    
    if Limiter && (Vap_st <= Vap_min || Vap_st >= Vap_max)
        error(msg("GUILDA:AVR_DC1:InvalidValueRange", char(obj.s_tag), num2str(Vap_st), num2str(Vap_min), num2str(Vap_max)))
    end
    if kap == 0
        error(msg("GUILDA:AVR_DC1:ZeroGain", char(obj.s_tag), num2str(Vap_st)))
    end
    Vcom_st = Vap_st/kap;            
    Vref_st = abs(V) + Vcom_st;
    Vtr_st  = abs(V);
    Vst_st  = 0;
    Vpss_st = 0;

    rv_Xequilibrium = [Vtr_st; Vap_st; Vfld_st; Vst_st];
    rv_Uequilibrium = [Vref_st;Vpss_st];            
end
