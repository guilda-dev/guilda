function verdict = out_of_step(result, opt)
% Judge a result by the rotor angles: out of step beyond a threshold from a reference.
%
% The default Judge of a scenario. The units judged are the components with the state
% delta (synchronous generators). A unit is out of step when the absolute value of its
% rotor angle relative to the reference exceeds Threshold (360 degrees) at any time of the
% result. The verdict is
%
% - "out-of-step" when a unit is out of step (also when the simulation stopped early after
%   that),
% - "incomplete" when no unit is out of step but the simulation did not reach its end
%   (result.flag ~= 1),
% - "stable" otherwise.
%
% The reference is the generator of the slack bus (Reference="slack", the default; the
% first component with delta on the slack bus of the network of the result), the center of
% inertia of all the units (Reference="COI", weights the dynamics parameter M), or a unit
% given by its tag. The states of a tripped unit are NaN while it is tripped and do not
% count; they are left out of the center of inertia at those times.
%
% <@Examples>
% ```matlab
% result  = net.simulate(sc);
% verdict = Scenario.out_of_step(result);           % same as sc.judge(result) by default
% verdict = Scenario.out_of_step(result, Reference="COI", Threshold=180);
% sc.Judge = @(r) Scenario.out_of_step(r, Reference="SG1B003");
% ```
%
% See also Scenario.judge, ODEresult
    arguments
        result (1,1) ODEresult % Result of net.simulate.
        opt.Reference (1,1) string = "slack" % "slack", "COI", or the tag of a unit with delta.
        opt.Threshold (1,1) double {mustBePositive} = 360 % [deg] Largest allowed absolute rotor angle relative to the reference.
    end
    arguments (Output)
        verdict struct % Verdict ("stable" | "out-of-step" | "incomplete"), Time [s] (first time beyond Threshold, NaN when none), Units (tags of the units out of step), MaxAngle [deg] (largest absolute relative angle), Reference, Threshold.
    end
    tab   = result.tab_variable;
    sv_cp = vertcat(strings(0,1), result.c_component{:});
    lv_d  = tab.Kind == "x" & tab.Name == "delta" & ismember(tab.Owner, sv_cp);
    if ~any(lv_d)
        error(msg("GUILDA:Scenario:NoRotorAngle"));
    end
    sv_unit = tab.Owner(lv_d);
    sv_bus  = tab.Bus(lv_d);
    m_delta = result.rm_variable(:, lv_d);
    rv_t    = result.rv_t;

    switch lower(opt.Reference)
        case "slack"
            net = result.a_PowerNetwork;
            lv_slack = cellfun(@(b) b.l_isSlack, net.a_Bus);
            str_slack = string(net.a_Bus(lv_slack));
            i_ref = find(ismember(sv_bus, str_slack), 1);
            if isempty(i_ref)
                error(msg("GUILDA:Scenario:NoSlackGenerator", char(join(str_slack, ", ")), char(net.str_tag)));
            end
            rv_ref = m_delta(:, i_ref);
            str_ref = sv_unit(i_ref);
        case "coi"
            net = result.a_PowerNetwork;
            c_comp = tools.cellfun(@(b) b.a_Component, net.a_Bus);
            c_comp = vertcat(cell(0,1), c_comp{:});
            sv_all = string(c_comp);
            rv_M = zeros(1, numel(sv_unit));
            for k = 1:numel(sv_unit)
                comp = c_comp{sv_all == sv_unit(k)};
                tab_dyn = comp.tab_parameter.dynamics;
                if ~ismember("M", string(tab_dyn.Properties.VariableNames))
                    error(msg("GUILDA:Scenario:NoInertia", char(sv_unit(k))));
                end
                rv_M(k) = tab_dyn.M(1);
            end
            m_w = ~isnan(m_delta) .* rv_M;
            m_d = m_delta;
            m_d(isnan(m_d)) = 0;
            rv_ref = sum(m_d .* m_w, 2) ./ sum(m_w, 2);
            str_ref = "COI";
        otherwise
            i_ref = find(sv_unit == opt.Reference, 1);
            if isempty(i_ref)
                error(msg("GUILDA:Scenario:UnknownReference", char(opt.Reference), char(join(sv_unit, ", "))));
            end
            rv_ref = m_delta(:, i_ref);
            str_ref = sv_unit(i_ref);
    end

    m_rel  = abs(m_delta - rv_ref);
    r_lim  = opt.Threshold*pi/180;
    lm_out = m_rel > r_lim;
    lv_out = any(lm_out, 1);

    verdict = struct();
    if any(lv_out)
        verdict.Verdict = "out-of-step";
        verdict.Time    = rv_t(find(any(lm_out, 2), 1));
    elseif ~isequal(result.flag, 1)
        verdict.Verdict = "incomplete";
        verdict.Time    = NaN;
    else
        verdict.Verdict = "stable";
        verdict.Time    = NaN;
    end
    verdict.Units     = sv_unit(lv_out(:));
    verdict.MaxAngle  = max([m_rel(:); NaN], [], "omitnan")*180/pi;
    verdict.Reference = str_ref;
    verdict.Threshold = opt.Threshold;
end
