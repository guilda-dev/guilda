classdef component < handle & base_class.HasStateInput & base_class.HasGridCode & base_class.HasCostFunction 
% 機器を定義するスーパークラス
% GUILDA上に機器モデルを実装するために必要なmethodが定義されている。
% 新しい機器モデルを実装する場合はこのcomponentクラスを継承すること。
    
    properties
        omega0 = 2*pi*60;
    end
    
    properties(Dependent)
        connected_bus
    end

    properties(SetAccess = protected)
        x_equilibrium
        u_equilibrium
    end

    properties(Dependent)
        V_equilibrium
        I_equilibrium
    end

    properties(SetAccess = protected)
        system_matrix    
    end

    properties
        parameter = array2table(zeros(1,0))
        get_dx_con_func
    end

    properties
        InputType = 'Add';
    end

    properties(SetAccess = protected)
        u_func = @(obj,u) obj.u_equilibrium + u;
    end
    
    properties(Access=protected,Dependent)
        V_st
        I_st
    end
    
    properties(Dependent)
        GraphCoordinate
    end
    
    methods(Abstract)
        [dx, constraint] = get_dx_constraint(t, x, V, I, u);
        [x_st,u_st] = get_equilibrium(V,I);
    end
    
    
    methods
        function obj = component()
            b = bus.dammy();
            b.set_component(obj)
        end
    
        %% Set method 
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            function set.parameter(obj, value)
                obj.parameter = value;
                obj.editted("Parameter");
            end

        %% Get method
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            function b = get.connected_bus(obj)
                b = obj.parents{1};
            end
    
            function out = get.V_equilibrium(obj)
                out = obj.connected_bus.V_equilibrium;
            end
    
            function out = get.I_equilibrium(obj)
                out = obj.connected_bus.I_equilibrium;
            end
    
            function out = get.V_st(obj)
                out = [real(obj.V_equilibrium);imag(obj.V_equilibrium)];
            end
    
            function out = get.I_st(obj)
                out = [real(obj.I_equilibrium);imag(obj.I_equilibrium)];
            end

            function out = get.GraphCoordinate(obj)
                out = obj.connected_bus.GraphCoordinate;
            end

        %% method for get number of state/input
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            function nx = get_nx(obj)
               nx = numel(obj.x_equilibrium); 
            end
    
            function nu = get_nu(obj)
               nu = numel(obj.u_equilibrium); 
            end


        %% method for calculate linear system
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            % 近似線形化した際のシステム行列を計算
            [A, B, C, D, BV, DV, BI, DI, R, S] = get_linear_matrix(obj,Vst,Ist,xst,ust);

            % 上のget_linear_matrixで得た行列をobj.system_matrixに格納する
            function set_linear_matrix(obj,varargin)
                sys = struct();
                [ sys.A , sys.B , sys.C , sys.D ,... 
                  sys.BV, sys.DV, sys.BI, sys.DI,sys.R , sys.S] = obj.get_linear_matrix(varargin{:});
                obj.system_matrix = sys;
            end

            % 上でobj.system_matrixに格納されたシステム行列から近似線形化システムとしての入出力を担当する
            function [dx, con] = get_dx_constraint_linear(obj, ~, x, V, I, u)
                ss  = obj.system_matrix;
                dx  = ss.A * ( x - obj.x_equilibrium) + ss.B * u + ss.BV * (V - obj.V_st) + ss.BI * ( I - obj.I_st);
                con = ss.C * ( x - obj.x_equilibrium) + ss.D * u + ss.DV * (V - obj.V_st) + ss.DI * ( I - obj.I_st);
            end
    

        %% 入力形式の指定を行うメソッド
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            function set.InputType(obj,val)
                if nargin<2
                    disp_msg = ['1. Rate: input = u_equilibrium + u \n',...
                                '2. Add : input = u_equilibrium * (1+u) \n',...
                                '3.Value: input = u \n'];
                    input_msg = 'input 1 or 2 or 3';
                    candidate = {'rate','Rate','1','add','Add','2','value','Value',3};
                    val = tools.input(disp_msg,input_msg,'str',candidate);
                end
                switch val
                    case {'rate' ,'Rate' ,1}
                        obj.InputType = 'Rate';
                    case {'add'  ,'Add'  ,2}
                        obj.InputType = 'Add';
                    case {'value','Value',3}
                        obj.InputType = 'Value';
                    otherwise
                        error('InputType must be "add","rate","value".')
                end
                obj.editted("Input Type")
                try
                    linear = obj.connected_bus.power_network.linear;%#ok
                catch
                    linear = false;
                end
                obj.set_function(linear);
            end
    
            function set_function(obj,linear)
                if linear
                    obj.get_dx_con_func = @obj.get_dx_constraint_linear;
                    obj.u_func          = @(obj,u) u;
                else  
                    obj.get_dx_con_func = @obj.get_dx_constraint;
                    switch obj.InputType
                        case 'Rate'
                            obj.u_func = @(obj,u) diag(obj.u_equilibrium) * (1+u);
                        case 'Add'
                            obj.u_func = @(obj,u) obj.u_equilibrium + u;
                        case 'Value'
                            obj.u_func = @(obj,u) u;
                    end
                end
            end
    
    
        %% 平衡点を計算
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            function [x_st,u_st] = set_equilibrium(obj,V,I)
                if nargin<2
                    V = obj.V_equilibrium;
                    I = obj.I_equilibrium;
                end
                [x_st, u_st] = obj.get_equilibrium(V,I);
                if numel(x_st)==0
                    x_st = zeros(0,1);
                end
                if numel(u_st)==0
                    u_st = zeros(0,1);
                end
                obj.x_equilibrium = x_st;
                obj.u_equilibrium = u_st;
                obj.set_linear_matrix();
            end


            function M = Mass(obj)
                [dx,con] = obj.check_dx_constraint;
                M = blkdiag( eye(numel(dx)), zeros(length(con)) );
            end
    
    
        %% チェック用のメソッド
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            [dx, con] = check_dx_constraint(obj)
            val = check_CostFunction(obj,func);
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




