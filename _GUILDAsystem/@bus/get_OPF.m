function optim = get_OPF(obj,opt)
% 
% %%%%%%%%%%%%%%%%%%%%%%%%
% %% AC OPF + shunt~=0 %%%
% %%%%%%%%%%%%%%%%%%%%%%%%
%
%  x = |  θ   | , x0 = |0| , |-pi/2| <= x <= |pi/2|
%      |  V   |        |1|   |-Vmin|         |Vmax|
%      |Pshunt|        |0|   |-inf |         | inf|
%      |Qshunt|        |0|   |-inf |         | inf|
%                             =====           ====
%                              lb              ub
%
%  PQ equation
%      |Pi|   | 0, 0,-1, 0 |   |   θ  |
%      |Qi| = | 0, 0, 0,-1 | * |   V  |
%               ==========     |Pshunt|
%                   Aeq        |Qshunt|
%                               ======
%                                  x
% 
%  Constraint
%      |0|   |Pshunt|   | real( vi * conj( (g-bj)*vi ) ) |
%      |0| = |Qshunt| - | imag( vi * conj( (g-bj)*vi ) ) |
%
% 
% %%%%%%%%%%%%%%%%%%%%%%%%
% %% AC OPF + shunt==0 %%%
% %%%%%%%%%%%%%%%%%%%%%%%%
%
%  x = |θ| , x0 = |0| , |-pi/2| <= x <= |pi/2|
%      |V|        |1|   | Vmin|         |Vmax|
%                        =====           ====
%                         lb              ub
%                        
% 
%  Constraint
%      []
% 
%
%
% %%%%%%%%%%%%%
% %% DC OPF %%%
% %%%%%%%%%%%%%
%
%  x = |θ| , x0 = |0| , |-pi/2| <= x <= |pi/2|
%                        =====           ====
%                       rvec_lb         rvec_ub
%
% 
%  Constraint
%      ||
%        
    arguments
        obj 
        opt.method     (1,1) string {mustBeMember(opt.method  ,["AC","DC","ELD"])} = "AC"
        opt.shunt      (1,1) double =  obj.shunt;
        opt.V_min      (1,1) double =  obj.parameter.Vmin;
        opt.V_max      (1,1) double =  obj.parameter.Vmax;
        opt.theta_min  (1,1) double = -pi/2;
        opt.theta_max  (1,1) double =  pi/2;
        opt.Pshunt_max (1,1) double =  inf
        opt.Qshunt_max (1,1) double =  inf
    end

    switch opt.method
        case "AC"
            if opt.shunt==0
                str_x = ["theta";"V";"Pshunt";"Qshunt"] + obj.index; 
                optim = supporters.OptimFactory(str_x,[]);
                optim.x0 = [0;1;0;0];
                optim.lb = [theta_min; V_min; -opt.Pshunt_max; -opt.Qshunt_max];
                optim.ub = [theta_max; V_max;  opt.Pshunt_max;  opt.Qshunt_max];
                
                % 等式制約(線形)
                %       θ   V  Pshunt Qshunt
                Aeq = [ 0,  0,    -1,    0 ;...
                        0,  0,     0,   -1 ];           
                beq = [  0;   0];
                optim.add_eq( Aeq, beq, ["P";"Q"]+obj.index )


                % 等式制約(非線形)
                x   = optim.x;
                PQ  = x([3;4]);
                Vi  = x(2) * ( cos(x(1)) + 1j* sin(x(2)) );
                Ii  = opt.shunt*Vi;
                PQi = Vi*conj(Ii);
                const = simplify( PQ - [real(PQi);imag(PQi)] );
                optim.add_nonleq( const, str_x([3;4]) );

            else
                str_x = ["theta";"V"] + obj.index; 
                optim = supporters.OptimFactory(str_x,[]);
                optim.x0 = [0;1];
                optim.lb = [opt.theta_min; opt.V_min];
                optim.ub = [opt.theta_max; opt.V_max];

            end

        case "DC"
            str_x = "theta" + obj.index; 
            optim = supporters.OptimFactory(str_x,[]);
            optim.x0 = 0;
            optim.lb = opt.theta_min;
            optim.ub = opt.theta_max;

        case "ELD"
            optim = supporters.OptimFactory([],[]);
            
    end
end