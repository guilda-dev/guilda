classdef T < Branch
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
    

    properties(Constant)   
        header = "EL"
        key    = "T"
    end
       
    methods
        function Ymat = get_admittance_matrix(obj)
            para  = obj.para_dynamics;
            yij   = 1/(para.R+1j*para.X);
            cij   = 1j * para.C;
            
            Y = 2 * yij;
            b = cij;

            Ymat = [ Y*(Y+b),    -Y^2 ;
                        -Y^2, (Y+b)*Y ] /(Y+b+Y);
        end

    end
    
end