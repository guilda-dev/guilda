function G = plot_kernel(obj, opt)
% Plot the left kernel of the Jacobian of the DAE on the network diagram.
%
% Draws the diagram of the snapshot sct_network (GraphNetDiagram, the topology: no
% flows) and colors each bus by the entry of the left kernel rm_left of get_kernel at its
% bus angle theta (the row of the P balance of the bus), for the kernel (island) Kernel.
% The left kernel w (w' J = 0, dual to the rotation of the phases: w' r = 1) weighs the
% equations of the island in its conserved combination; its entries at the phase
% variables sum to 1 over the island. A bus of another island, or of a section without
% that kernel, is gray (NaN). The components are drawn without a color value (black while
% the buses are colored); the entries at their phase variables (the generator angles
% delta) are written in their labels.
%
% Label chooses the labels:
%
% - "value" (default): each bus "tag: value" (the theta entry), and each component
%   with a phase variable in the kernel its delta entry ("δ value"; several phase
%   variables are joined); the other components have no label.
% - "tag": the tags of the buses and components (LabelMode "tag").
% - "none": no labels.
%
% The color limits are [min max] of the theta entries of the kernel over every section,
% so that the colors compare between sections; G.ColorLimits changes them.
%
% A result with several sections (numel(rv_t) > 1) has one sample per section, at the
% times rv_t (the section numbers when rv_t is not finite and nondecreasing), switched by
% the playback bar or G.set_time(t): the colors and labels follow the kernel of each
% section (the TimeChangedFcn of G). It starts at Index. The section shown first must have
% the kernel: a section without a kernel of the rotation form stops with
% GUILDA:ResultLIN:NoKernel (with the s_message of get_kernel), and a Kernel beyond its
% islands with GUILDA:ResultLIN:KernelRange. Only a result of the network has a kernel;
% another layer stops with GUILDA:ResultLIN:NetworkOnly.
%
% <@Examples>
% ```matlab
% res = net.get_sys();
% G = res.plot_kernel();                    % left kernel of the (first) island
% sct = res.get_kernel();  sct.tab_phase    % the numbers of the colors and labels
% G = res.plot_kernel(Label="tag");
% res = net.get_sys({sim, [0.5 1 2]});
% G = res.plot_kernel(Kernel=2, Index=3);   % second island, from the third section
% ```
%
% See also ResultLIN.get_kernel, GraphNetDiagram, ResultLIN.plot_participation
    arguments (Input)
        obj
        opt.Kernel (1,1) double {mustBeInteger, mustBePositive} = 1  % Kernel (island) drawn: a column of rm_left of get_kernel.
        opt.Label (1,1) string {mustBeMember(opt.Label, ["none","value","tag"])} = "value"  % Labels: "value" (the kernel entries), "tag" or "none".
        opt.Index (1,1) double {mustBeInteger, mustBePositive} = obj.Index  % Section shown first (1 ... numel(rv_t)); res.Index when omitted.
        opt.Parent = []                                        % Container (figure, uifigure, uipanel, uitab, uigridlayout) or axes/uiaxes to draw in; [] for a new figure.
    end
    arguments (Output)
        G  % The diagram (GraphNetDiagram), ColorMode "user" with the kernel entries in BusColorData.
    end
    if ~(isfield(obj.output, "s_layer") && obj.output.s_layer == "PowerNetwork")
        error(msg("GUILDA:ResultLIN:NetworkOnly", "plot_kernel"))
    end
    n_t = numel(obj.rv_t);
    if opt.Index > n_t
        error(msg("GUILDA:ResultLIN:IndexRange", string(n_t)))
    end
    sct_kernel = obj.get_kernel(Index="all");
    tab_first = sct_kernel(opt.Index).tab_phase;
    if isempty(tab_first)
        error(msg("GUILDA:ResultLIN:NoKernel", sct_kernel(opt.Index).s_message))
    end
    if opt.Kernel > max(tab_first.Kernel)
        error(msg("GUILDA:ResultLIN:KernelRange", string(max(tab_first.Kernel))))
    end

    s_label = "tag";
    if opt.Label ~= "tag"
        s_label = "none";
    end
    [G, sv_bus, sv_comp] = section_diagram(obj, "Left kernel " + opt.Kernel, ...
        {"LabelMode", s_label, "ColorbarLabel", "left kernel at \theta", "Parent", opt.Parent});

    % The entries of every section: theta of each bus, delta of each component
    rm_bus = NaN(numel(sv_bus), n_t);
    cm_comp = repmat({strings(0, 1)}, numel(sv_comp), n_t);
    for s = 1:n_t
        tab = sct_kernel(s).tab_phase;
        tab = tab(tab.Kernel == opt.Kernel, :);
        [lv, iv] = ismember(tab.Owner, sv_bus);
        lv = lv & tab.Kind == "Bus";
        rm_bus(iv(lv), s) = tab.Left(lv);
        [lv, iv] = ismember(tab.Owner, sv_comp);
        for j = reshape(find(lv & tab.Kind == "Component"), 1, [])
            cm_comp{iv(j), s}(end+1, 1) = sprintf("%.3g", tab.Left(j));
        end
    end
    sm_busLabel = repmat(sv_bus, 1, n_t);
    lm = ~isnan(rm_bus);
    sm_busLabel(lm) = sm_busLabel(lm) + ": " + compose("%.3g", rm_bus(lm));
    sm_compLabel = strings(numel(sv_comp), n_t);
    lm = ~cellfun(@isempty, cm_comp);
    sm_compLabel(lm) = "δ " + cellfun(@(c) join(c, ", "), cm_comp(lm));
    if opt.Label ~= "value"
        sm_busLabel = strings(numel(sv_bus), 0);
        sm_compLabel = strings(numel(sv_comp), 0);
    end

    rv_v = rm_bus(isfinite(rm_bus));
    if ~isempty(rv_v) && max(rv_v) > min(rv_v)
        G.ColorLimits = [min(rv_v), max(rv_v)];
    end
    show_section(G, opt.Index, rm_bus, sm_busLabel, sm_compLabel);
    if n_t > 1
        G.TimeChangedFcn = @(G, data) show_section(G, data.Index, rm_bus, sm_busLabel, sm_compLabel);
        G.set_time(G.rv_t(opt.Index));
    end
end


function show_section(G, k, rm_bus, sm_busLabel, sm_compLabel)
% Colors and labels of section k (also the TimeChangedFcn of the diagram)
    arguments (Input)
        G                           % The diagram.
        k (1,1) double              % Section.
        rm_bus double               % Color value of each bus (buses x sections).
        sm_busLabel string          % Label of each bus (buses x sections; no columns: the labels of LabelMode).
        sm_compLabel string         % Label of each component (components x sections; no columns: the labels of LabelMode).
    end
    G.BusColorData = rm_bus(:, k);
    if ~isempty(sm_busLabel)
        G.BusLabel = sm_busLabel(:, k);
        G.ComponentLabel = sm_compLabel(:, k);
        G.LabelMode = "user";
    end
end
