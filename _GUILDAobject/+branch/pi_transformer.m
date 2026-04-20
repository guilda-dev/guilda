classdef pi_transformer < Branch
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

    properties(Constant)
        key = "pi_transformer"
    end
    methods(Access={?PowerNetwork})
        function obj = pi_transformer(index, varargin)
            obj@Branch("ET"+index, varargin{:})
        end
    end
       
    methods
        function Ymat = get_admittance_matrix(obj)
            para  = obj.para_dynamics;
            yij   = 1/(para.R+1j*para.X);
            cij   = 1j * para.C;
            tap   = para.tap;
            phase = para.phase;

            r    = tap * exp(1j*phase);
            Ymat = [ (cij+yij)/tap^2,  -yij/conj(r) ;
                          -yij/r    ,      cij+yij  ];
        end
    end
    
end