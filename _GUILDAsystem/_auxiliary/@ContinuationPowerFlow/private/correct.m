function [x_correct,x_current,N] = Correct(obj,x_current,x_pred)
            
    NRM = obj.CPF_NRM;            
    
    delta_s   = obj.CPFArcL;                        
    ArcLength = @(x,s) (x-x_current)' * (x-x_current) - s;            
    ArcJacobi = @(x,s) (x-x_current)' * 2;                      

    NRM.NRMFcn  = @(x) [obj.CPFFcn(x); ArcLength(x,delta_s)];
    NRM.NRMJac  = @(x) [obj.CPFJac(x); ArcJacobi(x,delta_s)];           
    NRM.NRMVal  = zeros(size(x_pred));
    NRM.InitVal = x_pred;

    [x_correct,N] = solve(NRM);
end