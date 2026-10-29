classdef DummyResult < AnalysisResult
% AnalysisResult の契約を確かめるための最小の結果クラス (テスト専用)
%
%   res = DebugScript.helper.DummyResult(net, solver, options, flag, output, elapsed, value)
%
% Plot だけを実装し、Export は基底クラスのまま (未対応エラー) にしている。
    properties (SetAccess=private)
        value
    end
    methods
        function obj = DummyResult(net, solver, options, flag, output, elapsed, value)
            obj@AnalysisResult(net, solver, options, flag, output, elapsed);
            obj.value = value;
        end
        function h = Plot(obj, opt)
            arguments
                obj
                opt.Parent = []
            end
            if isempty(opt.Parent)
                opt.Parent = axes(figure("Visible", "off"));
            end
            h = plot(opt.Parent, obj.value);
        end
    end
end
