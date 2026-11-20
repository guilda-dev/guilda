function G = tab_sim_diagram(G, h_parent, h_panel, sct_app)
% Diagram of the time simulation tab: the network at the equilibrium with the targets of the scenario selected.
%
% net.plot_diagram(State="auto") (draw_network) with the targets of the scenario selected:
% the buses and branches of tab_event (faults, openings), the tripped units and the units
% with an offset or an input. A local controller marks its component; a global controller
% has no element. A run does not change the drawing: the result is viewed in the Analyze
% result window.
%
% A drawing error falls back to draw_network. Nothing is logged.
    arguments (Input)
        G          % Diagram of the tab, or [].
        h_parent   % Diagram panel of the tab.
        h_panel    % Panel of the tab (UserData: the state, see tab_sim_build).
        sct_app    % Tab API (see tab_list).
    end
    arguments (Output)
        G  % Diagram drawn ([] for a network without buses). <@Type> GraphNetDiagram
    end
    net = sct_app.history.get_variable("net");
    sct = h_panel.UserData;
    try
        G = draw_network(G, h_parent, net, true);
        if isempty(G) || isempty(sct.sc) || ~isvalid(sct.sc)
            return
        end
        sc = sct.sc;
        sv_target = unique([string(sc.tab_event.Target); string(sc.tab_offset.OffsetUnit); string(sc.tab_input.InputUnit)]);
        sv_tag = intersect(sv_target, G.tab_element.Tag);
        % local controllers (nested ones too): their component
        for i_bus = 1:numel(net.a_Bus)
            for i_comp = 1:numel(net.a_Bus{i_bus}.a_Component)
                comp = net.a_Bus{i_bus}.a_Component{i_comp};
                c_stack = reshape(comp.a_LocalController, 1, []);
                while ~isempty(c_stack)
                    if ismember(string(c_stack{1}.s_tag), sv_target)
                        sv_tag = union(sv_tag, string(comp.s_tag));
                        break
                    end
                    c_stack = [c_stack(2:end), reshape(c_stack{1}.a_LocalController, 1, [])];
                end
            end
        end
        if ~isempty(sv_tag)
            G.select(reshape(sv_tag, 1, []));
        end
    catch    % fall back to the network without highlight
        G = draw_network([], h_parent, net, true);
    end
end
