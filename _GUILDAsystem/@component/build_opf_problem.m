function [prob, x0, const] = build_opf_problem(obj, prob, x0, const, Busvar, option)
% This method is intended to be called internally from the "build_opf_problem" method of the Bus class.
%
% prob   @optimproblem
% x0     @struct 
% Busvar @optimvar 
%
    arguments
        obj 
        prob   = optimproblem();
        x0     = struct();
        const  = struct();
        Busvar = zeros(2,0); %#ok
        option.methods (1,1) string {mustBeMember(option.methods,["ELD","DC OPF","AC OPF"])} = "AC OPF";
    end

    % try
    
        opf  = obj.para_OPF;
        ope  = obj.para_operation;
        str  = string(obj);
    
        switch option.methods
            case "AC OPF"
                var  = optimvar(str, {'P','Q'}, 1,      "Type", "continuous"       ,...
                                                  "LowerBound",[ope.Pmin;ope.Qmin] ,...
                                                  "UpperBound",[ope.Pmax;ope.Qmax] );
                Convar  = ["P","Q"] + "_" + string(obj.a_Bus);
                const.(Convar(1)) = const.(Convar(1)) + var("P");
                const.(Convar(2)) = const.(Convar(2)) + var("Q");
                x0.(str) = [opf.P0;opf.Q0];
                prob.Objective.GenCost = prob.Objective.GenCost...
                                  + opf.HP * var("P")^2 + opf.fP * var("P") ...
                                  + opf.HQ * var("Q")^2 + opf.fQ * var("Q");
                
            case "DC OPF"
                var  = optimvar(str, {'P'}, 1, "Type"      ,"continuous" ,...
                                               "LowerBound",ope.Pmin     ,...
                                               "UpperBound",ope.Pmax     );
                Convar  = "P_" + string(obj.a_Bus);
                const.(Convar) = const.(Convar) + var;
                x0.(str)       = opf.P0;
                prob.Objective.GenCost = prob.Objective.GenCost + opf.HP * var^2 + opf.fP * var;
    
            case "ELD"
                var  = optimvar(str, {'P'}, 1, "Type"      ,"continuous" ,...
                                               "LowerBound",ope.Pmin     ,...
                                               "UpperBound",ope.Pmax     );
                const.P = const.P + var;
                x0.(str) = opf.P0;
                prob.Objective.GenCost = prob.Objective.GenCost + opf.HP * var^2 + opf.fP * var;
        end

    % catch
    %     error("Error: This method must only be called internally by Bus.build_opf_problem/")
    % end
end
