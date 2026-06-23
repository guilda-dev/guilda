function [sol,sol_pred] = solve(obj)                       

    x_past    = [];            
    x_current = [obj.CPFInitVal;obj.CPFInitLam];
    
    sol      = x_current;
    sol_pred = nan(size(x_current));
    
    Iteration = 1;            
    while Iteration <= obj.CPFMaxIter

        x_pred = obj.Predict(x_current,x_past);                            

        [x_current,x_past,~] = obj.Correct(x_current,x_pred);           

        sol_pred = [sol_pred,x_pred]; %#ok
        sol      = [sol,x_current];   %#ok

        if x_current(end) < 0
            break;
        end
        Iteration = Iteration + 1;                
    end

    obj.CPF_Result.x_sol = [obj.rm_BusEM * sol(1:end-1)      + obj.CONSTANT; sol(end)     ];
    obj.CPF_Result.x_prd = [obj.rm_BusEM * sol_pred(1:end-1) + obj.CONSTANT; sol_pred(end)];
end