function tab_model_select(G, a_target, net)
% Select in the diagram the element of the model shown: a bus, a branch or a component.
%
% A local controller selects its component (searched through the controllers of every
% component, nested ones included). The network, a global controller or a scenario has no
% element: the selection is cleared.
    arguments (Input)
        G         % Diagram, or [] before the first one.
        a_target  % Model shown in the model GUI.
        net       % Network of the model GUI.
    end
    arguments (Output)
    end
    if ~(isa(G, "GraphNetDiagram") && isscalar(G) && isvalid(G))
        return
    end
    s_tag = "";
    if ~isvalid(a_target)
        % deleted: no element
    elseif isa(a_target, "Bus") || isa(a_target, "Branch") || isa(a_target, "Component")
        s_tag = string(a_target.s_tag);
    elseif isa(a_target, "LocalController")
        for i_bus = 1:numel(net.a_Bus)
            for i_comp = 1:numel(net.a_Bus{i_bus}.a_Component)
                comp = net.a_Bus{i_bus}.a_Component{i_comp};
                c_stack = reshape(comp.a_LocalController, 1, []);
                while ~isempty(c_stack) && s_tag == ""
                    if c_stack{1} == a_target
                        s_tag = string(comp.s_tag);
                    end
                    c_stack = [c_stack(2:end), reshape(c_stack{1}.a_LocalController, 1, [])];
                end
            end
        end
    end
    if isequal(G.Selection, s_tag) || (s_tag == "" && isempty(G.Selection))
        return
    end
    G.clear_selection();
    if s_tag ~= "" && ismember(s_tag, G.tab_element.Tag)
        G.select(s_tag);
    end
end
