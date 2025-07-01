function [flag,output,dataSheet] = initialize(obj,opt)
    arguments
        obj 
        opt.method (1,1) string {mustBeMember(opt.method,["PF","AC OPF"])} = "PF";
    end
    switch opt.method
        case "PF" 
            [dataSheet, flag, output] = obj.calculate_power_flow;
        case "AC OPF"
            [dataSheet, flag, output] = obj.optimize_power_flow;
    end
    obj.set_equilibrium(dataSheet,opt.method);
end