function W = weight(W, s_name)
    % A vector is the diagonal of the weight (set.Q, set.R)
    arguments (Input)
        W       % Weight as given: a matrix, its diagonal or empty.
        s_name  % Name of the weight ("Q" or "R"), for the error message.
    end
    arguments (Output)
        W  % Weight matrix, or empty.
    end
    if isempty(W)
        W = [];
    elseif isvector(W) && ~isscalar(W)
        W = diag(W);
    elseif size(W,1) ~= size(W,2)
        error(msg("GUILDA:Retrofit:WeightShape", s_name))
    end
end
