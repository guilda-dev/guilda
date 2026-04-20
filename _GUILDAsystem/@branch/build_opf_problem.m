function [prob, x0, const] = build_opf_problem(obj, prob, x0, const, Vvar, option)
% This function requires an optimproblem class instance, which stores all "build_opf_problem" of the Bus class.
% It is designed to be called internally from the "build_opf_problem" method of the @PowerNetwork class.
%
% prob   @optimproblem
% x0     @struct 
% rm_V   @optimvar 
%
    arguments
        obj 
        prob  = optimproblem();
        x0    = struct()
        const = struct()
        Vvar  = struct()  
        option.methods (1,1) string {mustBeMember(option.methods,["ELD","DC OPF","AC OPF"])} = "AC OPF";
    end

    % In case "ELD", Branch dynamics are ignored.
    if option.methods == "ELD"
        return
    end
    
    % get Parameter
    para_ope  = obj.para_operation;
    
    % Branch Variables : Current / Vbusi("Varg")-Vbusj("Varg")
    str_bus = string(obj.a_Bus);
    Vbusi = Vvar.(str_bus(1));
    Vbusj = Vvar.(str_bus(2));
    if ~isnan(para_ope.Vargij_max) && ~isinf(para_ope.Vargij_max)
        str = string(obj);
        Vm  = para_ope.Vargij_max;
        prob.Constraints.("VargMax1_"+str) = (Vbusi("Varg")-Vbusj("Varg")) <=  Vm;
        prob.Constraints.("VargMax2_"+str) = (Vbusi("Varg")-Vbusj("Varg")) >= -Vm;
    end

    str  = string(obj.a_Cubicle);
    Convar = ["P_","Q_"] + string(obj.a_Bus);
    switch option.methods
        case "AC OPF"
            % var   = ["P";"Q";"Ireal";"Iimag"];
            var   = {'P','Q','Ireal','Iimag'};
            % para_ope.Iij_max
            ub    = [ para_ope.Pij_max; para_ope.Qij_max; inf; inf];
            lb    = [-para_ope.Pij_max;-para_ope.Qij_max;-inf;-inf];
            ub(isnan(ub)) =  inf;
            lb(isnan(lb)) = -inf;
  
            varji = optimvar(str(1), var, 1, "LowerBound",lb, "UpperBound",ub);
            varij = optimvar(str(2), var, 1, "LowerBound",lb, "UpperBound",ub);

            x0.(str(1)) = zeros(4,1);
            x0.(str(2)) = zeros(4,1);

            % define Iij/Iji and Constraint
            rm_Yij  = - obj.get_admittance_matrix; % << The direction into the cubicle is positive, so it becomes subtraction.
            rm_Yex  = tools.complex2matrix(rm_Yij);
            
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

            if ~isnan(para_ope.Iij_max) && ~isinf(para_ope.Iij_max)
                prob.Constraints.("Imax_"+str(1)) = sqrt( varji("Ireal")^2+varji("Iimag")^2 )<= para_ope.Iij_max;
                prob.Constraints.("Imax_"+str(2)) = sqrt( varij("Ireal")^2+varij("Iimag")^2 )<= para_ope.Iij_max;
            end

            if ~isnan(para_ope.Sij_max) && ~isinf(para_ope.Sij_max)
                prob.Constraints.("Smax_"+str(1)) = Vbusi("V") * sqrt( varji("Ireal")^2+varji("Iimag")^2 ) <= para_ope.Sij_max;
                prob.Constraints.("Smax_"+str(2)) = Vbusj("V") * sqrt( varij("Ireal")^2+varij("Iimag")^2 ) <= para_ope.Sij_max;
            end
            
        case "DC OPF"
            ub  =  para_ope.Pij_max;
            lb  = -para_ope.Pij_max;
            P_i = optimvar(str(1), {'P'}, 1, "LowerBound",lb, "UpperBound",ub);
            P_j = optimvar(str(2), {'P'}, 1, "LowerBound",lb, "UpperBound",ub);
            
            x0.(str(1)) = 0;
            x0.(str(2)) = 0;

            para = obj.para_dynamics;
            yij  = 1/(para.Rij+1j*para.Xij);
            bij  = imag(yij);
            prob.Constraints.("defP_"+str(1)) = P_i == bij *(Vbusj("Varg")-Vbusi("Varg"));
            prob.Constraints.("defP_"+str(2)) = P_j == bij *(Vbusi("Varg")-Vbusj("Varg"));

            const.(Convar(1,1)) = const.(Convar(1,1)) + P_i;
            const.(Convar(2,1)) = const.(Convar(2,1)) + P_j;
            
    end

end
