function optim = get_OPF(obj,opt)
% 
% %%%%%%%%%%%%%
% %% AC OPF %%%
% %%%%%%%%%%%%%
%
%  x = |Pij| , x0 = |0| , |-Pmax|         |Pmax|
%      |Qij|        |0|   | -inf|         | inf|
%      |Pji|        |0|   |-Pmax| <= x <= |Pmax|
%      |Qji]        |0|   | -inf|         | inf|
%                          =====           ====
%                         rvec_lb         rvec_ub
%
%  PQ equation
%      |Pi|   |-1, 0, 0, 0 |   |Pij|
%      |Qi| = | 0,-1, 0, 0 | * |Qij|
%      |Pj|   | 0, 0,-1, 0 |   |Pji|
%      |Qj|   | 0, 0, 0,-1 |   |Qji|
%               ==========      ===
%                rmat_PQx        x
% 
%  Constraint
%      |0|   |Pij|   |  Vi * ( -Vi*gij + Vj*gij*cos(θi-θj) + Vj*bij*sin(θi-θj) ) |
%      |0| = |Qij| - |  Vi * (  Vi*bij + Vj*gij*sin(θi-θj) - Vj*bij*cos(θi-θj) ) |
%      |0|   |Pji|   | -Vj * (  Vj*gij - Vi*gij*cos(θi-θj) + Vi*bij*sin(θi-θj) ) |
%      |0|   |Qji|   | -Vj * ( -Vj*bij + Vi*bij*cos(θi-θj) + Vi*gij*sin(θi-θj) ) |
% 
%
% %%%%%%%%%%%%%
% %% DC OPF %%%
% %%%%%%%%%%%%%
%
%  x = |Pij| , x0 = |0| , |-Pmax| <= x <= |Pmax|
%                          =====           ====
%                         rvec_lb         rvec_ub
%
%  PQ equation
%      |Pi| = |  1 | * |Pij|
%      |Pj|   | -1 |   
%             ======    ===
%            rmat_PQx    x
% 
%  Constraint
%      |0| = |1| * |Pij|  + |1/xij, -1/xij| * |θ1|
%             =              =============    |θ2|
%         rmat_Constx         rmat_Constv
%
    arguments
        obj 
        opt.method (1,1) string {mustBeMember(opt.method  ,["AC","DC","ELD"])} = "AC"
        opt.Pmax   (1,1) double = obj.parameter.Pmax
    end

    if ~obj.isConnected
        optim = supporters.OptimFactory([],[]);
        return
    end


    switch opt.method
        case "AC"
            str_x    = ["P";"Q"] +[obj.from,obj.to] + "_" + [obj.to,obj.from];
            str_xsub = ["theta";"V"] +[obj.from,obj.to]; 

   
            optim = supporters.OptimFactory( str_x(:), str_xsub(:));
            optim.lb = [ -opt.Pmax; -inf; -opt.Pmax; -inf];
            optim.ub = [  opt.Pmax;  inf;  opt.Pmax;  inf];

            % 等式制約(線形)
            %    Pij Qij Pji Qji  θi  Vi  θj  Vj
            Aeq = [ -1,  0,  0,  0,  0,  0,  0,  0;...
                     0, -1,  0,  0,  0,  0,  0,  0 ;...
                     0,  0, -1,  0,  0,  0,  0,  0 ;...
                     0,  0,  0, -1,  0,  0,  0,  0 ];           
            beq = [  0;  0;  0;  0];
            optim.add_eq( Aeq, beq, replace( ["P";"Q"]+[obj.from, obj.to], [], 1) )

            % 等式制約(非線形)
            x     = optim.x;
            xsub  = optim.xsub;
            Vvec  = [xsub(2) * ( cos(xsub(1)) + 1j*sin(xsub(1)) );...  
                     xsub(4) * ( cos(xsub(3)) + 1j*sin(xsub(3)) )]; 
            yij   = obj.get_admittance_matrix();
            Ivec  = yij*Vvec;
            PQij  = Vvec .* conj(Ivec);
            PQvec = simplify([ real(PQij(1)); imag(PQij(1)); real(PQij(2)); imag(PQij(2))]);
            optim.add_nonleq( x-PQvec, str_x);

        case "DC"
            str_x    = "P" +[obj.from,obj.to] + "_" + [obj.to,obj.from];
            str_xsub = "theta" +[obj.from,obj.to]; 

            optim = supporters.OptimFactory( str_x(:), str_xsub(:));
            optim.lb = [ -opt.Pmax; -opt.Pmax];
            optim.ub = [  opt.Pmax;  opt.Pmax];

            % 等式制約(線形)
            %       Pij Pji  θi  θj 
            Aeq = [ -1,   0,  0,  0 ;...
                     0,  -1,  0,  0 ];           
            beq = [  0;   0];
            optim.add_eq( Aeq, beq, "P"+[obj.from;obj.to] )

            bij = imag(obj.lineAdmittance);
            Aeq = [ -1,   0,  bij, -bij ;...
                     0,  -1, -bij,  bij ];
            beq = [  0;   0];
            optim.add_eq( Aeq, beq, str_x )

        case "ELD"
            optim = supporters.OptimFactory([],[]);
    end

end