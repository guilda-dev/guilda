classdef base < base_class.handleCopyable
% モデル ：ガバナの実装モデル
%         発電機モデルに付加するために実装されたクラス
%親クラス：handleクラス
%実行方法：obj = governor()
%　引数　：なし
%　出力　：governorクラスのインスタンス
    
    properties
        P_st = 0;
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
        
        function [x,u] = initialize(obj, P)
            obj.P_st = P;
            x = [];
            u = P;
        end
        
        function nx = get_nx(~)
            nx = 0;
        end
        
        function nx = get_nu(~)
            nx = 1;
        end

        function M = Mass(obj)
            M = eye(obj.get_nx);
        end
        
        function nx = naming_port(obj)
            nx = convertStringsToChars("u_gov"+(1:obj.get_nu));
        end
        
        function [dx, P] = get_P(obj, x_gov, omega, u)%#ok
            P  =  u;
            dx = [];
        end
        
        function sys = get_sys(obj)
            sys = obj.sys;
        end

        function name_tag = naming_state(obj)
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

