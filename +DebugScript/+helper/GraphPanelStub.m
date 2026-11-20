classdef GraphPanelStub < GraphBase
% テスト用の 2 パネルの図 (GraphBase のフックの約束を確かめる。第 2a 段階の GraphChart の雛形)
%
%   G = DebugScript.helper.GraphPanelStub(sct, Parent=container);
%   rv_w = DebugScript.helper.GraphPanelStub.call_range_map(rv_v, rv_range, rv_lim);   % GraphBase.range_map
%   sct.rv_t (1 x n_t), sct.rm_y (2 x n_t): パネル i に系列 "y<i>" を描く

    properties
        LineColor (:,3) double = zeros(0, 3)    % 系列の色 (2 x 3)
    end
    properties (SetAccess = private)
        sct_data                                % データ
    end

    methods
        function obj = GraphPanelStub(sct_data, opt)
            arguments
                sct_data (1,1) struct
                opt.Parent = []
            end
            obj.load_data(sct_data);
            obj.build(opt, 2);
        end
        function set.LineColor(obj, val)
            obj.LineColor = val;
            if ~isempty(obj.sct_plt) %#ok<MCSUP>
                obj.apply_style((1:2)');
            end
        end
    end

    methods (Static)
        function rv_w = call_range_map(rv_v, rv_range, rv_lim)
            % GraphBase.range_map (protected) を呼ぶ (test_F59)
            rv_w = DebugScript.helper.GraphPanelStub.range_map(rv_v, rv_range, rv_lim);
        end
    end

    methods (Access = protected)
        function load_data(obj, sct_data)
            obj.sct_data  = sct_data;
            obj.rv_t      = sct_data.rv_t;
            obj.i_time    = 1;
            obj.LineColor = [0 0 1; 0 0.5 0];
        end
        function create_scene(obj)
            plt = struct();
            plt.Line   = gobjects(2, 1);
            plt.Cursor = gobjects(2, 1);
            for i = 1:2
                cla(obj.ax(i));
                plt.Line(i) = plot(obj.ax(i), obj.rv_t, obj.sct_data.rm_y(i, :), "Color", obj.LineColor(i, :), ...
                    "ButtonDownFcn", @(~, ~) obj.click_element(i));
                plt.Cursor(i) = xline(obj.ax(i), obj.rv_t(1));
            end
            obj.sct_plt = plt;
        end
        function update_scene(obj, k)
            set(obj.sct_plt.Cursor, "Value", obj.rv_t(k));
        end
        function apply_style(obj, iv_element)
            for i = iv_element'
                obj.sct_plt.Line(i).Color = obj.LineColor(i, :);
            end
        end
        function tab = element_table(~)
            tab = table(["y1"; "y2"], ["line"; "line"], [1; 2], 'VariableNames', ["Tag", "Kind", "Index"]);
        end
        function sct_map = style_properties(~)
            sct_map = struct("line", struct("Color", "LineColor"));
        end
        function apply_selection(obj)
            for i = 1:2
                l_sel = any(obj.Selection == "y" + i);
                obj.sct_plt.Line(i).LineWidth = 0.5 + 2.5*l_sel;
            end
        end
    end
end
