function l = is_stale(net)
% 系統のどこかが古いか (解析が GUILDA:SolverODE:Stale などで止まるか)
%
%   l = DebugScript.helper.is_stale(net)
    arguments (Input)
        net
    end
    arguments (Output)
        l (1,1) logical  % 古いものがあれば true
    end
    l = ~isempty(DebugScript.helper.stale(net));
end
