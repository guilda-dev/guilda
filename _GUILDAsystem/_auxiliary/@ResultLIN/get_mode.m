function sct_mode = get_mode(obj, opt)
% Get the modes of the linear model: eigenvalues, frequencies, damping ratios and owners.
%
% Returns one struct. Its table tab_mode has one row per mode of get_ss(Type): the finite
% generalized eigenvalues of (A, E), one of each complex pair (the one with Im > 0), as in
% the stability-constrained OPF (calculate_optimal_powerflow, sct_stability.tab_mode,
% which leaves out the zero eigenvalues). The infinite eigenvalues of a singular E (the
% "DAE", whose bus voltages are algebraic) are not modes. The rows are sorted by the real
% part, the largest (the least stable) first.
%
% - Eigenvalue: the eigenvalue lambda [1/s] (complex).
% - Frequency: |Im lambda| / (2 pi) [Hz].
% - DampingRatio: -Re lambda / |lambda| for an oscillatory mode (|Im lambda| > 1e-6), NaN
%   for a real mode.
% - DominantOwner: the owner (component or controller tag, of tab_variable.Owner; the bus
%   tag for a bus variable of the "DAE") of the states with the largest participation in
%   the mode, the participation summed over the states of each owner.
%
% MinFrequency > 0 keeps the oscillatory modes with Frequency >= MinFrequency only.
% The other fields hold, for the modes of the rows (columns) and the states of the model
% (rows, in the order of StateName):
%
% - rm_participation: the participation |w_k (E v)_k| of state k (left and right
%   eigenvectors w, v), normalized to sum 1 in each mode (get_participation sums it by
%   bus).
% - cm_shape: the mode shape, the right eigenvector v normalized so that its entry of
%   largest magnitude is 1.
% - sv_state, sv_owner: the names of the states (StateName) and their owners.
% - s_type: the Type of the model.
%
% Index chooses the section (default res.Index; see ResultLIN), and Time, when given, the
% section whose time rv_t is nearest to it. Index "all" returns a 1 x n_t struct array
% whose tab_mode has the columns Time (rv_t of the section) and Index first, so that
% vertcat(sct.tab_mode) is one table of the modes of every section.
%
% On a contribution result (sv_target nonempty, see get_contribution) the numbers are of
% the part alone and have no meaning for the whole system.
%
% <@Examples>
% ```matlab
% net = network.IEEE9bus();
% net.initialize();
% res = net.get_sys();
% sct = res.get_mode();                            % every mode
% sct.tab_mode
% sct = res.get_mode(MinFrequency=0.1);            % oscillatory modes only
% bar(categorical(sct.sv_state), sct.rm_participation(:, 1));   % participation in the first mode
% sct = res.get_mode(Index="all");                 % every section of a result with time sections
% tab = vertcat(sct.tab_mode);                     % one table, with Time and Index
% ```
%
% See also ResultLIN.get_participation, ResultLIN.plot_eigenvalue, ResultLIN.get_ss, PowerNetwork.calculate_optimal_powerflow
    arguments (Input)
        obj
        opt.Type (1,1) string {mustBeMember(opt.Type, ["ODE","DAE"])} = obj.Type  % Model whose modes are returned: "ODE" or "DAE"; the Type of the result when omitted.
        opt.MinFrequency (1,1) double {mustBeNonnegative} = 0                     % [Hz] Smallest frequency kept; > 0 keeps the oscillatory modes only.
        opt.Index {mustBeSection} = obj.Index                                     % Section (1 ... numel(rv_t)) or "all" (a struct array, tab_mode with the columns Time and Index); res.Index when omitted.
        opt.Time (1,1) double {mustBeReal}                                        % [s] Time: the section whose rv_t is nearest; overrides Index.
    end
    arguments (Output)
        sct_mode struct  % tab_mode (Eigenvalue, Frequency [Hz], DampingRatio, DominantOwner), rm_participation, cm_shape (states x modes), sv_state, sv_owner (states), s_type (1 x n_t for Index "all").
    end
    iv_sec = section_list(obj, opt);
    l_all = ~isfield(opt, "Time") && (isstring(opt.Index) || ischar(opt.Index));
    c_mode = cell(1, numel(iv_sec));
    for i = 1:numel(iv_sec)
        k = iv_sec(i);
        sct = sorted_modes(obj, opt.Type, k);
        lv = true(numel(sct.lambda), 1);
        if opt.MinFrequency > 0
            lv = sct.l_osc & sct.frequency >= opt.MinFrequency;
        end
        tab_mode = table(sct.lambda(lv), sct.frequency(lv), sct.zeta(lv), sct.owner(lv), ...
            'VariableNames', ["Eigenvalue","Frequency","DampingRatio","DominantOwner"]);
        tab_mode.Properties.VariableUnits = ["1/s", "Hz", "", ""];
        if l_all
            tab_mode = addvars(tab_mode, repmat(obj.rv_t(k), height(tab_mode), 1), repmat(k, height(tab_mode), 1), ...
                Before=1, NewVariableNames=["Time","Index"]);
            tab_mode.Properties.VariableUnits(1:2) = ["s", ""];
        end
        c_mode{i} = struct("tab_mode", tab_mode, "rm_participation", sct.rm_participation(:, lv), ...
            "cm_shape", sct.cm_shape(:, lv), "sv_state", sct.sv_state, "sv_owner", sct.sv_owner, "s_type", opt.Type);
    end
    sct_mode = [c_mode{:}];
end
