classdef pi < branch
% モデル　：対地静電容量をもつ送電線のπ型回路モデル
% 親クラス：branchクラス
% 実行方法：obj = branch.pi(from, to, x, y)
% 　引数　：・from,to : 接続する母線番号
% 　　　　　・　x　：[1*2 double]の配列。インピーダンスの実部、虚部を並べた配列。
% 　　　　　・　y　：double値。対地静電容量の値
% 　出力　：branchクラスのインスタンス
%
%  ---+--[x]--+---
%     |       |        x : impedance
%    [y]     [y]
%     |       |     1j*y : admittance
%  ---------------
%  


    properties(SetAccess = public)
       x
       y
    end
    
    methods
        function obj = pi(from, to, x, y)
           obj@branch(from, to);
           if numel(x) == 2
               x = x(1) + 1j*x(2);
           end
           obj.x = x;
           obj.y = y;
        end
        
        function Ymat = get_admittance_matrix(obj)
            Y = 1 / obj.x;
            b = 1j * obj.y;% /2;

            Ymat = [ b+Y,  -Y ;
                      -Y, b+Y ];
        end
    end
    
end