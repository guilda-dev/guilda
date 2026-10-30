function [prob, x0, const, Vvar] = build_opf_problem(obj, prob, x0, const, Vvar, option)
% Add the variables and constraints of the bus to an OPF problem.
%
% Called by PowerNetwork.build_opf_problem for each bus; the bus also adds its
% components unless `l_includeComponent` is false.
%
% See also PowerNetwork.build_opf_problem, Component.build_opf_problem
    arguments
        obj 
        prob  = optimproblem("Objective",struct("GenCost",0));   % optimproblem to extend.
        x0    = struct();   % Struct of initial values, extended.
        const = struct();   % Struct of power-balance expressions, extended.
        Vvar  = struct();   % Struct of bus variables, extended.
        option.methods            (1,1) string {mustBeMember(option.methods,["ELD","DC OPF","AC OPF"])} = "AC OPF";   % OPF formulation: "ELD", "DC OPF" or "AC OPF".
        option.l_includeComponent (1,1) logical = true;   % Also add the components of the bus.
    end
    arguments (Output)
        prob    % Extended optimproblem.
        x0      % Extended initial values.
        const   % Extended power-balance expressions.
        Vvar    % Extended bus variables.
    end

    Convar = [   "P","Q"] + "_" + string(obj);

    str = string(obj);
    switch option.methods
        case "AC OPF"
            opf  = obj.para_powerflow;   % initial point (Varg0, V0)
            ope  = obj.para_operation;
            Vlim = [ope.Vmin; ope.Vmax];
            if ~obj.s_opffcn.DefaultConstraint   % set_opffcn: no default voltage bounds
                Vlim = [-inf; inf];
            end
            var  = optimvar(str, {'Varg','V'}, 1,     "Type",    "continuous" ,...
                                                "LowerBound", [-inf;Vlim(1)] ,...
                                                "UpperBound", [ inf;Vlim(2)] );
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
            x0.(str) = obj.para_powerflow.Varg0;
            
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

    % set_opffcn terms of the bus ("ELD" has no bus variables)
    if option.methods ~= "ELD"
        prob = opffcn.apply(obj, prob, option.methods, struct(str, var));
    end
end
