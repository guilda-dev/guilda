function [G, tab_coupling] = plot_reduced_matrix(obj, target, opt)
% Plot the reduced matrix seen from the buses on the network diagram.
%
% Computes get_reduced_matrix(target, State) (the Jacobian of the DAE with the variables
% of the targets eliminated) and draws, on the diagram of sct_network (GraphNetDiagram,
% the topology), its block between the bus variables of Block:
%
% - "P" (default): the rows of the P balance and the columns of the bus angles theta (the
%   first bus variable of the Port: theta, or Vre for Port "I");
% - "Q": the rows of the Q balance and the second bus variable (rho for "PQ", V for "PI",
%   Vim for "I").
%
% With K that block (buses x buses), each bus is colored by its diagonal entry K(i,i)
% (the self term; colorbar over every section) and labelled "tag: K(i,i)"; each branch is
% drawn with a width from 0.5 pt (no coupling) to 6 pt (the largest coupling over the
% branches of every section) by the coupling of its end buses, (|K(i,j)| + |K(j,i)|)/2.
% A bus whose variable was eliminated (a target bus) is gray, and the branches to it
% take the smallest width. The reduction also couples buses that no branch joins (e.g.
% through an eliminated bus); the diagram cannot draw them, so tab_coupling lists every
% pair of buses with a coupling above 1e-9 times the largest of the section shown first:
% Bus1, Bus2, Coupling and Branch (the tags of the branches between them, "" when none).
%
% target and State are those of get_reduced_matrix: e.g. ["Component","LocalController"]
% (with "GlobalController" when the model has one) gives the matrix seen from the buses
% (縮約アドミタンス), State "settled" (default) the steady-state one and "fixed" the
% instantaneous one. A result with several sections has one sample per section, switched
% by the playback bar (colors, widths and labels follow), starting at Index. Only a result
% of the network has it; another layer stops with GUILDA:ResultLIN:NetworkOnly.
%
% <@Examples>
% ```matlab
% res = net.get_sys();
% [G, tab] = res.plot_reduced_matrix(["Component","LocalController"]);   % P block seen from the buses
% tab(tab.Branch == "", :)                         % couplings without a branch
% G = res.plot_reduced_matrix("Component", State="fixed", Block="Q");
% ```
%
% See also ResultLIN.get_reduced_matrix, GraphNetDiagram, ResultLIN.plot_kernel
    arguments (Input)
        obj
        target (1,:) string {mustBeNonempty}  % Tags and class (or package) names of the elements whose variables are eliminated (see get_reduced_matrix).
        opt.State (1,1) string {mustBeMember(opt.State, ["settled","fixed"])} = "settled"  % Dynamic states of the targets: "settled" (eliminated) or "fixed" (held at the point).
        opt.Block (1,1) string {mustBeMember(opt.Block, ["P","Q"])} = "P"  % Block drawn: "P" (P balance x theta) or "Q" (Q balance x the second bus variable).
        opt.Index (1,1) double {mustBeInteger, mustBePositive} = obj.Index  % Section shown first (1 ... numel(rv_t)); res.Index when omitted.
        opt.Parent = []                                        % Container (figure, uifigure, uipanel, uitab, uigridlayout) or axes/uiaxes to draw in; [] for a new figure.
    end
    arguments (Output)
        G                   % The diagram (GraphNetDiagram), ColorMode "user" with K(i,i) in BusColorData and the couplings as BranchLineWidth.
        tab_coupling table  % Couplings of the section shown first: Bus1, Bus2, Coupling, Branch.
    end
    if ~(isfield(obj.output, "s_layer") && obj.output.s_layer == "PowerNetwork")
        error(msg("GUILDA:ResultLIN:NetworkOnly", "plot_reduced_matrix"))
    end
    n_t = numel(obj.rv_t);
    if opt.Index > n_t
        error(msg("GUILDA:ResultLIN:IndexRange", string(n_t)))
    end
    sct_red = obj.get_reduced_matrix(target, State=opt.State, Index="all");
    [G, sv_bus, ~, sv_title] = section_diagram(obj, "Reduced matrix (" + opt.Block + ")", ...
        {"ColorbarLabel", "K(i,i)", "LabelMode", "user", "Parent", opt.Parent}, ...
        ["Color: self term K(i,i) of the bus; width: coupling of the two buses"; "Gray: eliminated"], ...
        "K(i,i)");
    n_bus = numel(sv_bus);
    a_branch = reshape(obj.sct_network.a_Branch, [], 1);
    n_br = numel(a_branch);
    sv_branch = strings(n_br, 1);
    im_edge = zeros(2, n_br);
    for k = 1:n_br
        sv_branch(k) = a_branch{k}.s_tag;
        for e = 1:2
            x = a_branch{k}.a_Bus{e};
            if isstruct(x)
                im_edge(e, k) = find(sv_bus == string(x.s_tag), 1);
            else
                im_edge(e, k) = str2double(regexp(string(x), "a_Bus\{(\d+)\}$", "tokens", "once"));
            end
        end
    end

    % The bus variables of the DAE: their bus and kind (1: theta / Vre, 2: the second), as
    % in get_ss (every bus for the first kind, then for the second)
    [sv_bv, sv_bvBus, iv_kind] = bus_variables(obj, opt.Index);
    i_kind = 1 + (opt.Block == "Q");
    sv_var = sv_bv(iv_kind == i_kind);
    [~, iv_varBus] = ismember(sv_bvBus(iv_kind == i_kind), sv_bus);

    % The block K of every section (NaN where a bus variable was eliminated)
    c_K = cell(1, n_t);
    for s = 1:n_t
        R = sct_red(s);
        K = NaN(n_bus);
        [lv_r, iv_r] = ismember(sv_var, R.sv_row);
        [lv_c, iv_c] = ismember(sv_var, R.sv_column);
        K(iv_varBus(lv_r), iv_varBus(lv_c)) = R.rm_value(iv_r(lv_r), iv_c(lv_c));
        c_K{s} = K;
    end
    rm_diag = cell2mat(cellfun(@(K) diag(K), c_K, "UniformOutput", false));
    rm_cpl = zeros(n_br, n_t);
    for s = 1:n_t
        K = abs(c_K{s});
        K(isnan(K)) = 0;
        rm_cpl(:, s) = (K(sub2ind([n_bus n_bus], im_edge(1, :), im_edge(2, :))) + ...
                        K(sub2ind([n_bus n_bus], im_edge(2, :), im_edge(1, :))))' / 2;
    end
    r_max = max([rm_cpl(:); 0]);
    rm_width = 0.5 + 5.5 * rm_cpl / max(r_max, eps);
    sm_label = repmat(sv_bus, 1, n_t);
    lm = isfinite(rm_diag);
    sm_label(lm) = sm_label(lm) + ": " + compose("%.3g", rm_diag(lm));
    rv_v = rm_diag(lm);
    if ~isempty(rv_v) && max(rv_v) > min(rv_v)
        G.ColorLimits = [min(rv_v), max(rv_v)];
    end
    show_section(G, opt.Index, rm_diag, rm_width, sm_label, sv_title);
    if n_t > 1
        G.TimeChangedFcn = @(G, data) show_section(G, data.Index, rm_diag, rm_width, sm_label, sv_title);
        G.set_time(G.rv_t(opt.Index));
    end

    % The couplings of the section shown first, with the branches between the buses
    K = abs(c_K{opt.Index});
    K(isnan(K)) = 0;
    K = (K + K.') / 2;
    [iv_1, iv_2] = find(triu(K, 1) > 1e-9 * max([K(:); eps]));
    sv_br = strings(numel(iv_1), 1);
    for q = 1:numel(iv_1)
        lv = (im_edge(1, :) == iv_1(q) & im_edge(2, :) == iv_2(q)) | (im_edge(1, :) == iv_2(q) & im_edge(2, :) == iv_1(q));
        sv_br(q) = join(sv_branch(lv), ", ");
    end
    sv_br(ismissing(sv_br)) = "";
    tab_coupling = table(sv_bus(iv_1), sv_bus(iv_2), K(sub2ind([n_bus n_bus], iv_1, iv_2)), sv_br, ...
        'VariableNames', ["Bus1","Bus2","Coupling","Branch"]);
    tab_coupling = sortrows(tab_coupling, "Coupling", "descend");
end


function show_section(G, k, rm_diag, rm_width, sm_label, sv_title)
% Colors, widths and labels of section k (also the TimeChangedFcn of the diagram)
    arguments (Input)
        G                    % The diagram.
        k (1,1) double       % Section.
        rm_diag double       % K(i,i) of each bus (buses x sections).
        rm_width double      % [pt] Width of each branch (branches x sections).
        sm_label string      % Label of each bus (buses x sections).
        sv_title string      % Title of each section.
    end
    G.BusColorData = rm_diag(:, k);
    G.BranchLineWidth = rm_width(:, k);
    G.BusLabel = sm_label(:, k);
    G.LabelMode = "user";
    title(G.ax(1), sv_title(min(k, end)));
end
