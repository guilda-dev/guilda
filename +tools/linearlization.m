function matrix = linearlization(func,steady_state)

    delta = 1e-8;
    
    n_state = numel(steady_state);
    val     = func(steady_state);
    matrix  = zeros(numel(val),n_state);

    for idx = 1:n_state
        state      = steady_state;
        state(idx) = state(idx)+delta;
        val_       = func(state);
        matrix(:,idx)  = (val_-val)/delta;
    end
end