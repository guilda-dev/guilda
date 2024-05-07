classdef T < branch
% モデル　：対地静電容量をもつ送電線のπ型回路モデル
% 親クラス：branchクラス
% 実行方法：obj = branch.pi(from, to, x, y)
% 　引数　：・from,to : 接続する母線番号
% 　　　　　・　x　：[1*2 double]の配列。インピーダンスの実部、虚部を並べた配列。
% 　　　　　・　y　：double値。対地静電容量の値
% 　出力　：branchクラスのインスタンス
%
%
%  ---[x/2]--+--[x/2]---
%            |               x : impedance
%           [y]
%            |            1j*y : admittance
%  ---------------------

    properties(SetAccess = public)
       x
       y
    end
    
    methods
        function obj = T(from, to, x, y)
           obj@branch(from, to);
           if numel(x) == 2
               x = x(1) + 1j*x(2);
           end
           obj.x = x;
           obj.y = y;
        end
        
        function Ymat = get_admittance_matrix(obj)
            Y =  2 / obj.x;
            b = 1j * obj.y;

            Ymat = [ Y*(Y+b),    -Y^2 ;
                        -Y^2, (Y+b)*Y ] ...
                   /(Y+b+Y);
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
    end
    
end