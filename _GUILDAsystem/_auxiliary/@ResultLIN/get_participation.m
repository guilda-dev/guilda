function sct_part = get_participation(obj, opt)
% Get the participation of the states and of the buses in the modes of the linear model.
%
% Returns one struct for the modes of get_mode (the same calculation and the same order:
% one of each complex pair, sorted by the real part, the largest first):
%
% - rm_value: states x modes, the participation |w_k (E v)_k| of state k (left and right
%   eigenvectors w, v) normalized to sum 1 in each mode (rm_participation of get_mode).
% - cv_lambda: the eigenvalues of the columns [1/s] (the Eigenvalue column of get_mode).
% - sv_state, sv_owner: the names of the rows (StateName) and their owners (the tag of the
%   component or controller, of tab_variable.Owner; the bus tag for a bus variable of the
%   "DAE").
% - tab_bus: one row per bus of the model, in the order of the buses: Bus (the tag) and
%   Participation (buses x modes), the sum of the participation of the states at the bus
%   (the states of its components and of their local controllers, by the column Bus of
%   tab_variable, and the bus variables of the "DAE").
% - tab_global: one row per owner of the states that belong to no bus (the global
%   controllers): Owner and Participation (owners x modes); no rows without them.
% - s_type: the Type of the model.
%
% The columns of tab_bus.Participation and tab_global.Participation of a mode sum to 1
% together. A mode whose participation is all zero gives NaN.
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
% sct = res.get_participation();
% sct.tab_bus                                        % participation of each bus
% bar(categorical(sct.tab_bus.Bus), sct.tab_bus.Participation(:, 1))   % in the least stable mode
% sct = res.get_participation(Type="DAE", Index="all");
% ```
%
% See also ResultLIN.get_mode, ResultLIN.get_eigenvector
    arguments (Input)
        obj
        opt.Type (1,1) string {mustBeMember(opt.Type, ["ODE","DAE"])} = obj.Type  % Model whose modes are used: "ODE" or "DAE"; the Type of the result when omitted.
        opt.Index {mustBeSection} = obj.Index   % Section (1 ... numel(rv_t)) or "all" (a struct array, one per section); res.Index when omitted.
        opt.Time (1,1) double {mustBeReal}      % [s] Time: the section whose rv_t is nearest; overrides Index.
    end
    arguments (Output)
        sct_part struct  % rm_value (states x modes), cv_lambda [1/s], sv_state, sv_owner, tab_bus (Bus, Participation), tab_global (Owner, Participation), s_type (1 x n_t for Index "all").
    end
    tab = obj.tab_variable;
    sv_bus = tab.Bus(tab.Kind == "Vre");
    iv_sec = section_list(obj, opt);
    c_part = cell(1, numel(iv_sec));
    for i = 1:numel(iv_sec)
        sct = sorted_modes(obj, opt.Type, iv_sec(i));
        rm_value = sct.rm_participation;
        n_m = size(rm_value, 2);

        % the bus of each state: tab_variable.Bus, or the bus that owns a bus variable
        [lv_known, iv_row] = ismember(sct.sv_state, tab.Label);
        sv_at = sct.sv_owner;
        sv_at(lv_known) = tab.Bus(iv_row(lv_known));
        rm_bus = zeros(numel(sv_bus), n_m);
        for b = 1:numel(sv_bus)
            rm_bus(b, :) = sum(rm_value(sv_at == sv_bus(b), :), 1);
        end
        lv_global = ~ismember(sv_at, sv_bus);
        sv_global = unique(sct.sv_owner(lv_global), "stable");
        rm_global = zeros(numel(sv_global), n_m);
        for g = 1:numel(sv_global)
            rm_global(g, :) = sum(rm_value(lv_global & sct.sv_owner == sv_global(g), :), 1);
        end
        c_part{i} = struct("rm_value", rm_value, "cv_lambda", sct.lambda, "sv_state", sct.sv_state, ...
            "sv_owner", sct.sv_owner, ...
            "tab_bus", table(sv_bus, rm_bus, 'VariableNames', ["Bus","Participation"]), ...
            "tab_global", table(sv_global, rm_global, 'VariableNames', ["Owner","Participation"]), ...
            "s_type", opt.Type);
    end
    sct_part = [c_part{:}];
end
