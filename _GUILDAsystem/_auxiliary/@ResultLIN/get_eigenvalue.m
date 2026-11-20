function cv_lambda = get_eigenvalue(obj, Type, opt)
% Get the eigenvalues of the linear model.
%
% Returns a column of the finite generalized eigenvalues of (A, E) of get_ss(Type): the
% infinite eigenvalues of a singular E (the "DAE", whose bus voltages are algebraic) are
% left out. They are sorted by the real part, the largest (the least stable) first, in the
% order of get_mode: each complex pair is kept together, the eigenvalue with Im > 0 first,
% so that the rows with Im >= 0 are the Eigenvalue column of get_mode. get_eigenvector
% returns the eigenvectors in the same order.
%
% Index chooses the section (default res.Index; see ResultLIN), and Time, when given, the
% section whose time rv_t is nearest to it. Index "all" returns a table with the columns
% Time (rv_t of the section), Index and Eigenvalue, one row per eigenvalue of every section.
%
% <@Examples>
% ```matlab
% net = network.IEEE9bus();
% net.initialize();
% res = net.get_sys();
% lambda = res.get_eigenvalue();          % eigenvalues of the Type of the result
% lambda = res.get_eigenvalue("DAE");     % the finite eigenvalues of the DAE
% max(real(lambda))                       % the largest real part
% tab = res.get_eigenvalue(Index="all");  % every section of a result with time sections
% ```
%
% See also ResultLIN.get_eigenvector, ResultLIN.get_mode, ResultLIN.plot_eigenvalue
    arguments (Input)
        obj
        Type (1,1) string {mustBeMember(Type, ["ODE","DAE"])} = obj.Type  % Model: "ODE" or "DAE"; the Type of the result when omitted.
        opt.Index {mustBeSection} = obj.Index   % Section (1 ... numel(rv_t)) or "all" (a table with the columns Time and Index); res.Index when omitted.
        opt.Time (1,1) double {mustBeReal}      % [s] Time: the section whose rv_t is nearest; overrides Index.
    end
    arguments (Output)
        cv_lambda  % [1/s] Eigenvalues (complex column), or a table Time [s], Index, Eigenvalue for Index "all".
    end
    iv_sec = section_list(obj, opt);
    c_lam = cell(numel(iv_sec), 1);
    for i = 1:numel(iv_sec)
        sys = obj.get_ss(Type, Index=iv_sec(i), Format="struct");
        c_lam{i} = eigen_sorted(sys.A, sys.E);
    end
    if isfield(opt, "Time") || ~(isstring(opt.Index) || ischar(opt.Index))
        cv_lambda = c_lam{1};
        return
    end
    n_k = cellfun(@numel, c_lam);
    cv_lambda = table(repelem(reshape(obj.rv_t(iv_sec), [], 1), n_k), repelem(reshape(iv_sec, [], 1), n_k), vertcat(c_lam{:}), ...
        'VariableNames', ["Time","Index","Eigenvalue"]);
    cv_lambda.Properties.VariableUnits = ["s", "", "1/s"];
end
