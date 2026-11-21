function [c_e, rv_sample, sv_text] = section_eigenvalues(obj, s_type)
% Finite eigenvalues of every section and the samples of a chart over the sections
% (plot_eigenvalue and plot_eigenvalue_path of a result with several sections).
%
% The samples are rv_t when its times are finite and nondecreasing (so that the chart
% links with the graphs of the same simulation), else the section numbers 1 ... n_t.
% sv_text is the text of each section for the chart ("section k of n, t = ...").
    arguments (Input)
        obj    ResultLIN          % The result.
        s_type (1,1) string       % "ODE" or "DAE".
    end
    arguments (Output)
        c_e       (1,:) cell      % Finite eigenvalues of each section (column vectors).
        rv_sample (1,:) double    % Sample of each section for the chart.
        sv_text   (1,:) string    % Text of each section.
    end
    n_t = numel(obj.rv_t);
    c_e = cell(1, n_t);
    for k = 1:n_t
        sys = obj.get_ss(s_type, Index=k, Format="struct");
        e = eig(full(sys.A), full(sys.E));
        c_e{k} = e(isfinite(e));
    end
    rv_sample = reshape(double(obj.rv_t), 1, []);
    if ~(all(isfinite(rv_sample)) && all(diff(rv_sample) >= 0))
        rv_sample = 1:n_t;
    end
    sv_text = compose("section %d of %d, t = %g", (1:n_t)', n_t, reshape(double(obj.rv_t), [], 1))';
end
