function [sys,lin] = get_sys(obj, opt)
    arguments
        obj 
        opt.Algorithm (1,1) {mustBeMember(opt.Algorithm, ["Kron", "Feedback", "DAE"])} = "Feedback" 
    end
    lin = odeLinearizer(obj, 7, "Algorithm", opt.Algorithm);
    sys = lin.get_sys;
end