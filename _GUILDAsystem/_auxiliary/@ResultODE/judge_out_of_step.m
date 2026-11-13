function verdict = judge_out_of_step(obj, opt)
% Judge the result by the rotor angles: out of step beyond a threshold from a reference.
%
% The units judged are the components with the state
% delta (synchronous generators). A unit is out of step when the absolute value of its
% rotor angle relative to the reference exceeds Threshold (360 degrees) at any time of the
% result. The verdict is
%
% - "out-of-step" when a unit is out of step (also when the simulation stopped early after
%   that),
% - "incomplete" when no unit is out of step but the simulation did not reach its end
%   (result.flag ~= 1; also flag = 2, a run stopped by StopOnOutOfStep at an angle below
%   Threshold),
% - "stable" otherwise.
%
% A run stopped by StopOnOutOfStep (flag = 2) from the same reference at StopAngle >=
% Threshold is "out-of-step" for the unit of output.outOfStep at the time of the stop,
% even when the angle at the located stop is a rounding error below StopAngle.
%
% The reference is the generator of the slack bus (Reference="slack", the default; the
% first component with delta on the slack bus of the network snapshot sct_network), the
% center of inertia of all the units (Reference="COI", weights the dynamics parameter M of
% the snapshot), or a unit given by its tag. The states of a tripped unit are NaN while it
% is tripped and do not count; they are left out of the center of inertia at those times.
% Only the result is read, so the judgment works after the network is edited or deleted.
% For another criterion, write a function of the result: v = my_judge(result).
%
% <@Examples>
% ```matlab
% result  = net.simulate("fault");
% verdict = result.judge_out_of_step();
% verdict = result.judge_out_of_step(Reference="COI", Threshold=180);
% verdict = result.judge_out_of_step(Reference="B003SG1");
% ```
%
% See also ResultODE
    arguments (Input)
        obj
        opt.Reference (1,1) string = "slack" % "slack", "COI", or the tag of a unit with delta.
        opt.Threshold (1,1) double {mustBePositive} = 360 % [deg] Largest allowed absolute rotor angle relative to the reference.
    end
    arguments (Output)
        verdict struct % Verdict ("stable" | "out-of-step" | "incomplete"), Time [s] (first time beyond Threshold, NaN when none), Units (tags of the units out of step), MaxAngle [deg] (largest absolute relative angle), Reference, Threshold.
    end
    tab   = obj.tab_variable;
    sv_cp = vertcat(strings(0,1), obj.c_component{:});
    lv_d  = tab.Kind == "x" & tab.Name == "delta" & ismember(tab.Owner, sv_cp);
    if ~any(lv_d)
        error(msg("GUILDA:ResultODE:NoRotorAngle"));
    end
    sv_unit = tab.Owner(lv_d);
    sv_bus  = tab.Bus(lv_d);
    m_delta = obj.rm_variable(:, lv_d);
    rv_t    = obj.rv_t;
    a_bus   = obj.sct_network.a_Bus;

    switch lower(opt.Reference)
        case "slack"
            lv_slack = cellfun(@(b) b.l_isSlack, a_bus);
            sv_slack = string(cellfun(@(b) b.s_tag, a_bus(lv_slack), 'UniformOutput', false));
            i_ref = find(ismember(sv_bus, sv_slack), 1);
            if isempty(i_ref)
                error(msg("GUILDA:ResultODE:NoSlackGenerator", char(join(sv_slack, ", ")), char(obj.s_network)));
            end
            rv_ref = m_delta(:, i_ref);
            s_ref = sv_unit(i_ref);
        case "coi"
            c_comp = tools.cellfun(@(b) reshape(b.a_Component, [], 1), a_bus);
            c_comp = vertcat(cell(0,1), c_comp{:});
            sv_all = string(cellfun(@(c) c.s_tag, c_comp, 'UniformOutput', false));
            rv_M = zeros(1, numel(sv_unit));
            for k = 1:numel(sv_unit)
                comp = c_comp{sv_all == sv_unit(k)};
                tab_dyn = comp.tab_parameter.dynamics;
                if ~ismember("M", string(tab_dyn.Properties.VariableNames))
                    error(msg("GUILDA:ResultODE:NoInertia", char(sv_unit(k))));
                end
                rv_M(k) = tab_dyn.M(1);
            end
            m_w = ~isnan(m_delta) .* rv_M;
            m_d = m_delta;
            m_d(isnan(m_d)) = 0;
            rv_ref = sum(m_d .* m_w, 2) ./ sum(m_w, 2);
            s_ref = "COI";
        otherwise
            i_ref = find(sv_unit == opt.Reference, 1);
            if isempty(i_ref)
                error(msg("GUILDA:ResultODE:UnknownReference", char(opt.Reference), char(join(sv_unit, ", "))));
            end
            rv_ref = m_delta(:, i_ref);
            s_ref = sv_unit(i_ref);
    end

    m_rel  = abs(m_delta - rv_ref);
    r_lim  = opt.Threshold*pi/180;
    lm_out = m_rel > r_lim;
    lv_out = any(lm_out, 1);
    r_stop = Inf;                       % time of a stop of StopOnOutOfStep beyond Threshold
    sct_st = struct([]);
    if isequal(obj.flag, 2) && isfield(obj.output, "outOfStep")
        sct_st = obj.output.outOfStep;
    end
    if ~isempty(sct_st) && sct_st.Reference == s_ref && sct_st.Angle >= opt.Threshold
        lv_out(sv_unit == sct_st.Unit) = true;
        r_stop = sct_st.Time;
    end

    verdict = struct();
    if any(lv_out)
        verdict.Verdict = "out-of-step";
        verdict.Time    = min([rv_t(find(any(lm_out, 2), 1)); r_stop]);
    elseif ~isequal(obj.flag, 1)
        verdict.Verdict = "incomplete";
        verdict.Time    = NaN;
    else
        verdict.Verdict = "stable";
        verdict.Time    = NaN;
    end
    verdict.Units     = sv_unit(lv_out(:));
    verdict.MaxAngle  = max([m_rel(:); NaN], [], "omitnan")*180/pi;
    verdict.Reference = s_ref;
    verdict.Threshold = opt.Threshold;
end
