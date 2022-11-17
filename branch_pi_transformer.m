classdef branch_pi_transformer < branch
% モデル  ：対地静電容量をもつ送電線のπ型回路モデルに位相調整変圧器が組み込まれたモデル
%親クラス：conntroller
%実行方法：obj = branch_pi_transformer(from, to, x, y, tap, phase)
%　引数　：・from,to: 接続する母線番号
%　　　　　・　x    ：[1*2 double]の配列。インピーダンスの実部、虚部を並べた配列。
%　　　　　・　y    ：double値。対地静電容量の値
%　　　　　・　tap  ：double値。電圧の絶対値の変化率
%　　　　　・　phase：double値。電圧の偏角の変化量
%　出力　：branchクラスのインスタンス
    
    properties(SetAccess = public)
        x
        y
        tap
        phase
    end
    
    methods
        function obj = branch_pi_transformer(from, to, x, y, tap, phase)
            obj@branch(from, to);
            if numel(x) == 2
                x = x(1) + 1j*x(2);
            end
            obj.x = x;
            obj.y = y;
            obj.tap = tap;
            obj.phase = phase;
        end
        
        function Y = get_admittance_matrix(obj)
            x = obj.x;
            y = obj.y;
            tap = obj.tap;
            phase = obj.phase;
            Y = [(1j*y+1/x)/tap^2, -1/x/tap/exp(-1j*phase);
                -1/x/tap/exp(1j*phase), 1j*y+1/x ];
        end
    end
    
end