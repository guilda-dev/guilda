classdef component < handle
% 機器を定義するスーパークラス
% GUILDA上に機器モデルを実装するために必要なmethodが定義されている。
% 新しい機器モデルを実装する場合はこのcomponentクラスを継承すること。
    
    properties
        get_dx_con_func
    end
    
    properties(SetAccess = protected)
        x_equilibrium
        V_equilibrium
        I_equilibrium
    end
    
    methods(Abstract)
        set_equilibrium(Veq, Ieq)
        nu = get_nu(varargin)
        [dx, constraint] = get_dx_constraint(t, x, V, I, u);
    end
    
    methods
        function nx = get_nx(obj)
           nx = numel(obj.x_equilibrium); 
        end

%         function get_dx_constraint_linear(obj,varargin)
%             disp_message("get_dx_constraint_linear")
%         end

        function [dx, con] = get_dx_constraint_linear(obj, ~, x, V, I, u)
            [A, B, C, D, BV, DV, BI, DI, ~, ~] = get_linear_matrix(obj);
            dx = A*(x-obj.x_st) + B*u + BV*(V-obj.V_st) + BI*(I-obj.I_st);
            con = C*(x-obj.x_st) + D*u + DV*(V-obj.V_st) + DI*(I-obj.I_st);
        end

%         function [A, B, C, D, BV, DV, BI, DI, R, S] = get_linear_matrix(obj, varargin)
%             disp_message("get_dx_constraint_linear")
%         end
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
            ust = zeros(obj.get_nu,1);
        
            t_dx = @(t) obj.get_dx_constraint( t, xst+0.1*ones(size(xst)), Vst+0.1*ones(size(Vst)),  Ist+0.1*ones(size(Ist)),  ust+0.1*ones(size(ust)) ) ;
            [dx0,con0] = t_dx(0);
            [dx10,con10] = t_dx(10);
            if all((dx0-dx10)<1e-4) && all((con0-con10)<1e-4)
                nx = obj.get_nx;
            
                % xに関しての近似線形モデル
                [A,C]   =  split_out(...
                    work.nishino.developping.tools.linearlization(...
                    @(x_) stack_out(@(x_) obj.get_dx_constraint(t, x_, Vst,  Ist,  ust),x_),xst),nx);
                
                % Vに関しての近似線形モデル
                [BV,DV] =  split_out(...
                    work.nishino.developping.tools.linearlization(...
                    @(V_) stack_out(@(V_) obj.get_dx_constraint(t, xst, V_,  Ist,  ust),V_),Vst),nx);
            
                % Iに関しての近似線形モデル
                [BI,DI] = split_out(... 
                    work.nishino.developping.tools.linearlization(...
                    @(I_) stack_out(@(I_) obj.get_dx_constraint(t, xst,  Vst, I_,  ust),I_),Ist),nx);
                
                % uに関しての近似線形モデル
                [B,D]   =  split_out(...
                    work.nishino.developping.tools.linearlization(...
                    @(u_) stack_out(@(u_) obj.get_dx_constraint(t, xst,  Vst,  Ist, u_),u_),ust),nx);
            
                R = zeros(obj.get_nx,0);
                S = zeros(0,obj.get_nx);
        
            else
                error('時変システムであるため数値的な近似線形化を行えませんでした．')
            end
        end

        function disp_messsage(function_name)
            error("Linear analysis cannot be performed. \n"...
                 +"Please implement function '"+function_name+"' in class '"+class(obj)+"'.",[])
        end

        function x_name = get_state_name(obj)
            nx = obj.get_nx;
            try x_name=obj.get_x_name;
            catch; x_name={};
            end
            
            if numel(x_name)>nx
                x_name(nx+1:end) = [];
                warning('the number of variable names exceeds the number of state variables')
                fprintf('state : '); disp(x_name)
            elseif numel(x_name)<nx
                for i = numel(x_name)+1:nx
                    x_name{i} = ['state',num2str(i)];
                end
            end
        end

        function u_name = get_port_name(obj)
            nu = obj.get_nu;
            try u_name=obj.get_u_name;
            catch; u_name={};
            end
            
            if numel(u_name)>nu
                u_name(nu+1:end) = [];
                warning('the number of variable names exceeds the number of state variables')
                fprintf('input port : '); disp(u_name)
            elseif numel(u_name)<nu
                for i = numel(u_name)+1:nu
                    u_name{i} = ['u',num2str(i),''];
                end
            end
        end
    end
end


