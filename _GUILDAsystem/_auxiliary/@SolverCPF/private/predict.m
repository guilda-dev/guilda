function [x_pred,t_old] = predict(f_Jac,h,x_current,x_past,t_old)
% Predictor of the CPF: the tangent at the first step (x_past empty), the secant
% from the previous step afterwards. t_old is the last tangent (orientation).
    arguments (Input)
        f_Jac     (1,1) function_handle  % Jacobian of the power flow equations of the CPF.
        h         (1,1) double           % Step size of the predictor.
        x_current (:,1) double           % Current point [unknowns; lambda].
        x_past                           % Previous point, or [] at the first step.
        t_old                            % Last tangent, or [] before the first one.
    end
    arguments (Output)
        x_pred    (:,1) double           % Predicted point.
        t_old                            % Last tangent (updated at the first step).
    end

    if isempty(x_past)

        x_pred = zeros(size(x_current));

        Jacobi = f_Jac(x_current);
        pivot  = piv(Jacobi);
        Jh     = size(Jacobi,2);

        l_p = ismember(1:Jh,pivot);

        beta = - Jacobi(:,l_p) \ Jacobi(:,~l_p);
        x_pred(~l_p) = sqrt( (1 + beta' * beta)^-1 );

        x_pred(l_p)  = beta * x_pred(~l_p);

        t = x_pred / norm(x_pred);
        if ~isempty(t_old)
            if dot(t,t_old) < 0
                t = -t;
            end
        else
            if t(end) < 0
                t = -t;
            end
        end

        t_old = t;

        x_pred = x_current + h * t;
    else
        x_pred = (x_current - x_past) * h + x_current;
    end
end

function p = piv(Mat)
    [~,U,~] = lu(Mat);
    [Jv ,~] = size(Mat);
    p = arrayfun(@(i) find(U(i,:)~=0, 1, "first"), 1:Jv);
end
