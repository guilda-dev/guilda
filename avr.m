classdef avr < handle
% AVRを定義するスーパークラス
% AVRコントローラモデルを実装する場合はこのクラスを継承する。
    
    properties
        Vfd_st %界磁電圧の定常値
        Vabs_st %母線電圧の定常値
        sys %システム行列を格納するプロパティ
    end
    
    methods
        function obj = avr()
            sys = ss([0 0 1]);
            sys.InputGroup.Vabs = 1;
            sys.InputGroup.u_avr = 3;
            sys.InputGroup.Efd = 2;
            sys.OutputGroup.Vfd = 1;
            obj.sys = sys;
        end
        
        function nx = get_nx(obj)
            nx = 0;
        end
        
        function x = initialize(obj, Vfd, V)
            obj.Vfd_st = Vfd;
            obj.Vabs_st = V;
            x = [];
        end
        
        function [dx, Vfd] = get_Vfd(obj, x_avr, Vabs, Efd,  u)
            %Vfd = obj.Vfd_st - u;
            Vfd = obj.Vfd_st + u;
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
                    name_tag{i} = ['state_avr',num2str(i)];
                end
            end
        end
        
    end
end

