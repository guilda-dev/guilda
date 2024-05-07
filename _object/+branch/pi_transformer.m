classdef pi_transformer < branch
%  モデル ：対地静電容量をもつ送電線のπ型回路モデルに位相調整変圧器が組み込まれたモデル
% 親クラス：branchクラス
% 実行方法：obj = branch.pi_transformer(from, to, x, y, tap, phase)
% 　引数　：・from,to: 接続する母線番号
%　 　　　　・　x    ：[1*2 double]の配列。インピーダンスの実部、虚部を並べた配列。
%　　 　　　・　y    ：double値。対地静電容量の値
%　　 　　　・　tap  ：double値。電圧の絶対値の変化率
%　　 　　　・　phase：double値。電圧の偏角の変化量
%
%    
%  ---+  +----+--[x]--+---
%     @  @    |       |        x : impedance
%     @  @   [y]     [y]
%     @  @    |       |     1j*y : admittance
%  ---+  +----------------
%  

    properties(SetAccess = public)
        x
        y
        tap
        phase
    end
    
    methods
        function obj = pi_transformer(from, to, x, y, tap, phase)
            obj@branch(from, to);
            if numel(x) == 2
                x = x(1) + 1j*x(2);
            end
            obj.x = x;
            obj.y = y;
            obj.tap = tap;
            obj.phase = phase;
        end
        
        function Ymat = get_admittance_matrix(obj)
            Y = 1 / obj.x;
            b = 1j* obj.y;
            r = obj.tap * exp(1j*obj.phase);

            Ymat = [ (b+Y)/obj.tap^2,  -Y/conj(r) ;
                                -Y/r,        b+Y  ];
        end

        %% Setメソッド
        %%%%%%%%%%%%%%%%%%%%%%%
        function set.x(obj,val)
            obj.x = val;
            obj.editted("x");
        end
        function set.y(obj,val)
            obj.y = val;
            obj.editted("y");
        end
        function set.tap(obj,val)
            obj.tap = val;
            obj.editted("tap");
        end
        function set.phase(obj,val)
            obj.phase = val;
            obj.editted("phase");
        end
    end
    
end