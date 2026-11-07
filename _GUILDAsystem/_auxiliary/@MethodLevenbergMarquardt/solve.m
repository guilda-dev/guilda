function [x, flag, output, rm_history, rv_step] = solve(obj)
% Solve F(x) = 0 from InitVal (see the class help).
    arguments (Input)
        obj
    end
    arguments (Output)
        x           % Last iterate.
        flag        % 1: converged, 0: MaxIter reached, -2: no decrease of |F| (no solution found).
        output      % Details: iterations, algorithm, residual (largest |F|), message.
        rm_history  % Iterates: InitVal and x after each taken step (one column each).
        rv_step     % Iteration numbers of rm_history.
    end
    l_iter = startsWith(obj.Display, "iter");
    x     = obj.InitVal;
    rv_F  = obj.Fcn(x);
    rm_J  = obj.Jac(x);
    r_mu  = full(1e-6 * max(sum(rm_J.^2, 1)));
    m_eye = speye(numel(x));
    rm_history = x;
    flag = 0;
    for k = 0:obj.MaxIter
        r_res = max(abs(rv_F));
        if l_iter
            fprintf('  levenberg-marquardt  iter %4d   max mismatch %.3e   mu %.1e\n', k, r_res, r_mu);
        end
        if r_res <= obj.ConvTol
            flag = 1;
            break
        elseif k == obj.MaxIter
            break
        end
        rm_A = rm_J.'*rm_J;
        rv_g = rm_J.'*rv_F;
        while true
            x_new = x - (rm_A + r_mu*m_eye) \ rv_g;
            F_new = obj.Fcn(x_new);
            if norm(F_new) < norm(rv_F)
                x = x_new;  rv_F = F_new;  rm_J = obj.Jac(x);
                r_mu = r_mu/10;
                break
            end
            r_mu = 10*r_mu;
            if ~(r_mu < 1e20)
                flag = -2;
                break
            end
        end
        if flag == -2
            break
        end
        rm_history(:,end+1) = x; %#ok<AGROW>
    end
    rv_step = 0:size(rm_history,2)-1;

    output = struct("iterations", rv_step(end), "algorithm", "levenberg-marquardt", "residual", r_res);
    switch flag
        case 1
            output.message = sprintf('✔ The Levenberg-Marquardt iteration has converged within the tolerance limit (%d iterations).', rv_step(end));
        case 0
            output.message = sprintf('✘ The Levenberg-Marquardt iteration did not converge within MaxIterations (%d).', obj.MaxIter);
        otherwise
            output.message = sprintf('✘ No solution was found: the Levenberg-Marquardt iteration stopped at a local minimum of the mismatch (max %.3e).', r_res);
    end
    if obj.Display ~= "none"
        disp(output.message)
    end
end
