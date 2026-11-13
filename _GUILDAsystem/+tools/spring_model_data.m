function sct_data = spring_model_data(sct_network, sct_value, opt)
% Build the data of a spring-mass picture (GraphSpring2D, GraphSpring3D) from a network snapshot.
%
% The shared builder of PowerNetwork.plot_spring_model, ResultODE.plot_spring_model and
% ResultPF.plot_spring_model. It reads only data: the snapshot struct(net, false) and the
% values of the buses and components over time, so it works for a network and for the
% stored data of a result alike. The output is the struct of the GraphSpringBase class help.
%
% - Nodes: every bus (kind "bus"), then one node of kind "component" for each component
%   whose class returns a non-empty E from its Static get_spring_node (called through the
%   class name), with a spring bus - node named by the component tag. OwnNode=false gives
%   the buses only.
% - Springs: the two end buses of each branch, named by the branch tag.
% - Arrows: one pair (P, Iq) on each own node, from its get_spring_node. One pair on each
%   bus that has a component without an own node: the current is the bus injection minus
%   the currents cv_I of the own-node components of the bus (NaN, a tripped unit, counts
%   as 0), evaluated at the bus voltage by Component.get_spring_node.
% - Appearance: Marker, MarkerSize and Color of the graph parameters of the bus or of the
%   component of an own node. rv_circle = |E| when |E| of an own node is constant over
%   two or more samples (relative spread < 1e-9, NaN samples ignored); NaN otherwise.
%
% <@Examples>
% ```matlab
% net = network.IEEE9bus();
% sct = struct(net, false);
% a_bus = sct.a_Bus;
% val.rv_t = 0;
% val.cm_V = cellfun(@(b) b.c_Vequilibrium, a_bus(:));
% val.cm_I = cellfun(@(b) b.c_Iequilibrium, a_bus(:));
% val.c_x  = cellfun(@(b) cellfun(@(c) c.rv_Xequilibrium, b.a_Component(:), "UniformOutput", false), a_bus(:), "UniformOutput", false);
% val.c_u  = cellfun(@(b) cellfun(@(c) c.rv_Uequilibrium, b.a_Component(:), "UniformOutput", false), a_bus(:), "UniformOutput", false);
% G = GraphSpring2D(tools.spring_model_data(sct, val));
% ```
%
% See also PowerNetwork.plot_spring_model, ResultODE.plot_spring_model, ResultPF.plot_spring_model, GraphSpringBase, Component.get_spring_node
    arguments (Input)
        sct_network (1,1) struct % Snapshot of the network: struct(net, false).
        sct_value   (1,1) struct % Values: rv_t (1 x n_t) [s]; cm_V, cm_I (n_bus x n_t) [pu] bus voltage and injected current in a_Bus order; c_x, c_u: per bus a cell of the states (n_x x n_t) and inputs (n_u x n_t) of each component (used when OwnNode is true).
        opt.OwnNode (1,1) logical = true % Add the own nodes of the components.
    end
    arguments (Output)
        sct_data (1,1) struct % Data of the picture (see GraphSpringBase).
    end
    a_bus = reshape(sct_network.a_Bus, [], 1);
    n_bus = numel(a_bus);
    rv_t  = reshape(sct_value.rv_t, 1, []);
    n_t   = numel(rv_t);
    cm_Vbus = sct_value.cm_V;
    cm_Ibus = sct_value.cm_I;

    sv_node   = strings(n_bus, 1);
    sv_marker = strings(n_bus, 1);
    rv_size   = nan(n_bus, 1);
    sv_color  = strings(n_bus, 1);
    for i = 1:n_bus
        sv_node(i) = a_bus{i}.s_tag;
        [sv_marker(i), rv_size(i), sv_color(i)] = graph_style(a_bus{i});
    end
    sv_kind   = repmat("bus", n_bus, 1);
    cm_V      = cm_Vbus;
    rv_circle = nan(n_bus, 1);

    % Branch springs
    a_branch = reshape(sct_network.a_Branch, [], 1);
    im_edge  = zeros(2, numel(a_branch));
    sv_edge  = strings(numel(a_branch), 1);
    for k = 1:numel(a_branch)
        sv_ref = string(a_branch{k}.a_Bus(:));       % "net.a_Bus{i}" (snapshot) or bus tags
        for m = 1:2
            s_num = regexp(sv_ref(m), "a_Bus\{(\d+)\}", "tokens", "once");
            if ~isempty(s_num)
                im_edge(m, k) = str2double(s_num);
            else
                im_edge(m, k) = find(sv_node == sv_ref(m), 1);
            end
        end
        sv_edge(k) = a_branch{k}.s_tag;
    end

    % Own nodes and their arrows; the rest of each bus current
    iv_arrow = zeros(0, 1);
    rm_P     = zeros(0, n_t);
    rm_Iq    = zeros(0, n_t);
    cm_Irest = cm_Ibus;
    lv_rest  = false(n_bus, 1);
    for i = 1:n_bus
        a_comp = reshape(a_bus{i}.a_Component, [], 1);
        rm_Vi  = [real(cm_Vbus(i, :)); imag(cm_Vbus(i, :))];
        for j = 1:numel(a_comp)
            comp = a_comp{j};
            if ~opt.OwnNode
                lv_rest(i) = true;
                continue
            end
            rr_param = zeros(1, 0);
            if ~isempty(comp.sv_para)
                rr_param = comp.tab_parameter.dynamics{:, comp.sv_para};
            end
            [cv_E, rv_P, rv_Iq, cv_I] = feval(comp.class + ".get_spring_node", ...
                sct_value.c_x{i}{j}, rm_Vi, zeros(2, n_t), sct_value.c_u{i}{j}, rr_param);
            if isempty(cv_E)
                lv_rest(i) = true;
                continue
            end
            cv_I(isnan(cv_I)) = 0;                       % a tripped unit injects nothing
            cm_Irest(i, :) = cm_Irest(i, :) - cv_I;

            i_node = numel(sv_node) + 1;
            sv_node(i_node, 1) = comp.s_tag;
            sv_kind(i_node, 1) = "component";
            cm_V(i_node, :)    = cv_E;
            [sv_marker(i_node, 1), rv_size(i_node, 1), sv_color(i_node, 1)] = graph_style(comp);
            rv_abs = abs(cv_E(isfinite(cv_E)));
            rv_circle(i_node, 1) = NaN;
            if n_t >= 2 && ~isempty(rv_abs) && (max(rv_abs) - min(rv_abs)) <= 1e-9*mean(rv_abs)
                rv_circle(i_node, 1) = mean(rv_abs);
            end
            im_edge(:, end+1) = [i; i_node];              %#ok<AGROW>
            sv_edge(end+1, 1) = comp.s_tag;               %#ok<AGROW>
            iv_arrow(end+1, 1) = i_node;                  %#ok<AGROW>
            rm_P(end+1, :)     = rv_P;                    %#ok<AGROW>
            rm_Iq(end+1, :)    = rv_Iq;                   %#ok<AGROW>
        end
    end
    for i = find(lv_rest)'
        rm_Vi = [real(cm_Vbus(i, :)); imag(cm_Vbus(i, :))];
        rm_Ii = [real(cm_Irest(i, :)); imag(cm_Irest(i, :))];
        [~, rv_P, rv_Iq] = Component.get_spring_node(zeros(0, n_t), rm_Vi, rm_Ii, zeros(0, n_t), zeros(1, 0));
        iv_arrow(end+1, 1) = i;                           %#ok<AGROW>
        rm_P(end+1, :)     = rv_P;                        %#ok<AGROW>
        rm_Iq(end+1, :)    = rv_Iq;                       %#ok<AGROW>
    end

    sct_data = struct("rv_t", rv_t, "sv_node", sv_node, "sv_kind", sv_kind, "cm_V", cm_V, ...
        "im_edge", im_edge, "sv_edge", sv_edge, "iv_arrow", iv_arrow, "rm_P", rm_P, "rm_Iq", rm_Iq, ...
        "sv_marker", sv_marker, "rv_size", rv_size, "sv_color", sv_color, "rv_circle", rv_circle);
end


function [s_marker, r_size, s_color] = graph_style(sct_obj)
% Marker, MarkerSize and Color of the graph parameters of a bus or component snapshot.
    arguments (Input)
        sct_obj (1,1) struct % Snapshot of a bus or component (with tab_parameter).
    end
    arguments (Output)
        s_marker (1,1) string % Marker ("" for the default).
        r_size   (1,1) double % Marker size (NaN for the default).
        s_color  (1,1) string % Color ("" for the default).
    end
    s_marker = "";
    r_size   = NaN;
    s_color  = "";
    tab = sct_obj.tab_parameter;
    if ~ismember("graph", tab.Properties.VariableNames)
        return
    end
    tab_g = tab.graph;
    sv_col = string(tab_g.Properties.VariableNames);
    if ismember("Marker", sv_col),     s_marker = string(tab_g.Marker);   end
    if ismember("MarkerSize", sv_col), r_size   = double(tab_g.MarkerSize); end
    if ismember("Color", sv_col),      s_color  = string(tab_g.Color);    end
    if ismissing(s_marker), s_marker = ""; end
    if ismissing(s_color),  s_color  = ""; end
end

