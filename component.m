classdef component < handle
% 機器を定義するスーパークラス
% GUILDA上に機器モデルを実装するために必要なmethodが定義されている。
% 新しい機器モデルを実装する場合はこのcomponentクラスを継承すること。
    
    properties
        get_dx_con_func
    end
    
    properties(Abstract, SetAccess = private)
        x_equilibrium
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

        function get_dx_constraint_linear(obj,varargin)
            disp_message("get_dx_constraint_linear")
        end

        function [A, B, C, D, BV, DV, BI, DI, R, S] = get_linear_matrix(obj, varargin)
            disp_message("get_dx_constraint_linear")
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


