function matrix = linearization(func,steady_state)

    use_symbolic = true;

    if ~isempty(which('vpa')) & use_symbolic
        old_digit = digits(100);

        delta = vpa(1e-8);
        fvpa = @(x) vpa(x);
    else
        delta = 1e-8;
        fvpa  = @(x) x;

        % recommend to install symbolic math toolbox
        msg = 'If the Symbolic math toolbox is installed, the function "vpa" can be used to further improve accuracy.';
        if strcmp(lastwarn,msg)
            warning(msg)
        end
    end


    n_state = numel(steady_state);
    val     = fvpa(func(steady_state));
    matrix  = zeros(numel(val),n_state);

    for idx = 1:n_state
        state      = fvpa(steady_state);
        state(idx) = state(idx)+delta;
        val_       = fvpa(func(state));
        matrix(:,idx)  = (val_-val)/delta;
    end


    if ~isempty(which('vpa')) & use_symbolic
        matrix = double(matrix);
        digits(old_digit);
    end
    
end