function [sys,lin] = get_sys(obj, opt)
    arguments
        obj 
        opt.NonUnit   (1,:) double = [];
        opt.Algorithm (1,1) {mustBeMember(opt.Algorithm, ["Kron", "Feedback", "DAE"])} = "Feedback" 
    end
    obj.check_edit("RequireEquilibrium", true);    % rebuild stale f_*; error if net.initialize() is needed
    lin = odeLinearizer(obj, opt.NonUnit, "Algorithm", opt.Algorithm);
    sys = lin.get_sys;
end