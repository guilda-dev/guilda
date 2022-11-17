classdef pss_IEEE_PSS1 < pss
% モデル ：IEEE-PSS1型のPSSの実装モデル
%         発電機モデルに付加するために実装されたクラス
%親クラス：handleクラス
%実行方法：obj = pss(parameter)
%　引数　：parameter : table型．「'Kpss','Tws','Td1','Tn1','Td2','Tn2'」を列名として定義
%　出力　：pssクラスのインスタンス
% ※ システム行列による線形化モデルには飽和関数が含まれていない。

    properties
        Vpss_min
        Vpss_max
    end

    methods
        function obj = pss_IEEE_PSS1(pss_in)
            obj@pss(pss_in);
        end

        function name_tag = get_state_name(obj)
            name_tag = {'xi_ws','xi1','xi2'};
        end

        function [dx, u] = get_u(obj, x_pss, omega)
            dx = obj.A*x_pss + obj.B*omega;
            u_temp = obj.C*x_pss + obj.D*omega;
            u  = max( obj.Vpss_min, min( obj.Vpss_max, u_temp));%飽和関数
        end

        function set_pss(obj, pss)
            if istable(pss)
                Kpss = pss{:, 'Kpss'};
                Tws  = pss{:, 'Tws'};
                Td1  = pss{:, 'Td1'};
                Tn1  = pss{:, 'Tn1'};
                Td2  = pss{:, 'Td2'};
                Tn2  = pss{:, 'Tn2'};
                obj.A = [
                                    - 1/Tws,                       0,      0;...
                              1/Tn1 - 1/Td1,                  -1/Td1,      0;...
                    (1/Tn2 - 1/Td2)*Tn1/Td1, (1/Tn2 - 1/Td2)*Tn1/Td1, -1/Td2 ...
                    ];

                obj.B = [
                    Kpss/Tws;
                    Kpss * (1/Td1 - 1/Tn1);
                    Kpss * (1/Td2 - 1/Tn2)*Tn1/Td1;
                    ];

                obj.C = [ - Tn2/Td2*Tn1/Td1, - Tn2/Td2*Tn1/Td1, - Tn2/Td2];
                obj.D = Kpss * Tn2/Td2*Tn1/Td1;
            else
                [obj.A, obj.B, obj.C, obj.D] = ssdata(pss);
            end
            obj.nx = size(obj.A, 1);
            obj.Vpss_max = pss{:,'Vpss_max'};
            obj.Vpss_min = pss{:,'Vpss_min'};
        end
    end

end