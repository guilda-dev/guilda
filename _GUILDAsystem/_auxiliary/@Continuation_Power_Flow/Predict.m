function x_pred = Predict(obj,x_current,x_past)                        
    h = obj.CPFStepSize;

    if isempty(x_past)

        x_pred = zeros(size(x_current));
                        
        Jacobi = obj.CPFJac(x_current);
        pivot  = piv(Jacobi);
        Jh     = size(Jacobi,2);
        
        l_p = ismember(1:Jh,pivot);
        
        beta = - Jacobi(:,l_p) \ Jacobi(:,~l_p);
        x_pred(~l_p) = sqrt( (1 + beta' * beta)^-1 );                

        x_pred(l_p)  = beta * x_pred(~l_p);                

        if x_pred(end) < 0
            x_pred = -x_pred;
        end

        x_pred = x_current + h * x_pred;
    else                
        x_pred = (x_current - x_past) * h + x_current;
    end
end

function p = piv(Mat)
    [~,U,~] = lu(Mat);                
    [Jv ,~] = size(Mat);
    p = arrayfun(@(i) find(U(i,:)~=0, 1, "first"), 1:Jv);                
end