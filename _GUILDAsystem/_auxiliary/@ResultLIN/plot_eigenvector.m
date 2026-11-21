function sct_graph = plot_eigenvector(obj, opt)
% Plot the eigenvector of a mode on the network diagram, with the mode picked on the eigenvalue map.
%
% What it shows: the shape of one mode over the network. The right eigenvector v
% (Side "right", default; A v = lambda E v, cm_right of get_eigenvector) says how much
% and with which phase each variable swings in the mode: buses of the same color phase
% swing together, buses 180° apart swing against each other. The left eigenvector w
% (Side "left"; w' A = lambda w' E, cm_left) says how strongly an input or a disturbance
% in the equation of each variable excites the mode.
%
% Draws the same figure as plot_participation (the eigenvalue map on the left, the
% diagram of sct_network on the right and a table below it) for the eigenvector of the
% mode picked on the map (mode 1, the first row of get_mode, first).
%
% Each bus shows the entry at its representative variable:
%
% - the angle delta of the first generator at the bus (a state named "delta" of a
%   component at the bus, tab_variable.Name), for the left vector the row of its state
%   equation;
% - else the bus angle theta (Type "DAE" only; for the left vector the row of the P
%   balance of the bus);
% - else none: the bus is gray (e.g. a load bus of Type "ODE").
%
% The node color is the magnitude of the entry divided by the largest magnitude over the
% representative variables (so 1 at the bus that moves most, colorbar from 0), and the
% label "tag: magnitude∠phase°" gives the phase relative to that largest entry (0° there;
% buses swinging against it are near 180°). Clicking a bus (or a component: its bus) lists
% every state of the bus with the magnitude and phase [deg] of its entry (the vector as
% get_eigenvector normalizes it); the data tip of a bus gives its |entry| / max. Clicking
% an eigenvalue picks its mode, as in plot_participation. Type chooses the model.
% Sections switch through the playback bar as in plot_participation; another layer than
% the network stops with GUILDA:ResultLIN:NetworkOnly.
%
% It returns a struct with Eigenvalue (GraphChart), Diagram (GraphNetDiagram) and Table
% (uitable).
%
% <@Examples>
% ```matlab
% res = net.get_sys();
% sct = res.plot_eigenvector();                   % mode shape of the least stable mode
% sct = res.plot_eigenvector(Side="left");
% sct = res.plot_eigenvector(Type="DAE");         % the load buses by their theta
% ```
%
% See also ResultLIN.get_eigenvector, ResultLIN.plot_participation, ResultLIN.get_mode
    arguments (Input)
        obj
        opt.Side (1,1) string {mustBeMember(opt.Side, ["right","left"])} = "right"  % Eigenvector: "right" (the mode shape) or "left".
        opt.Type (1,1) string {mustBeMember(opt.Type, ["ODE","DAE"])} = obj.Type  % Model whose modes are used: "ODE" or "DAE"; the Type of the result when omitted.
        opt.Index (1,1) double {mustBeInteger, mustBePositive} = obj.Index  % Section shown first (1 ... numel(rv_t)); res.Index when omitted.
        opt.Parent = []                                        % Container (figure, uifigure, uipanel, uitab, uigridlayout) to draw in; [] for a new figure.
    end
    arguments (Output)
        sct_graph struct  % Eigenvalue (GraphChart), Diagram (GraphNetDiagram) and Table (uitable).
    end
    if ~(isfield(obj.output, "s_layer") && obj.output.s_layer == "PowerNetwork")
        error(msg("GUILDA:ResultLIN:NetworkOnly", "plot_eigenvector"))
    end
    n_t = numel(obj.rv_t);
    if opt.Index > n_t
        error(msg("GUILDA:ResultLIN:IndexRange", string(n_t)))
    end
    sct_part = obj.get_participation(Type=opt.Type, Index="all");
    sct_vec  = obj.get_eigenvector(opt.Type, Index="all");
    s_side = opt.Side;
    sct_spec = struct("s_name", "Eigenvector (" + s_side + ")", "s_colorbar", "|entry| / max", "s_limit", "zero", ...
        "s_explain", ["Color: |" + s_side + " eigenvector| at the bus's \delta (else \theta) / largest"; "Label: magnitude∠phase"], ...
        "s_value", "|entry| / max", ...
        "sv_column", ["Magnitude", "Phase [deg]"], "l_tableAll", false, ...
        "fcn_section", @(sv_bus, ~, ~) vector_sections(obj, sct_part, sct_vec, s_side, sv_bus));
    sct_graph = mode_diagram(obj, struct("Type", opt.Type, "Index", opt.Index, "Parent", opt.Parent), sct_spec);
