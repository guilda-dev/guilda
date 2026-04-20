function [prob, x0, const, Vvar] = build_opf_problem(obj, prob, x0, const, Vvar, option)
    arguments
        obj 
        prob  = optimproblem("Objective",struct("GenCost",0));
        x0    = struct();
        const = struct();
        Vvar  = struct(); 
        option.methods            (1,1) string {mustBeMember(option.methods,["ELD","DC OPF","AC OPF"])} = "AC OPF";
        option.l_includeComponent (1,1) logical = true;
    end

    Convar = [   "P","Q"] + "_" + string(obj);

    str = string(obj);
    switch option.methods
        case "AC OPF"
            opf  = obj.para_OPF;
            ope  = obj.para_operation;
            var  = optimvar(str, {'Varg','V'}, 1,     "Type",    "continuous" ,...
                                                "LowerBound", [-inf;ope.Vmin] ,...
                                                "UpperBound", [ inf;ope.Vmax] );
            Vvar.(str) = var;
        
            x0.(str) = [opf.Varg0;opf.V0];

            Gshunt = obj.para_dynamics.Gshunt;
            if Gshunt~=0
                const.(Convar(1)) = - var("V")^2 * Gshunt;
            else
                const.(Convar(1)) = 0;
            end

            Bshunt = obj.para_dynamics.Bshunt;
            if Bshunt
                const.(Convar(2)) =   var("V")^2 * Bshunt;
            else
                const.(Convar(2)) =   0;
            end

        case "DC OPF"
            var  = optimvar(str, {'Varg'}, 1, "Type","continuous");
            Vvar.(str) = var;
            x0.(str) = obj.para_OPF.Varg0;
            
            % If |V|=1, Ishunt = (G+jB) * e^(jθ)
            % Then, Pshunt+jQshunt = e^(jθ) * conj((G+jB) * e^(jθ))
            %                      = (G - jB) * e^(jθ) * e^(-jθ))
            %                      =  G - jB 
            const.(Convar(1)) = - obj.para_dynamics.Gshunt;
        
        case "ELD"
            % In case "ELD", Bus variables are not involved at all.
            var = [];
    end

    if option.l_includeComponent
        a_Com = obj.a_Component;
        for i_Com = 1:numel(a_Com)
            [prob, x0, const] = a_Com{i_Com}.build_opf_problem(prob, x0, const, var,"methods",option.methods);
        end
    end
end
