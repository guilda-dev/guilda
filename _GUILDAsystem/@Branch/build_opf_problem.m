function [prob, x0, const] = build_opf_problem(obj, prob, x0, const, Vvar, option)
% Add the flow variables and limits of the branch to an OPF problem.
%
% Called by PowerNetwork.build_opf_problem after the buses have added their variables
% to `Vvar`. The power flowing from the branch into each end bus is added to the power
% balance in `const`. "ELD" ignores branches and returns the inputs unchanged.
%
% See also PowerNetwork.build_opf_problem, Bus.build_opf_problem, Branch.set_opffcn
    arguments
        obj 
        prob  = optimproblem();   % optimproblem to extend.
        x0    = struct()   % Struct of initial values, extended.
        const = struct()   % Struct of power-balance expressions, extended.
        Vvar  = struct()   % Struct of bus variables by bus tag (from Bus.build_opf_problem).
        option.methods (1,1) string {mustBeMember(option.methods,["ELD","DC OPF","AC OPF"])} = "AC OPF";   % OPF formulation: "ELD", "DC OPF" or "AC OPF".
    end
    arguments (Output)
        prob    % Extended optimproblem.
        x0      % Extended initial values.
        const   % Extended power-balance expressions.
    end

    % In case "ELD", Branch dynamics are ignored.
    if option.methods == "ELD"
        return
    end
    
    % get Parameter (set_opffcn DefaultConstraint=false: no default limits)
    para_ope  = obj.para_operation;
    if ~obj.s_opffcn.DefaultConstraint
        para_ope = struct("Pmax",nan, "Qmax",nan, "Vargmax",nan, "Imax",nan, "Smax",nan);
    end
    
    % Branch Variables : Current / Vbusi("Varg")-Vbusj("Varg")
    str_bus = string(obj.a_Bus);
    Vbusi = Vvar.(str_bus(1));
    Vbusj = Vvar.(str_bus(2));
    if ~isnan(para_ope.Vargmax) && ~isinf(para_ope.Vargmax)
        str = string(obj);
        Vm  = para_ope.Vargmax;
        prob.Constraints.("VargMax1_"+str) = (Vbusi("Varg")-Vbusj("Varg")) <=  Vm;
        prob.Constraints.("VargMax2_"+str) = (Vbusi("Varg")-Vbusj("Varg")) >= -Vm;
    end

    % Variables of each branch end are named "<branch>_<bus>" (str(1): end at bus i, str(2): end at bus j).
    % They hold the power/current flowing from the branch into the bus.
    str  = string(obj) + "_" + str_bus;
    Convar = ["P_","Q_"] + string(obj.a_Bus);
    switch option.methods
        case "AC OPF"
            % var   = ["P";"Q";"Ireal";"Iimag"];
            var   = {'P','Q','Ireal','Iimag'};
            ub    = [ para_ope.Pmax; para_ope.Qmax; inf; inf];
            lb    = [-para_ope.Pmax;-para_ope.Qmax;-inf;-inf];
            ub(isnan(ub)) =  inf;
            lb(isnan(lb)) = -inf;
  
            varji = optimvar(str(1), var, 1, "LowerBound",lb, "UpperBound",ub);
            varij = optimvar(str(2), var, 1, "LowerBound",lb, "UpperBound",ub);

            % define Iij/Iji and Constraint
            rm_Yij  = - obj.get_admittance_matrix; % << The direction into the bus is positive, so it becomes subtraction.
            rm_Yex  = tools.complex2matrix(rm_Yij);

            % Initial point: the end values at the initial bus voltages, so that the
            % definitions below hold at x0 (a zero current is also a non-smooth point of |I|).
            rv_x0V = [x0.(str_bus(1)), x0.(str_bus(2))];
            cv_V0  = (rv_x0V(2,:) .* exp(1j*rv_x0V(1,:))).';
            cv_I0  = rm_Yij * cv_V0;
            cv_S0  = cv_V0 .* conj(cv_I0);
            x0.(str(1)) = [real(cv_S0(1)); imag(cv_S0(1)); real(cv_I0(1)); imag(cv_I0(1))];
            x0.(str(2)) = [real(cv_S0(2)); imag(cv_S0(2)); real(cv_I0(2)); imag(cv_I0(2))];
            
            prob.Constraints.("defIre_"+str(1)) = varji("Ireal") == rm_Yex(1,1) * Vbusi("V") * cos(Vbusi("Varg")) ...
                                                                  + rm_Yex(1,2) * Vbusi("V") * sin(Vbusi("Varg")) ...
                                                                  + rm_Yex(1,3) * Vbusj("V") * cos(Vbusj("Varg")) ...
                                                                  + rm_Yex(1,4) * Vbusj("V") * sin(Vbusj("Varg")) ;
            prob.Constraints.("defIim_"+str(1)) = varji("Iimag") == rm_Yex(2,1) * Vbusi("V") * cos(Vbusi("Varg")) ...
                                                                  + rm_Yex(2,2) * Vbusi("V") * sin(Vbusi("Varg")) ...
                                                                  + rm_Yex(2,3) * Vbusj("V") * cos(Vbusj("Varg")) ...
                                                                  + rm_Yex(2,4) * Vbusj("V") * sin(Vbusj("Varg")) ;
            prob.Constraints.("defIre_"+str(2)) = varij("Ireal") == rm_Yex(3,1) * Vbusi("V") * cos(Vbusi("Varg")) ...
                                                                  + rm_Yex(3,2) * Vbusi("V") * sin(Vbusi("Varg")) ...
                                                                  + rm_Yex(3,3) * Vbusj("V") * cos(Vbusj("Varg")) ...
                                                                  + rm_Yex(3,4) * Vbusj("V") * sin(Vbusj("Varg")) ;
            prob.Constraints.("defIim_"+str(2)) = varij("Iimag") == rm_Yex(4,1) * Vbusi("V") * cos(Vbusi("Varg")) ...
                                                                  + rm_Yex(4,2) * Vbusi("V") * sin(Vbusi("Varg")) ...
                                                                  + rm_Yex(4,3) * Vbusj("V") * cos(Vbusj("Varg")) ...
                                                                  + rm_Yex(4,4) * Vbusj("V") * sin(Vbusj("Varg")) ;
            
            % define P/Q/S and Constraint

            P_i    = varji("P");
            Q_i    = varji("Q");
            P_j    = varij("P");
            Q_j    = varij("Q");   
            prob.Constraints.("defP_"+str(1)) = P_i == ( varji("Ireal")*Vbusi("V") * cos(Vbusi("Varg")) + varji("Iimag")*Vbusi("V") * sin(Vbusi("Varg")) );
            prob.Constraints.("defP_"+str(2)) = P_j == ( varij("Ireal")*Vbusj("V") * cos(Vbusj("Varg")) + varij("Iimag")*Vbusj("V") * sin(Vbusj("Varg")) );
            prob.Constraints.("defQ_"+str(1)) = Q_i == ( varji("Ireal")*Vbusi("V") * sin(Vbusi("Varg")) - varji("Iimag")*Vbusi("V") * cos(Vbusi("Varg")) );
            prob.Constraints.("defQ_"+str(2)) = Q_j == ( varij("Ireal")*Vbusj("V") * sin(Vbusj("Varg")) - varij("Iimag")*Vbusj("V") * cos(Vbusj("Varg")) );

            const.(Convar(1,1)) = const.(Convar(1,1)) + P_i;
            const.(Convar(1,2)) = const.(Convar(1,2)) + Q_i;
            const.(Convar(2,1)) = const.(Convar(2,1)) + P_j;
            const.(Convar(2,2)) = const.(Convar(2,2)) + Q_j;

            % Squared limits |I|^2 <= Imax^2 and |S|^2 = P^2+Q^2 <= Smax^2: smooth everywhere,
            % unlike sqrt(), whose derivative is undefined at zero.
            if ~isnan(para_ope.Imax) && ~isinf(para_ope.Imax)
                prob.Constraints.("Imax_"+str(1)) = varji("Ireal")^2 + varji("Iimag")^2 <= para_ope.Imax^2;
                prob.Constraints.("Imax_"+str(2)) = varij("Ireal")^2 + varij("Iimag")^2 <= para_ope.Imax^2;
            end

            if ~isnan(para_ope.Smax) && ~isinf(para_ope.Smax)
                prob.Constraints.("Smax_"+str(1)) = P_i^2 + Q_i^2 <= para_ope.Smax^2;
                prob.Constraints.("Smax_"+str(2)) = P_j^2 + Q_j^2 <= para_ope.Smax^2;
            end
            
        case "DC OPF"
            ub  =  para_ope.Pmax;
            lb  = -para_ope.Pmax;
            if isnan(ub); ub = inf; lb = -inf; end
            P_i = optimvar(str(1), {'P'}, 1, "LowerBound",lb, "UpperBound",ub);
            P_j = optimvar(str(2), {'P'}, 1, "LowerBound",lb, "UpperBound",ub);
            
            % |V|=1, lossless, MATPOWER convention (makeBdc): the flow from bus i to bus j is
            % b*(θi - θj - phase) with b = 1/(X*tap); the power into bus i is its negative.
            [b, phase] = dc_susceptance(obj.para_dynamics);
            prob.Constraints.("defP_"+str(1)) = P_i == b *(Vbusj("Varg")-Vbusi("Varg")+phase);
            prob.Constraints.("defP_"+str(2)) = P_j == b *(Vbusi("Varg")-Vbusj("Varg")-phase);

            % Initial point: the end values at the initial bus angles
            x0.(str(1)) = b *(x0.(str_bus(2))-x0.(str_bus(1))+phase);
            x0.(str(2)) = b *(x0.(str_bus(1))-x0.(str_bus(2))-phase);

            const.(Convar(1,1)) = const.(Convar(1,1)) + P_i;
            const.(Convar(2,1)) = const.(Convar(2,1)) + P_j;
            
    end

    % set_opffcn terms of the branch
    prob = opffcn.apply(obj, prob, option.methods);
end


function [b, phase] = dc_susceptance(para)
% DC branch susceptance as in MATPOWER: b = 1/(X*tap), with the off-nominal tap ratio and
% the phase shift [rad] at the from end (a_Bus{1}); tap = 1 and phase = 0 for lines.
    s = table2struct(para.tab_parameter);
    tap = 1;
    phase = 0;
    if isfield(s, "tap") && ~isnan(s.tap) && s.tap ~= 0
        tap = s.tap;
    end
    if isfield(s, "phase") && ~isnan(s.phase)
        phase = s.phase;
    end
    b = 1/(s.X*tap);
end
