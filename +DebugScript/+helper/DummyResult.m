classdef DummyResult < ResultBase
% ResultBase の契約を確かめるための最小の結果クラス (テスト専用)
%
%   res = DebugScript.helper.DummyResult(net, solver, options, flag, output, elapsed, value)
%
% Plot だけを実装し、export は基底クラスのまま (未対応エラー) にしている。
    properties (SetAccess=private)
        value  % Plot で描く値
    end
    methods
        function obj = DummyResult(net, solver, options, flag, output, elapsed, value)
            arguments (Input)
                net      % 電力系統
                solver   % 解析に使ったソルバー
                options  % 解析の設定
                flag     % 終了フラグ
                output   % 解析の詳細
                elapsed  % [s] 計算時間
                value    % Plot で描く値
            end
            arguments (Output)
                obj  % 作成したオブジェクト
            end
            obj@ResultBase(net, solver, options, flag, output, elapsed);
            obj.value = value;
        end
        function h = Plot(obj, opt)
            arguments (Input)
                obj
                opt.Parent = []
            end
            arguments (Output)
                h  % 描いた線
            end
            if isempty(opt.Parent)
                opt.Parent = axes(figure("Visible", "off"));
            end
            h = plot(opt.Parent, obj.value);
        end
    end
end
