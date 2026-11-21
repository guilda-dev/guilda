function [G, sv_bus, sv_comp, sv_text] = section_diagram(obj, s_name, c_opt)
% Diagram of the snapshot sct_network with one sample per section (plot_kernel and
% plot_participation): the topology (a state of NaN), the colors and labels set by the
% caller ("user").
%
% The samples are rv_t when its times are finite and nondecreasing, else the section
% numbers; with more than one section their text ("<s_name>, section k of n, t = ...") is
% the title and the text of the playback bar.
    arguments (Input)
        obj    ResultLIN          % The result (of the network, with sct_network).
        s_name (1,1) string       % What is shown, the start of the title (e.g. "Left kernel 1").
        c_opt  (1,:) cell         % Name-Value options of GraphNetDiagram (Parent included).
    end
    arguments (Output)
        G                         % The diagram (GraphNetDiagram).
        sv_bus  (:,1) string      % Bus tags in the order of the diagram (a_Bus of the snapshot).
        sv_comp (:,1) string      % Full component tags in the order of the diagram.
        sv_text (1,:) string      % Title of each section (s_name alone for one section).
    end
    sct_net = obj.sct_network;
    if ~isfield(sct_net, "a_Bus") || ~isfield(sct_net, "a_Branch")
        error(msg("GUILDA:ResultLIN:NetworkOnly", "A diagram of the result"))
    end
    a_bus = reshape(sct_net.a_Bus, [], 1);
    sv_bus = string(cellfun(@(b) b.s_tag, a_bus, "UniformOutput", false));
    n_comp = sum(cellfun(@(b) numel(b.a_Component), a_bus));
    n_t = numel(obj.rv_t);
    rv_sample = reshape(double(obj.rv_t), 1, []);
    if ~(all(isfinite(rv_sample)) && all(diff(rv_sample) >= 0))
        rv_sample = 1:n_t;
    end
    sct_state = struct("rv_t", rv_sample, "cm_Vbus", NaN(numel(sv_bus), n_t), "cm_Icomp", NaN(n_comp, n_t));
    sv_text = s_name;
    if n_t > 1
        sv_text = s_name + ", " + compose("section %d of %d, t = %g", (1:n_t)', n_t, reshape(double(obj.rv_t), [], 1))';
        sct_state.s_sampleName  = "Section";
        sct_state.sv_sampleText = sv_text;
    end
    G = GraphNetDiagram(sct_net, sct_state, "ColorMode", "user", "FlowMode", "none", c_opt{:});
    if n_t == 1
        title(G.ax, s_name);
    end
    tab = G.tab_element;
    sv_comp = tab.Tag(tab.Kind == "component");
end
