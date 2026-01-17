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
%      |Pi|   | 1, 0, 0, 0 |   |Pij|
%      |Qi| = | 0, 1, 0, 0 | * |Qij|
%      |Pj|   | 0, 0, 1, 0 |   |Pji|
%      |Qj|   | 0, 0, 0, 1 |   |Qji|
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
%                                             |θ2|
% 
%