classdef component < base_class.HasStateInput & base_class.HasGridCode & base_class.HasCostFunction 
% 機器を定義するスーパークラス
% GUILDA上に機器モデルを実装するために必要なmethodが定義されている。
% 新しい機器モデルを実装する場合はこのcomponentクラスを継承すること。
    

    properties(Dependent)
        index
        omega0
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
        parameter = table();
        get_dx_con_func
    end

    properties(SetAccess = protected)
        InputType = 'Add';
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
    end
    
    
    methods
    
        %% Set method 
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            function set.parameter(obj, value)
                obj.parameter = value;
                if ~isempty(obj.connected_bus)  %#ok
                    Veq = obj.V_equilibrium;    %#ok
                    Ieq = obj.I_equilibrium;    %#ok
                    if ~isempty(Veq) && ~isempty(Ieq)
                        obj.set_equilibrium();
                    end
                end
            end

        %% Get method
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            function i = get.index(obj)
                i = obj.parents{1}.index;
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
            function [dx, con] = get_dx_constraint_linear(obj, ~, x, V, I, u)
                ss  = obj.system_matrix;
                dx  = ss.A * ( x - obj.x_equilibrium) + ss.B * u + ss.BV * (V - obj.V_st) + ss.BI * ( I - obj.I_st);
                con = ss.C * ( x - obj.x_equilibrium) + ss.D * u + ss.DV * (V - obj.V_st) + ss.DI * ( I - obj.I_st);
            end
    
            function [A, B, C, D, BV, DV, BI, DI, R, S] = get_linear_matrix(obj,Vst,Ist,xst,ust)
        
                    %%% 引数の補完 %%%
                    if nargin < 3
                        % use properties
                        Vst = obj.V_st;
                        Ist = obj.I_st;
                        xst = obj.x_equilibrium;
                        ust = obj.u_equilibrium;
                    else
                        % check form of Vst and Ist
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

                        if nargin<5
                            % calculate xst/ust from Vst/Ist
                            [xst,ust] = obj.set_equilibrium(Vst,Ist);
                        else
                            % check form of xst/ust
                            if numel(xst) ~= obj.get_nx
                                error('The size of the specified x_st does not match the state')
                            end
                            if numel(ust) ~= obj.get_nu
                                error('The size of the specified u_st does not match the state')
                            end
                        end
                    end
                    
                    %%% 時変システムでないかの検査 %%%
                    t_dx = @(t) obj.get_dx_constraint(t,1.01*xst,1.01*Vst,1.01*Ist,ust);
                    [dx0,con0] = t_dx(0);
                    [dx100,con100] = t_dx(100);
                    if ~ ( all((dx0-dx100)<1e-4) && all((con0-con100)<1e-4) )
                        warning('時変システムであるようです. t=0において近似線形化を実行します.')
                    end
                        
                    M = diag(obj.Mass);

                    % xに関しての近似線形モデル
                    [A,C]   =  split_out(...
                        tools.linearization(...
                        @(x_) stack_out(@(x_) obj.get_dx_constraint(0, x_, Vst,  Ist,  ust),x_),xst),M);
                    
                    % Vに関しての近似線形モデル
                    [BV,DV] =  split_out(...
                        tools.linearization(...
                        @(V_) stack_out(@(V_) obj.get_dx_constraint(0, xst, V_,  Ist,  ust),V_),Vst),M);
                
                    % Iに関しての近似線形モデル
                    [BI,DI] = split_out(... 
                        tools.linearization(...
                        @(I_) stack_out(@(I_) obj.get_dx_constraint(0, xst,  Vst, I_,  ust),I_),Ist),M);
                    
                    % uに関しての近似線形モデル
                    [B,D]   =  split_out(...
                        tools.linearization(...
                        @(u_) stack_out(@(u_) obj.get_dx_constraint(0, xst,  Vst,  Ist, u_),u_),ust),M);
                
                    R = zeros(obj.get_nx,0);
                    S = zeros(0,obj.get_nx);

                        function out = stack_out(func,x)
                            [dx,con] = func(x);
                            out = [dx;-con];
                        end
                        
                        function [dx,con] = split_out(matrix,M)
                            x = M~=0;
                            dx  = diag(1./M(x)) * matrix(x,:);
                            con = matrix(~x,:);
                        end
                end
        


        %% 入力形式の指定を行うメソッド
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            function set_InputType(obj,val)
                if nargin<2
                    disp_msg = ['1. Rate: input = u_equilibrium + u \n',...
                                '2. Add : input = u_equilibrium * (1+u) \n',...
                                '3.Value: input = u \n'];
                    input_msg = 'input 1 or 2 or 3';
                    candidate = {'rate','Rate','1','add','Add','2','value','Value',3};
                    val = tools.input(disp_msg,input_msg,'str',candidate);
                end
                switch val
                    case {'rate' ,'Rate', 1}
                        obj.InputType = 'Rate';
                    case {'add','Add',2}
                        obj.InputType = 'Add';
                    case {'value','Value',3}
                        obj.InputType = 'Value';
                    otherwise
                        error('porttype must be "add","rate","value".')
                end
                try
                    linear = obj.connected_bus.power_network.linear;
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
                % [x_st, u_st] = obj.get_equilibrium(V,I,'init');
                if numel(x_st)==0
                    x_st = zeros(0,1);
                end
                if numel(u_st)==0
                    u_st = zeros(0,1);
                end
                obj.x_equilibrium = x_st;
                obj.u_equilibrium = u_st;
                obj.set_linear_matrix(x_st);
            end
    
            function set_linear_matrix(obj,varargin)
                sys = struct();
                [ sys.A , sys.B , sys.C , sys.D ,... 
                  sys.BV, sys.DV, sys.BI, sys.DI,sys.R , sys.S] = obj.get_linear_matrix(varargin{:});
                obj.system_matrix = sys;
            end


            function M = Mass(obj)
                [dx,con] = obj.check_dx_constraint;
                M = blkdiag( eye(numel(dx)), zeros(length(con)) );
            end
    
    
        %% get_dx_uの関数の型をチェック
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            function [dx, con] = check_dx_constraint(obj)
                x = obj.x_equilibrium;
                u = obj.u_equilibrium;
                [dx,con] = obj.get_dx_constraint( 0, x, obj.V_st, obj.I_st, u);
            end
    
            function val = usage_function(obj,func)
                x = obj.x_equilibrium;
                u = obj.u_equilibrium;
                V = obj.V_st;
                I = obj.I_st;
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
    end
end




