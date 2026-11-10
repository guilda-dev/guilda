function set_equilibrium(obj, c_V, c_I, r_P, r_Q, opt)
% Set the bus voltage and distribute P and Q of the equilibrium to the components.
%
% Called by PowerNetwork.initialize. The slack bus gives the remaining P to its first
% component whose Q is NaN; Q goes to the components whose Q is NaN, split by
% `QdistributionRule` (tools.distribute_power). A slack bus without such components gives both to its first component.
% With `rm_PQ` the components take the given powers instead, and r_P and r_Q are not used.
% With `c_XU` the components store the given states and inputs (Component.set_equilibrium).
%
% <@Group> Called by analyses
    arguments (Input)
        obj 
        c_V   % [pu] Bus voltage phasor.
        c_I   % [pu] Bus current injection phasor.
        r_P = real( c_V*conj(c_I) );   % [pu] Active power injection.
        r_Q = imag( c_V*conj(c_I) );   % [pu] Reactive power injection.
        opt.QdistributionRule (1,1) string {mustBeMember(opt.QdistributionRule,["baseMVA","Qmax"])} = "baseMVA";   % Split of Q: "baseMVA" (by rating) or "Qmax" (by the Q range).
        opt.c_XU cell = {};      % {x, u} of each component, one row per component (initialize(Method="FixedInput")). Default {} computes them with get_equilibrium.
        opt.rm_PQ double = [];   % [pu] [P Q] of each component, one row per component (e.g. the OPF solution). Default [] distributes r_P and r_Q from tab_parameter.powerflow.
    end
    
    % The bus owns V. Its current is the sum of the component currents
    % (Dependent), so c_I is only used for the default r_P and r_Q.
    obj.c_Vequilibrium = c_V;

    a_Comp = obj.a_Component;
    n_Comp = numel(a_Comp);
    if isempty(opt.rm_PQ)
        rm_PQcomp = tools.distribute_power(obj, r_P, r_Q, opt.QdistributionRule);
    else
        rm_PQcomp = opt.rm_PQ;
    end

    % @Component set_equilibrium
    for i = 1:n_Comp
        rr_PQi = rm_PQcomp(i,:);
        r_Pi   = rr_PQi(1);
        r_Qi   = rr_PQi(2);
        c_Ii   = conj( rr_PQi*[1;1j] / c_V );
        if isempty(opt.c_XU)
            a_Comp{i}.set_equilibrium(c_V,c_Ii,r_Pi,r_Qi);
        else
            a_Comp{i}.set_equilibrium(c_V,c_Ii,r_Pi,r_Qi,"c_XU",opt.c_XU(i,:));
        end
    end
end

