function [rv_Xequilibrium, rv_Uequilibrium] = get_equilibrium(obj, V, u, x) %#ok<INUSD>
% Return the equilibrium state and reference voltage of the AVR (Component.set_equilibrium calls its PSS; nothing is stored).
% The reference `Vref` is chosen so that the field voltage equals the
% generator's equilibrium field voltage `u(2)`; `Vpss` is 0 at the equilibrium.
% `Ifield` equals `Vfield` at the equilibrium (the field equation is at rest).
% An error is raised when `Limiter` is true and the required amplifier output is
% outside `(Vap_min, Vap_max)` or the output limits `(gamma_min*|V|, gamma_max*|V| - k0*Ifield)`.
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
    kap     = tab{:, 'kap'    };

    Vap_st    = u(2);            
    Ifield_st = u(2);
    
    % Limits on the output at the equilibrium: the amplifier limits and the output limits
    r_max = Vap_max;
    r_min = Vap_min;
    if tab{:, 'gamma_max'} < Inf
        r_max = min(r_max, tab{:, 'gamma_max'}*abs(V) - tab{:, 'k0'}*Ifield_st);
    end
    if tab{:, 'gamma_min'} > -Inf
        r_min = max(r_min, tab{:, 'gamma_min'}*abs(V));
    end
    if tab{:, 'Limiter'} && (Vap_st <= r_min || Vap_st >= r_max)
        error(msg("GUILDA:AVR_ST1:InvalidValueRange", char(obj.s_tag), num2str(Vap_st), num2str(r_min), num2str(r_max)))
    end

    Vst_st  = 0;
    Vcom_st = Vap_st/kap;                        
    Vtr_st  = abs(V);            
    Vref_st = Vcom_st + Vtr_st;
    Vpss_st = 0;

    rv_Xequilibrium = [Vtr_st; Vap_st; Vst_st];
    rv_Uequilibrium = [Vref_st; Vpss_st; Ifield_st];            
end
