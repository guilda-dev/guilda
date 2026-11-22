function sct_vector = get_eigenvector(obj, Type, opt)
% Get the right and left eigenvectors of the linear model.
%
% Returns one struct with the eigenvectors of the finite generalized eigenvalues of (A, E)
% of get_ss(Type) as columns, for the eigenvalues cv_lambda (those of get_eigenvalue, in
% the same order: sorted by the real part, the largest first; each complex pair together,
% Im > 0 first). The rows are the states of the model, named in sv_state (its StateName).
%
% - cm_right: A v = lambda E v, with v normalized so that its entry of largest magnitude
%   is 1 (the mode shape cm_shape of get_mode).
% - cm_left: w' A = lambda w' E (w' is the conjugate transpose), with w normalized so that
%   w' E v = 1 with the right vector v of the same column.
%
% The vectors of the conjugate eigenvalue of a pair are the conjugates of the vectors of
% the eigenvalue with Im > 0. s_type is the Type of the model.
%
% Index chooses the section (default res.Index; see ResultLIN), and Time, when given, the
% section whose time rv_t is nearest to it. Index "all" returns a 1 x n_t struct array.
%
% On a contribution result (sv_target nonempty, see get_contribution) the numbers are of
% the part alone and have no meaning for the whole system.
%
% <@Examples>
% ```matlab
% net = network.IEEE9bus();
% net.initialize();
% res = net.get_sys();
% sct = res.get_eigenvector();                        % right and left eigenvectors
% sys = res.get_ss(Format="struct");
% sct.cm_left(:,1)' * sys.E * sct.cm_right(:,1)       % 1
% bar(categorical(sct.sv_state), abs(sct.cm_right(:, 1)))   % shape of the least stable mode
% ```
%
% See also ResultLIN.get_eigenvalue, ResultLIN.get_mode
    arguments (Input)
        obj
        Type (1,1) string {mustBeMember(Type, ["ODE","DAE"])} = obj.Type  % Model: "ODE" or "DAE"; the Type of the result when omitted.
        opt.Index {mustBeSection} = obj.Index   % Section (1 ... numel(rv_t)) or "all" (a struct array, one per section); res.Index when omitted.
        opt.Time (1,1) double {mustBeReal}      % [s] Time: the section whose rv_t is nearest; overrides Index.
    end
    arguments (Output)
        sct_vector struct  % cm_right, cm_left (states x eigenvalues, complex), cv_lambda [1/s], sv_state (states), s_type (1 x n_t for Index "all").
    end
    iv_sec = section_list(obj, opt);
    c_vector = cell(1, numel(iv_sec));
    for i = 1:numel(iv_sec)
        sys = obj.get_ss(Type, Index=iv_sec(i), Format="struct");
        [cv_lambda, cm_right, cm_left] = eigen_sorted(sys.A, sys.E);
        c_vector{i} = struct("cm_right", cm_right, "cm_left", cm_left, "cv_lambda", cv_lambda, ...
            "sv_state", sys.StateName, "s_type", Type);
    end
    sct_vector = [c_vector{:}];
end
