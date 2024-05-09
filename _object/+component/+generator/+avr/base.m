classdef base < base_class.handleCopyable
% AVRを定義するスーパークラス
% AVRコントローラモデルを実装する場合はこのクラスを継承する。
    
    properties
        Vfd_st  = 0;%界磁電圧の定常値
        Vabs_st = 0;%母線電圧の定常値
        sys %システム行列を格納するプロパティ
    end
    
    methods
        function obj = base()
            sys = ss([0 0 1]);
            sys.InputGroup.Vabs = 1;
            sys.InputGroup.u_avr = 3;
            sys.InputGroup.Efd = 2;
            sys.OutputGroup.Vfd = 1;
            obj.sys = sys;
        end
        
        function nx = get_nx(~)
            nx = 0;
        end
        
        function nu = get_nu(~)
            nu = 1;
        end

        function M = Mass(obj)
            M = eye(obj.get_nx);
        end
        
        function nx = naming_port(obj)
            nx = convertStringsToChars("u_avr"+(1:obj.get_nu));
        end
        
        function [x,u] = initialize(obj, Vfd, V)
            obj.Vfd_st = Vfd;
            obj.Vabs_st = V;
            x = [];
            u = Vfd;
        end
        
        function [dx, Vfd] = get_Vfd(obj, x_avr, Vabs, Efd,  u)%#ok
            Vfd = u;
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
                    name_tag{i} = ['state_avr',num2str(i)];
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

