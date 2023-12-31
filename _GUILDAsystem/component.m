classdef component < base_class.HasStateInput & base_class.HasGridCode & base_class.HasCostFunction 
% 機器を定義するスーパークラス
% GUILDA上に機器モデルを実装するために必要なmethodが定義されている。
% 新しい機器モデルを実装する場合はこのcomponentクラスを継承すること。
    

    
    properties(SetAccess = protected)
        system_matrix
        x_equilibrium
        u_equilibrium
    end

    properties(Dependent)
        V_equilibrium
        I_equilibrium
        omega0
        connected_bus
    end

    properties
        parameter = table();
        get_dx_con_func
    end

    
    properties(Access=protected,Dependent)
        V_st
        I_st
    end
    
    properties
        GraphCoordinate = [];
    end

    
    methods(Abstract)
        set_equilibrium(Veq, Ieq)
        [dx, constraint] = get_dx_constraint(t, x, V, I, u);
    end
    
    
    methods
        
        function setprop(obj,prop,value)
            obj.(prop) = value;
        end

        function set.parameter(obj, value)
            obj.parameter = value;
            obj.recalculate
            obj.editted;
        end

        function b = get.connected_bus(obj)
            b = obj.parents{1};
        end

        function out = get.V_equilibrium(obj)
            out = obj.connected_bus.V_equilibrium;
        end

        function out = get.I_equilibrium(obj)
            out = obj.connected_bus.I_equilibrium;
        end

        function out = get.omega0(obj)
            out = obj.connected_bus.power_network.omega0;
        end

        function out = get.V_st(obj)
            out = [real(obj.V_equilibrium);imag(obj.V_equilibrium)];
        end

        function out = get.I_st(obj)
            out = [real(obj.I_equilibrium);imag(obj.I_equilibrium)];
        end

        function nx = get_nx(obj)
           nx = numel(obj.x_equilibrium); 
        end

        function nu = get_nu(obj)
           nu = numel(obj.u_equilibrium); 
        end

        function [dx, con] = get_dx_constraint_linear(obj, ~, x, V, I, u)
            ss  = obj.system_matrix;
            dx  = ss.A * ( x - obj.x_equilibrium) + ss.B * u + ss.BV * (V - obj.V_st) + ss.BI * ( I - obj.I_st);
            con = ss.C * ( x - obj.x_equilibrium) + ss.D * u + ss.DV * (V - obj.V_st) + ss.DI * ( I - obj.I_st);
        end

        function M = Mass(obj)
            x = obj.x_equilibrium;
            u = obj.u_equilibrium;
            [dx,con] = obj.get_dx_constraint( 0, x, obj.V_st, obj.I_st, u);
            M = blkdiag( eye(numel(dx)), zeros(length(con)) );
        end

        function [A, B, C, D, BV, DV, BI, DI, R, S] = get_linear_matrix(obj,xst,Vst,Ist)

            %%% 引数の補完 %%%
            if nargin < 2 || isempty(xst)
                xst = obj.x_equilibrium;
            end
            if nargin < 3 || isempty(Vst)
                Vst = obj.V_equilibrium;
            end
            if nargin < 4 || isempty(Ist)
                Ist = obj.I_equilibrium;
            end
            
            %%% パラメータの型のチェック %%%
            if numel(xst) ~= obj.get_nx
                error('The size of the specified x_st does not match the state')
            end
            if numel(Vst) == 1
                Vst = tools.complex2vec(Vst);
            elseif numel(Vst) ~= 2 || any(~isreal(Vst))
                error('The type of the specified Vst is incorrect')
            end
            if numel(Ist) == 1
                Ist = tools.complex2vec(Ist);
            elseif numel(Ist) ~= 2 || any(~isreal(Ist))
                error('The type of the specified Ist is incorrect')
            end
            t = 0;
            ust = obj.u_equilibrium;
            
            %%% 時変システムでないかの検査 %%%
            t_dx = @(t) obj.get_dx_constraint(t,1.01*xst,1.01*Vst,1.01*Ist,ust);
            [dx0,con0] = t_dx(0);
            [dx100,con100] = t_dx(100);
            if ~ ( all((dx0-dx100)<1e-4) && all((con0-con100)<1e-4) )
                warning('時変システムであるようです. t=0において近似線形化を実行します.')
            end

                nx = obj.get_nx;
                % xに関しての近似線形モデル
                [A,C]   =  split_out(...
                    tools.linearization(...
                    @(x_) stack_out(@(x_) obj.get_dx_constraint(t, x_, Vst,  Ist,  ust),x_),xst),nx);
                
                % Vに関しての近似線形モデル
                [BV,DV] =  split_out(...
                    tools.linearization(...
                    @(V_) stack_out(@(V_) obj.get_dx_constraint(t, xst, V_,  Ist,  ust),V_),Vst),nx);
            
                % Iに関しての近似線形モデル
                [BI,DI] = split_out(... 
                    tools.linearization(...
                    @(I_) stack_out(@(I_) obj.get_dx_constraint(t, xst,  Vst, I_,  ust),I_),Ist),nx);
                
                % uに関しての近似線形モデル
                [B,D]   =  split_out(...
                    tools.linearization(...
                    @(u_) stack_out(@(u_) obj.get_dx_constraint(t, xst,  Vst,  Ist, u_),u_),ust),nx);
            
                R = zeros(obj.get_nx,0);
                S = zeros(0,obj.get_nx);
        end


        function set_linear_matrix(obj,varargin)
            sys = struct();
            [ sys.A , sys.B , sys.C , sys.D ,... 
              sys.BV, sys.DV, sys.BI, sys.DI,sys.R , sys.S] = obj.get_linear_matrix(varargin{:});
            obj.system_matrix = sys;
        end
        
        function val = usage_function(obj,func)
            x = obj.x_equilibrium;
            V = tools.complex2vec(obj.V_equilibrium);
            I = tools.complex2vec(obj.I_equilibrium);
            u = zeros(obj.get_nu,1);
            try
                val = func(obj,0,x,V,I,u);
            catch
                error(['The function handle seems to be in the wrong format.',newline,...
                       'It must be in the following format',newline,...
                       'func = @(obj,t,x,V,I,u) ~',newline,...
                       '・obj : own class object',newline,...
                       '・t = time(scalar)',newline,...
                       '・x = state vector',newline,...
                       '・V = [real(V);imag(V)]',newline,...
                       '・I = [real(I);imag(I)]',newline,...
                       '・u = input vector',newline])
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

        function recalculate(obj)
            if ~isempty(obj.connected_bus)
                Veq = obj.V_equilibrium;
                Ieq = obj.I_equilibrium;
                if ~isempty(Veq) && ~isempty(Ieq)
                    obj.set_equilibrium();
                end
            end
        end
        
        function check_class(~,c,cname,print_name)
            if iscell(cname)
                check = any( tools.hcellfun(@(n) isa(c,n), cname) );
            else
                check = isa(c,cname);
            end
            if ~check
                if nargin<4
                    if iscell(cname)
                        print_name = ['"',cname{1},'" class'];
                    else
                        print_name = ['"',cname,'" class'];
                    end
                end
                error(['It is not ',print_name,'.'])
            end
        end

    end
end



function out = stack_out(func,x)
    [dx,con] = func(x);
    out = [dx;-con];
end

function [dx,con] = split_out(matrix,nx)
    dx  = matrix(1:nx,:);
    con = matrix(nx+1:end,:);
end

