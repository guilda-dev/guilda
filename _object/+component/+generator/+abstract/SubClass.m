classdef SubClass < base_class.handleCopyable
% Governorを定義するスーパークラス
% Governorモデルを実装する場合はこのクラスを継承する。

    properties
        parameter
        generator 
        system_matrix
    end

    properties(Access=protected)
        port_in
        port_out
    end
    properties(SetAccess=protected)
        name
    end


    methods(Abstract)
        [x_st, u_st] = get_equilibrium(obj, varargin);
        [dx, u] = get_dx_u(obj, x, u, varargin);
    end

    
    methods
        function obj = SubClass(Type)
            switch Type
                case "AVR"
                    obj.port_in = {'Vabs','Efd'};
                    obj.port_out= {'Vfd'};
                    obj.name = "avr";
                case "PSS"
                    obj.port_in = {'omega'};
                    obj.port_out = {'v_pss'};
                    obj.name = "pss";
                case "GOVERNOR"
                    obj.port_in = {'omega_governor','P'};
                    obj.port_out = {'Pmech'};
                    obj.name = "gov";
            end
        end

        function nx = get_nx(obj)
            nx = size(obj.system_matrix.B,1);
        end
        
        function nu_user = get_nu(obj)
            nu_all = size(obj.system_matrix.B,2);
            nu_sys = numel(obj.port_in);
            nu_user = nu_all-nu_sys;
        end

        function set.parameter(obj,val)
            if ismethod(obj,'set_parameter')
                obj.set_parameter(val);
            end
            obj.parameter = val;
        end


        function M = Mass(obj)
            M = eye(obj.get_nx);
        end
        
        function uname = naming_port(obj)
            uname = convertStringsToChars("u_"+obj.name+(1:obj.get_nu));
        end

        function xname = naming_state(obj)
            xname = convertStringsToChars("x_"+obj.name+(1:obj.get_nx));
        end

        function set_linear_matrix(obj,varargin)
            [sys.A,sys.B,sys.C,sys.D] = get_linear_matrix(obj,varargin{:});
            obj.system_matrix = sys;
        end

        function [A,B,C,D] = get_linear_matrix(obj, x_st, u_st, varargin)
            d = 1e-6;
            dmat = @(var) d*eye(numel(var));

            [dx_st,out_st] = obj.get_dx_Vfd(x_st,u_st,varargin{:});
            
            dx = x_st + dmat(x_st);
            du = u_st + dmat(u_st);

            [A(:),C(:)] = tools.arrayfun(@(i) obj.get_dx_Vfd( dx(i),  u_st, Vabs_st, Efd_st), 1:numel(x_st) );
            [B(:),D(:)] = tools.arrayfun(@(i) obj.get_dx_Vfd(  x_st, du(:), Vabs_st, Efd_st), 1:numel(u_st) );

            Bin = cell(1,numel(varargin));
            Din = cell(1,numel(varargin));
            for i = 1:numel(varargin)
                temp = varargin;
                temp{i} = temp{i} + d;
                [Bin{i},Din{i}] = obj.get_dx_u(x_st,u_st,temp{:});
            end

            %[dx/dVabs,dx/dEfd,dx/du_avr]
            A = horzcat(A{:})-dx_st;
            B = [horzcat(Bin{:}),horzcat(B{:})]-dx_st;
            C = horzcat(C{:})-out_st;
            D = [horzcat(Din{:}),horzcat(D{:})]-out_st;
        end

        function sys = get_sys(obj,varargin)

            sys = obj.system_matrix;
            if isempty(sys)
                if numel(varargin)>0
                    obj.set_linear_matrix(varargin{:})
                else
                    error('Linear system not yet calculated.')
                end
            end

            % SSクラスで定義
            sys = ss(sys.A,sys.B,sys.C,sys.D);
            

            uname = [obj.port_in ,obj.naming_port()];
            yname = [obj.port_out];%,obj.naming_state()];
            for i = 1:numel(uname)
                sys.InputGroup.(uname{i}) = i;
            end
            for i = 1:numel(yname)
                sys.OutputGroup.(yname{i}) = i;
            end

        end

    end

    methods(Access=protected)
        
        function out = sat(obj, x, x_min, x_max)%#ok
            out = max(x, x_min);
            out = min(out, x_max);
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
