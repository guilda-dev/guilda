classdef base < base_class.handleCopyable
% モデル ：ガバナの実装モデル
%         発電機モデルに付加するために実装されたクラス
%親クラス：handleクラス
%実行方法：obj = governor()
%　引数　：なし
%　出力　：governorクラスのインスタンス
    
    properties
        P = 0;
        sys
    end
    
    methods
        function obj = base()
            sys = ss(eye(2));
            sys.InputGroup.omega_governor = 1;
            sys.InputGroup.u_governor = 2;
            sys.OutputGroup.omega_governor = 1;
            sys.OutputGroup.Pmech = 2;
            obj.sys = sys;
        end
        
        function x = initialize(obj, P)
            obj.P = P;
            x = [];
        end
        
        function nx = get_nx(obj)
            nx = 0;
        end
        
        function [dx, P] = get_P(obj, x_gov, omega, u)
            P = obj.P + u;
            dx = [];
        end
        
        function sys = get_sys(obj)
            sys = obj.sys;
        end

        function name_tag = get_state_name(obj)
            nx = obj.get_nx;
            name_tag = cell(1,nx);
            if nx ~= 0
                for i = 1:obj.get_nx
                    name_tag{i} = ['state_governor',num2str(i)];
                end
            end
        end

    end

    methods(Access=protected)
        function PropEditor_Set(obj,prop,val)
            obj.(prop) = val;
        end
        function val = PropEditor_Get(obj,prop)
            val = obj.(prop);
        end
    end
end

