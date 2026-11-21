function rv_center = center_of_inertia(obj, m_value, sv_unit, s_errorId)
% Center of inertia of a quantity of some units: the mean weighted by their inertia M.
%
% The weight of a unit is the dynamics parameter M of the component in the network
% snapshot sct_network. A unit whose value is NaN at a time (tripped) is left out of the
% mean at that time. Called by judge_out_of_step (rotor angles) and get_trajectory.
    arguments (Input)
        obj                       % The result (ResultODE).
        m_value double            % Values: one row per time, one column per unit.
        sv_unit (:,1) string      % Component tags of the columns of m_value.
        s_errorId (1,1) string    % Message id when a unit has no M (an id of msg with the unit tag as its argument).
    end
    arguments (Output)
        rv_center (:,1) double    % Center of inertia at each time (NaN when every unit is NaN).
    end
    c_comp = tools.cellfun(@(b) reshape(b.a_Component, [], 1), obj.sct_network.a_Bus);
    c_comp = vertcat(cell(0,1), c_comp{:});
    sv_all = string(cellfun(@(c) c.s_tag, c_comp, 'UniformOutput', false));
    rv_M = zeros(1, numel(sv_unit));
    for k = 1:numel(sv_unit)
        comp = c_comp{sv_all == sv_unit(k)};
        tab_dyn = comp.tab_parameter.dynamics;
        if ~ismember("M", string(tab_dyn.Properties.VariableNames))
            error(msg(s_errorId, char(sv_unit(k))));
        end
        rv_M(k) = tab_dyn.M(1);
    end
    m_w = ~isnan(m_value) .* rv_M;
    m_d = m_value;
    m_d(isnan(m_d)) = 0;
    rv_center = sum(m_d .* m_w, 2) ./ sum(m_w, 2);
end
