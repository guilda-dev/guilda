function sct = step_sample(obj)
% Samples of the plots of a continuation power flow result: the steps 1 ... n_step.
%
% The samples are the step numbers (lambda is not monotonic past the nose), named "Step",
% with the text "Step k (λ = ...)" of each step. The fields are those of the data of a
% GraphBase subclass (rv_t, s_sampleName, sv_sampleText), so the plots of the steps link
% with each other and with net.get_sys({result, steps}).plot_eigenvalue (G.link).
    arguments (Input)
        obj ResultCPF  % The result.
    end
    arguments (Output)
        sct (1,1) struct  % rv_t (1 x n_step), s_sampleName "Step", sv_sampleText (1 x n_step).
    end
    n_step = numel(obj.rv_lambda);
    sct = struct();
    if n_step == 0
        return              % no path: the default sample of the graph
    end
    sct.rv_t = 1:n_step;
    sct.s_sampleName  = "Step";
    sct.sv_sampleText = reshape(compose("Step %d (λ = %.4g)", (1:n_step).', obj.rv_lambda(:)), 1, []);
end
