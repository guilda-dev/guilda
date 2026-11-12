function sct_options = ode_options(varargin)
% SolverODE.solve に直接渡す設定 (net.simulate が作るものと同じ形) を作る
%
%   sct_options = DebugScript.helper.ode_options("Progress", "none", "TimeLimit", 5);
%   [result, flag, output] = net.solver_ODE.solve(net, [0,1], {sc}, sct_options);
%
% GUILDA.setting の TimeSimulation の値に Name-Value を重ねる (net.simulate の
% ローカル関数 simulate_options と同じ規則。値の検査はしない)。
    arguments (Input, Repeating)
        varargin  % Name-Value (simulate のオプション名)
    end
    arguments (Output)
        sct_options (1,1) struct  % SolverODE.solve の sct_options
    end
    sct_options = struct();
    sct_cfg = GUILDA.config("TimeSimulation");
    for s_name = string(fieldnames(sct_cfg)).'
        sct_options.(s_name) = sct_cfg.(s_name).Value;
    end
    if ~(isnumeric(sct_options.TimeLimit) && isscalar(sct_options.TimeLimit) && sct_options.TimeLimit > 0)
        sct_options.TimeLimit = Inf;
    end
    for s_name = ["MaxStep", "InitialStep"]
        v = sct_options.(s_name);
        if ~(isnumeric(v) && isscalar(v) && v > 0)
            sct_options.(s_name) = NaN;
        end
    end
    for k = 1:2:numel(varargin)
        sct_options.(string(varargin{k})) = varargin{k+1};
    end
    sct_options.Solver   = string(sct_options.Solver);
    if islogical(sct_options.Progress) || isnumeric(sct_options.Progress)
        sv_mode = ["none", "dialog"];
        sct_options.Progress = sv_mode(1 + logical(sct_options.Progress));
    else
        sct_options.Progress = string(sct_options.Progress);
    end
    sct_options.Verbose  = logical(sct_options.Verbose);
    sct_options.SeparateComplexParts = logical(sct_options.SeparateComplexParts);
end
