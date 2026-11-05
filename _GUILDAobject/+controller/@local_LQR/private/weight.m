function W = weight(W, s_name)
    % A vector is the diagonal of the weight
    arguments (Input)
        W         % Weight as given: a matrix, its diagonal or empty.
        s_name    % Name of the weight ("Q" or "R"), for the error message.
    end
    arguments (Output)
        W  % Weight matrix, or empty.
    end
    if isempty(W)
        W = [];
    elseif isvector(W) && ~isscalar(W)
        W = diag(W);
    elseif size(W,1) ~= size(W,2)
        error(msg("GUILDA:local_LQR:WeightShape", s_name))
    end
end
