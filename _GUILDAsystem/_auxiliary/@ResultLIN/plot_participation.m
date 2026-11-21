function sct_graph = plot_participation(obj, opt)
% Plot the participation of the buses in a mode, picked on the eigenvalue map.
%
% Draws one figure (in Parent) with three parts:
%
% - left: the eigenvalue map of plot_eigenvalue (GraphChart, marker sets "stable" and
%   "unstable"). Clicking an eigenvalue picks the mode of that eigenvalue (the nearest
%   eigenvalue, or its conjugate, of the modes of get_participation in the section shown
%   to the point clicked), marked by a black ring on it and its conjugate.
% - right: the diagram of the snapshot sct_network (GraphNetDiagram, the topology), whose
%   buses are colored by tab_bus.Participation of get_participation in the mode picked,
%   on the colormap of the diagram with a colorbar from 0 to the largest participation of
%   the mode. A bus without states (no component or controller states at it, and no bus
%   variable in Type "DAE") is gray (NaN), and so is every bus of a section that has fewer
%   modes. The title gives the mode, its eigenvalue, frequency and damping ratio.
% - below the diagram: a table of the bus clicked (or selected) on the diagram, with the
%   participation of each state of that bus in the mode picked (a component clicked shows
%   its bus). Its panel title is the tag of the bus.
%
% Mode is the mode picked first: the column of get_participation (the modes of get_mode,
% one of each complex pair, sorted by the real part, the largest first). Type chooses the
% model, as in get_participation.
%
% A result with several sections (numel(rv_t) > 1) has one sample per section in both
% graphs, which are linked (G.link): the playback bar of either switches the section of
% both, and the colors, the ring and the table follow the mode of the same number in that
% section. It starts at Index; a Mode beyond the modes of that section stops with
% GUILDA:ResultLIN:ModeRange. Only a result of the network has a diagram; another layer
% stops with GUILDA:ResultLIN:NetworkOnly.
%
% It returns a struct with the parts: Eigenvalue (the GraphChart), Diagram (the
% GraphNetDiagram) and Table (the uitable). The two graphs are GraphBase objects; a bus
% clicked is also selected on the diagram (Diagram.select). Their ElementClickedFcn are
% used by the figure: add more with addlistener(G, "ElementClicked", ...).
%
% <@Examples>
% ```matlab
% res = net.get_sys();
% sct = res.plot_participation();             % click an eigenvalue, then a bus
% sct = res.plot_participation(Mode=3);       % the third mode of get_participation
% sct.Diagram.BusColorData                    % = tab_bus.Participation(:, 3), NaN without states
% res = net.get_sys({sim, [0.5 1 2]});
% sct = res.plot_participation(Index=2);      % sections switched by the playback bar
% ```
%
% See also ResultLIN.get_participation, ResultLIN.plot_eigenvalue, ResultLIN.get_mode, GraphNetDiagram
    arguments (Input)
        obj
        opt.Mode (1,1) double {mustBeInteger, mustBePositive} = 1  % Mode picked first: a column of get_participation.
        opt.Type (1,1) string {mustBeMember(opt.Type, ["ODE","DAE"])} = obj.Type  % Model whose modes are used: "ODE" or "DAE"; the Type of the result when omitted.
        opt.Index (1,1) double {mustBeInteger, mustBePositive} = obj.Index  % Section shown first (1 ... numel(rv_t)); res.Index when omitted.
        opt.Parent = []                                        % Container (figure, uifigure, uipanel, uitab, uigridlayout) to draw in; [] for a new figure.
    end
    arguments (Output)
        sct_graph struct  % Eigenvalue (GraphChart), Diagram (GraphNetDiagram) and Table (uitable).
    end
    if ~(isfield(obj.output, "s_layer") && obj.output.s_layer == "PowerNetwork")
        error(msg("GUILDA:ResultLIN:NetworkOnly", "plot_participation"))
    end
    n_t = numel(obj.rv_t);
    if opt.Index > n_t
        error(msg("GUILDA:ResultLIN:IndexRange", string(n_t)))
    end
    sct_part = obj.get_participation(Type=opt.Type, Index="all");
    tab = obj.tab_variable;
    sct_spec = struct("s_name", "Participation", "s_colorbar", "participation", "s_limit", "zero", ...
        "sv_column", "Participation", "l_tableAll", false, ...
        "fcn_section", @(sv_bus, ~, ~) participation_sections(sct_part, tab, sv_bus));
    sct_graph = mode_diagram(obj, opt, sct_spec);
end


function sct_sec = participation_sections(sct_part, tab, sv_bus)
% Data of each section for mode_diagram: the participation of the buses (NaN without states) and of the states at each bus
    arguments (Input)
        sct_part struct         % get_participation of every section.
        tab table               % Variable map of the result.
        sv_bus (:,1) string     % Bus tags of the diagram.
    end
    arguments (Output)
        sct_sec struct          % Data of each section (see mode_diagram).
    end
    c_sec = cell(1, numel(sct_part));
    for s = 1:numel(sct_part)
        P = sct_part(s);
        [lv_known, iv_row] = ismember(P.sv_state, tab.Label);
        sv_at = P.sv_owner;
        sv_at(lv_known) = tab.Bus(iv_row(lv_known));
        [~, iv] = ismember(sv_bus, P.tab_bus.Bus);
        rm = P.tab_bus.Participation(iv, :);
        rm(~ismember(sv_bus, sv_at), :) = NaN;
        c_sec{s} = struct("cv_lambda", P.cv_lambda, "rm_bus", rm, "sm_busLabel", strings(0, 0), ...
            "rm_comp", [], "rm_branch", [], "sv_row", P.sv_state, "sv_rowBus", sv_at, "rm_row", P.rm_value);
    end
    sct_sec = [c_sec{:}];
end
