function v3_nonunit_dynamic(s_options, c_sysBus)
% Reject a bus with states in the retired option NonUnit.
%
% v3 compatibility hook of LTIresult.get_ss with "Feedback": stops with
% GUILDA:LTIresult:NonUnitDynamicBus. "Kron" and "DAE" never used the option.
%
% Inputs:
%
% - `s_options` — Options of the result; the field NonUnit exists only when buses are listed.
% - `c_sysBus` — Bus models, in the order of net.a_Bus.
%
% See also v3_linearize_args, LTIresult.get_ss
    if ~isfield(s_options, "NonUnit")
        return
    end
    lv_dynamic = ismember(1:numel(c_sysBus), s_options.NonUnit) & ...
                 reshape(tools.vcellfun(@(S) ~isempty(S.A), c_sysBus), 1, []);
    if any(lv_dynamic)
        error("GUILDA:LTIresult:NonUnitDynamicBus", ...
              "NonUnit = [%s] names buses with states, which cannot be eliminated with the network: bus %s.", ...
              num2str(s_options.NonUnit), num2str(find(lv_dynamic)))
    end
end
