classdef BadJacobianStub < Component
% validate が解析的なヤコビアンの誤りを検出することを確かめるための機器 (テスト専用)
%
%   comp = DebugScript.helper.stub_component("BadJacobianStub")   % Axx の値と Bxu の大きさが誤り
%
% モデルの関数は誤りのない BadComponentStub ("none") と同じで、Jacobi_dx だけが誤り。
% 登録した写しの親が DebugScript のクラスだとキーの一覧に載らないため、Component を直接継承する。
    properties (Constant)
        key = "test-bad-jacobian-stub"  % 機器の種類のキー
        sv_x = ["x1";"x2"]              % 状態の名前
        sv_u = ["u1";"u2"]              % 入力の名前
        sv_y = "x1"                     % 出力の名前
        sv_para = "bad"                 % 動的パラメータの名前 (BadComponentStub の誤りの番号。1 は "none")
    end
    methods
        function obj = BadJacobianStub(s_tag, ~, opt)
            % add_component から (タグの番号, parameter, 設定) で呼ばれる
            arguments (Input)
                s_tag  % タグの接尾辞
                ~      % add_component の parameter (使わない)
                opt    % add_component の設定
            end
            arguments (Output)
                obj  % 作成したオブジェクト
            end
            obj@Component("BJ" + s_tag, opt);
            obj.a_Parameter{cellfun(@(p) p.s_tag=="dynamics", obj.a_Parameter)} = Parameter(obj, "dynamics", struct("bad", 1));
        end
        function [x, u] = get_equilibrium(~, ~, c_I, ~, ~)
            arguments (Input)
                ~
                ~
                c_I  % [pu] 注入電流 (複素数)
                ~
                ~
            end
            arguments (Output)
                x  % 平衡点の状態
                u  % 平衡点の入力
            end
            u = [real(c_I); imag(c_I)];
            x = u;
        end
    end
    methods (Static)
        function dx = fcn_dx(varargin)
            arguments (Input, Repeating)
                varargin  % BadComponentStub.fcn_dx の引数
            end
            arguments (Output)
                dx  % 状態方程式の右辺
            end
            dx = DebugScript.helper.BadComponentStub.fcn_dx(varargin{:});
        end
        function I = fcn_I(varargin)
            arguments (Input, Repeating)
                varargin  % BadComponentStub.fcn_I の引数
            end
            arguments (Output)
                I  % 注入電流 (複素数)
            end
            I = DebugScript.helper.BadComponentStub.fcn_I(varargin{:});
        end
        function y = fcn_Y(varargin)
            arguments (Input, Repeating)
                varargin  % BadComponentStub.fcn_Y の引数
            end
            arguments (Output)
                y  % 出力
            end
            y = DebugScript.helper.BadComponentStub.fcn_Y(varargin{:});
        end
        function M = fcn_Mass(varargin)
            arguments (Input, Repeating)
                varargin  % BadComponentStub.fcn_Mass の引数
            end
            arguments (Output)
                M  % 質量行列
            end
            M = DebugScript.helper.BadComponentStub.fcn_Mass(varargin{:});
        end
        function [Axx,Bxv,Bxu] = Jacobi_dx(~, ~, ~, ~, ~, ~)
            arguments (Input)
                ~
                ~
                ~
                ~
                ~
                ~
            end
            arguments (Output)
                Axx  % fcn_dx の x によるヤコビアン
                Bxv  % fcn_dx の V によるヤコビアン
                Bxu  % fcn_dx の u によるヤコビアン
            end
            Axx = 2*eye(2);  Bxv = zeros(2);  Bxu = zeros(2,3);
        end
    end
end
