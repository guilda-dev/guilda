function [sys,lin] = get_sys(obj, opt)
    arguments
        obj 
        opt.NonUnit   (1,:) double = [];
        opt.Algorithm (1,1) {mustBeMember(opt.Algorithm, ["Kron", "Feedback", "DAE"])} = "Feedback" 
    end
    lin = odeLinearizer(obj, opt.NonUnit, "Algorithm", opt.Algorithm);
    sys = lin.get_sys;
end