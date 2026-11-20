function sct_options = ode_options(varargin)
% SolverODE.solve に直接渡す設定 (net.simulate が作るものと同じ形) を作る
%
%   sct_options = DebugScript.helper.ode_options("Progress", "none", "TimeLimit", 5);
%   [d, e, x0] = net.build_simulation_data(sc.s_tag, [0,1]);
%   [sct_sol, flag, output] = net.solver_ODE.solve(d, e, x0, sct_options);   % or DebugScript.helper.solve_direct
%
% GUILDA.setting の TimeSimulation の値 (GUILDA.config が読み込むときに検査・変換済み) に
% Name-Value を重ねる (net.simulate の arguments ブロックの既定値と同じ。値の検査はしない)。
% 呼び出しの Progress の true/false は net.simulate と同じく "dialog"/"none" にする。
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
    for k = 1:2:numel(varargin)
        sct_options.(string(varargin{k})) = varargin{k+1};
    end
    if islogical(sct_options.Progress) || isnumeric(sct_options.Progress)
        sv_mode = ["none", "dialog"];
        sct_options.Progress = sv_mode(1 + logical(sct_options.Progress));
    end
end
