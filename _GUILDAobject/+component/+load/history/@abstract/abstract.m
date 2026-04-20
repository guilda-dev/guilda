classdef abstract < Component

    properties
        porttype = 'rate';
    end

    methods
        function obj = abstract()
            obj@Component()
            obj.parameter.powerflow{1,["theta","V","P","Q"]} = [nan, nan, -1, -1];
            obj.parameter.OPF{1,["P_min","P_max","Q_min","Q_max"]} = [-1.0,-0.1,-1.5,0.5];
            obj.tag = 'Load';
        end
    end
    methods
        M   = Mass(obj)
    end
    methods
        xst = get_xequilibrium(obj, c_V, c_I)
        dx  = fcn_dx(obj, r_time, rvec_x, c_V, rvec_u)
        y   = fcn_y( obj, r_time, rvec_x, c_V)
    end

end