end


function sct_sec = vector_sections(obj, sct_part, sct_vec, s_side, sv_bus)
% Data of each section for mode_diagram: the entry of the representative variable of each bus
    arguments (Input)
        obj ResultLIN           % The result.
        sct_part struct         % get_participation of every section (the modes).
        sct_vec struct          % get_eigenvector of every section.
        s_side (1,1) string     % "right" or "left".
        sv_bus (:,1) string     % Bus tags of the diagram.
    end
    arguments (Output)
        sct_sec struct          % Data of each section (see mode_diagram).
    end
    tab = obj.tab_variable;
    c_sec = cell(1, numel(sct_part));
    for s = 1:numel(sct_part)
        V = sct_vec(s);
        cm = V.cm_right;
        if s_side == "left"
            cm = V.cm_left;
        end
        sv_state = V.sv_state;
        % the bus of each state, and the representative variable of each bus: delta, else theta
        [lv_known, iv_row] = ismember(sv_state, tab.Label);
        sv_at = state_owner(obj, sv_state);
        sv_at(lv_known) = tab.Bus(iv_row(lv_known));
        sv_name = strings(numel(sv_state), 1);
        sv_name(lv_known) = tab.Name(iv_row(lv_known));
        iv_rep = zeros(numel(sv_bus), 1);
        for b = 1:numel(sv_bus)
            i = find(sv_at == sv_bus(b) & sv_name == "delta", 1);
            if isempty(i)
                i = find(sv_at == sv_bus(b) & ~lv_known & startsWith(sv_state, "theta"), 1);
            end
            if ~isempty(i)
                iv_rep(b) = i;
            end
        end
        % the eigenvector of each mode (the column of its eigenvalue)
        cv_lambda = sct_part(s).cv_lambda;
        n_m = numel(cv_lambda);
        cm_mode = complex(zeros(numel(sv_state), n_m));
        for m = 1:n_m
            [~, j] = min(abs(V.cv_lambda - cv_lambda(m)));
            cm_mode(:, m) = cm(:, j);
        end
        rm_bus = NaN(numel(sv_bus), n_m);
        sm_label = repmat(sv_bus, 1, n_m);
        lv_rep = iv_rep > 0;
        for m = 1:n_m
            cv = cm_mode(iv_rep(lv_rep), m);
            [r_max, i_max] = max(abs(cv));
            if isempty(cv) || r_max == 0
                continue
            end
            cv = cv / cv(i_max);                    % 1∠0° at the largest entry
            rm_bus(lv_rep, m) = abs(cv);
            rv_deg = round(rad2deg(angle(cv)));
            rv_deg(rv_deg == 0) = 0;                % no "-0"
            sm_label(lv_rep, m) = sv_bus(lv_rep) + ": " + compose("%.2f∠%d°", abs(cv), rv_deg);
        end
        c_sec{s} = struct("cv_lambda", cv_lambda, "rm_bus", rm_bus, "sm_busLabel", sm_label, ...
            "rm_comp", [], "rm_branch", [], "sv_row", sv_state, "sv_rowBus", sv_at, "rm_row", cm_mode);
    end
    sct_sec = [c_sec{:}];
end
